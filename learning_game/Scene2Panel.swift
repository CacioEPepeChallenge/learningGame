//
//  Scene2Panel.swift
//  learning_game
//
//  Checkpoint 2: The Flickering Lamp — wire each lamp part with the right type fuse.
//  Assets: lamp_on, lamp_dim, lamp_off, part_meter, part_switch_on, part_switch_off,
//          part_dimmer, part_tag, socket_empty, fuse, spark
//

import SwiftUI

// MARK: - Model

enum SwiftType: String, CaseIterable, Identifiable {
    case int = "Int", string = "String", bool = "Bool", double = "Double"
    var id: String { rawValue }
}

enum LampPart: CaseIterable, Identifiable {
    case meter, switchPlate, dimmer, tag
    var id: Self { self }

    var needs: SwiftType {
        switch self {
        case .meter: .int
        case .switchPlate: .bool
        case .dimmer: .double
        case .tag: .string
        }
    }

    var variable: String {
        switch self {
        case .meter: "watts"
        case .switchPlate: "isOn"
        case .dimmer: "brightness"
        case .tag: "label"
        }
    }
}

enum LampState: Hashable {
    case on, dim, off, flicker
}

// MARK: - Panel

struct Scene2Panel: View {
    let onClose: () -> Void
    let onComplete: () -> Void

    @State private var wired: [LampPart: SwiftType] = [:]
    @State private var lastWired: LampPart?
    @State private var socketFrames: [LampPart: CGRect] = [:]

    @State private var dragging: SwiftType?
    @State private var dragOffset: CGSize = .zero
    @State private var selected: SwiftType?          // tap-to-place alternative to dragging
    @State private var chipShake: [SwiftType: CGFloat] = [:]
    @State private var sparkingPart: LampPart?

    @State private var switchOn = true
    @State private var brightness = 0.75

    @State private var rightTrigger = 0
    @State private var wrongTrigger = 0

    private var allWired: Bool { wired.count == LampPart.allCases.count }

    private var lampState: LampState {
        guard allWired else { return .flicker }
        if !switchOn { return .off }
        return brightness < 0.5 ? .dim : .on
    }

    /// The panel is laid out at a fixed design size, then scaled to fit the screen,
    /// so nothing can overflow. Landscape gets its own wide layout.
    private static let portraitSize = CGSize(width: 360, height: 600)
    private static let landscapeSize = CGSize(width: 780, height: 360)

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            let design = isLandscape ? Self.landscapeSize : Self.portraitSize
            let scale = min(geo.size.width * 0.96 / design.width,
                            geo.size.height * 0.96 / design.height,
                            1.6)

            ZStack {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {}

                panel(isLandscape: isLandscape)
                    .frame(width: design.width, height: design.height)
                    .scaleEffect(scale)
                    .frame(width: design.width * scale, height: design.height * scale)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .sensoryFeedback(.success, trigger: rightTrigger)
        .sensoryFeedback(.error, trigger: wrongTrigger)
        .overlay(alignment: .topTrailing) {
            DebugAutocompleteButton(action: onComplete)
        }
    }

    @ViewBuilder
    private func panel(isLandscape: Bool) -> some View {
        Group {
            if isLandscape {
                // Lamp on the left, puzzle on the right
                HStack(spacing: 14) {
                    lamp
                        .frame(width: 190)
                        .frame(maxHeight: .infinity)
                    controls
                }
            } else {
                VStack(spacing: 10) {
                    lamp
                        .frame(maxWidth: .infinity)
                        .frame(height: 130)
                    controls
                }
            }
        }
        .coordinateSpace(.named("board"))
        .padding(14)
        .padding(.top, 24)   // room for the close button
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(white: 0.08))
        .overlay(Rectangle().stroke(.white, lineWidth: 3))
        .overlay(alignment: .topTrailing) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(6)
                    .background(.white)
            }
            .padding(8)
        }
    }

    private var lamp: some View {
        LampView(state: lampState, steadiness: 4 + wired.count)
            .padding(10)
            .background(Color(white: 0.18))
    }

    private var controls: some View {
        VStack(spacing: 10) {
            Text(allWired ? "It works! Try the switch and the dimmer."
                          : "Plug the right fuse into each part.")
                .font(.system(size: 15, design: .monospaced))
                .foregroundStyle(allWired ? .green : .white)
                .frame(maxWidth: .infinity, alignment: .leading)

            // All four parts on one line
            HStack(alignment: .top, spacing: 8) {
                ForEach(LampPart.allCases) { part in
                    partCell(part)
                }
            }

            codeLine

            chipTray

            Spacer(minLength: 0)

            HStack {
                Spacer()
                Button("Done ▶", action: onComplete)
                    .font(.system(size: 17, weight: .semibold, design: .monospaced))
                    .foregroundStyle(allWired ? .black : .gray)
                    .padding(.horizontal, 22).padding(.vertical, 10)
                    .background(allWired ? Color.yellow : Color(white: 0.2))
                    .overlay(Rectangle().stroke(allWired ? .clear : .gray, lineWidth: 1))
                    .disabled(!allWired)
            }
        }
    }

    // MARK: Parts

    private func partCell(_ part: LampPart) -> some View {
        VStack(spacing: 4) {
            partImage(part)
                .frame(width: 52, height: 52)
                .contentShape(Rectangle())
                .onTapGesture { interact(with: part) }

            Text(literal(for: part))
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(.yellow)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            socket(part)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func partImage(_ part: LampPart) -> some View {
        switch part {
        case .meter:
            pixel("part_meter")
        case .switchPlate:
            pixel(switchOn ? "part_switch_on" : "part_switch_off")
        case .dimmer:
            pixel("part_dimmer")
                .rotationEffect(.degrees(-135 + 270 * brightness))
                .animation(.spring(duration: 0.3), value: brightness)
        case .tag:
            pixel("part_tag")
        }
    }

    private func socket(_ part: LampPart) -> some View {
        ZStack {
            if let type = wired[part] {
                fuseView(type)
                    .transition(.scale(scale: 1.3).combined(with: .opacity))
            } else {
                pixel("socket_empty")
            }
            if sparkingPart == part {
                pixel("spark")
                    .frame(width: 56, height: 56)
                    .transition(.opacity)
            }
        }
        .frame(width: 72, height: 36)
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named("board")) } action: {
            socketFrames[part] = $0
        }
        .onTapGesture {
            if let selected { tryPlace(selected, in: part) }
        }
    }

    private func literal(for part: LampPart) -> String {
        switch part {
        case .meter: "400"
        case .switchPlate: switchOn ? "true" : "false"
        case .dimmer: String(brightness)
        case .tag: "\"Leo's lamp\""
        }
    }

    /// Switch and dimmer can always be played with. They only change the lamp once it's wired.
    private func interact(with part: LampPart) {
        switch part {
        case .switchPlate:
            switchOn.toggle()
        case .dimmer:
            let steps = [0.25, 0.5, 0.75, 1.0]
            let i = steps.firstIndex(of: brightness) ?? 0
            brightness = steps[(i + 1) % steps.count]
        default:
            break
        }
    }

    // MARK: Code line

    private var codeLine: some View {
        Group {
            if let part = lastWired, let type = wired[part] {
                Text("\(Text("var \(part.variable): "))\(Text(type.rawValue).foregroundStyle(.green).bold())\(Text(" = \(literal(for: part))"))")
            } else {
                Text("// wire a part to see its code").foregroundStyle(.gray)
            }
        }
        .font(.system(size: 15, design: .monospaced))
        .foregroundStyle(.white)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(white: 0.15))
        .overlay(Rectangle().stroke(Color(white: 0.35), lineWidth: 1))
    }

    // MARK: Fuse chips

    private var chipTray: some View {
        HStack(spacing: 8) {
            ForEach(SwiftType.allCases) { type in
                let used = wired.values.contains(type)
                fuseView(type)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .overlay(Rectangle().stroke(selected == type ? Color.yellow : .clear, lineWidth: 2))
                    .scaleEffect(dragging == type ? 1.15 : 1)
                    .offset(dragging == type ? dragOffset : .zero)
                    .modifier(Shake(animatableData: chipShake[type, default: 0]))
                    .zIndex(dragging == type ? 1 : 0)
                    .opacity(used ? 0 : 1)
                    .allowsHitTesting(!used)
                    .onTapGesture {
                        selected = (selected == type) ? nil : type
                    }
                    .gesture(
                        DragGesture(coordinateSpace: .named("board"))
                            .onChanged { value in
                                dragging = type
                                selected = nil
                                dragOffset = value.translation
                            }
                            .onEnded { value in
                                if let part = socketFrames.first(where: {
                                    $0.value.insetBy(dx: -12, dy: -12).contains(value.location)
                                })?.key {
                                    tryPlace(type, in: part)
                                }
                                withAnimation(.spring(duration: 0.3)) {
                                    dragging = nil
                                    dragOffset = .zero
                                }
                            }
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .zIndex(1)
    }

    private func fuseView(_ type: SwiftType) -> some View {
        ZStack {
            pixel("fuse")
            Text(type.rawValue)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(.black)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 10)
        }
    }

    // MARK: Actions

    private func tryPlace(_ type: SwiftType, in part: LampPart) {
        selected = nil
        guard wired[part] == nil else { return }

        if part.needs == type {
            withAnimation(.spring(duration: 0.35)) {
                wired[part] = type
                lastWired = part
            }
            rightTrigger += 1
        } else {
            wrongTrigger += 1
            withAnimation(.linear(duration: 0.4)) { chipShake[type, default: 0] += 1 }
            withAnimation(.easeOut(duration: 0.1)) { sparkingPart = part }
            Task {
                try? await Task.sleep(for: .milliseconds(450))
                withAnimation(.easeIn(duration: 0.2)) {
                    if sparkingPart == part { sparkingPart = nil }
                }
            }
        }
    }

    private func pixel(_ name: String) -> some View {
        Image(name)
            .resizable()
            .interpolation(.none)
            .scaledToFit()
    }
}

// MARK: - Lamp

struct LampView: View {
    let state: LampState
    /// Out of 10: how often the flickering lamp shows "on". Higher = steadier.
    var steadiness: Int = 6
    @State private var frame = "lamp_on"

    private struct FlickerKey: Hashable {
        let state: LampState
        let steadiness: Int
    }

    var body: some View {
        Image(state == .flicker ? frame : Self.image(for: state))
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .task(id: FlickerKey(state: state, steadiness: steadiness)) { await run() }
    }

    private static func image(for state: LampState) -> String {
        switch state {
        case .on, .flicker: "lamp_on"
        case .dim: "lamp_dim"
        case .off: "lamp_off"
        }
    }

    private func run() async {
        guard state == .flicker else { return }
        while !Task.isCancelled {
            frame = Int.random(in: 0..<10) < steadiness ? "lamp_on"
                  : Bool.random() ? "lamp_dim" : "lamp_off"
            try? await Task.sleep(for: .milliseconds(Int.random(in: 50...350)))
        }
    }
}

// MARK: - Shake

struct Shake: GeometryEffect {
    var amount: CGFloat = 8
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(
            translationX: amount * sin(animatableData * .pi * 4), y: 0))
    }
}


// MARK: - Previews

//#Preview(){
//    Scene3Panel()
//}

#Preview("Lamp puzzle") {
    ZStack {
        Color.green.ignoresSafeArea()
        Scene2Panel(onClose: {}, onComplete: {})
    }
}

#Preview("Lamp puzzle – iPhone SE size") {
    ZStack {
        Color.green.ignoresSafeArea()
        Scene2Panel(onClose: {}, onComplete: {})
    }
    .frame(width: 375, height: 667)
}
