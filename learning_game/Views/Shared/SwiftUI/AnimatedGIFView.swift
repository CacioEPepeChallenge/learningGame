//
//  AnimatedGIFView.swift
//  learning_game
//
//  Plays an animated GIF from the app bundle, frame by frame, with
//  nearest-neighbour scaling so pixel art stays crisp.
//

import SwiftUI
import UIKit
import ImageIO

/// Loads loose (non-asset-catalog) images that are copied into the bundle,
/// e.g. the files in the synced `references` folder.
enum BundleImage {
    static func url(_ name: String, ext: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: ext)
            ?? Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "references")
    }
}

struct AnimatedGIFView: View {
    let name: String
    /// When false, plays once and holds the final frame.
    var loops = true

    @State private var frames: [CGImage] = []
    @State private var delays: [Double] = []
    @State private var index = 0

    var body: some View {
        Group {
            if frames.indices.contains(index) {
                Image(decorative: frames[index], scale: 1)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
            } else {
                Color.clear
            }
        }
        .task(id: name) { await play() }
    }

    private func play() async {
        guard let url = BundleImage.url(name, ext: "gif"),
              let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return }

        let count = CGImageSourceGetCount(source)
        var loaded: [CGImage] = []
        var times: [Double] = []
        for i in 0..<count {
            guard let image = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
            loaded.append(image)
            let props = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [CFString: Any]
            let gif = props?[kCGImagePropertyGIFDictionary] as? [CFString: Any]
            let delay = (gif?[kCGImagePropertyGIFUnclampedDelayTime] as? Double)
                ?? (gif?[kCGImagePropertyGIFDelayTime] as? Double)
                ?? 0.1
            times.append(max(delay, 0.02))
        }
        frames = loaded
        delays = times
        index = 0
        guard loaded.count > 1 else { return }

        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(delays[index]))
            if Task.isCancelled { return }
            if index + 1 < frames.count {
                index += 1
            } else if loops {
                index = 0
            } else {
                return
            }
        }
    }
}

#Preview {
    AnimatedGIFView(name: "painting_safe")
        .frame(width: 160, height: 240)
        .background(.black)
}
