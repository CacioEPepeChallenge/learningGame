//
//  DevStart.swift
//  learning_game
//
//  Developer shortcut: start the game at a touchpoint instead of from the
//  beginning (name entry → intro → TP1). The room is set up as if the earlier
//  touchpoints were already solved, so you walk to the object with the joystick
//  and play from there.
//
//  Two ways to use it (Debug builds only — Release always starts normally):
//
//   1. Edit `startAt` below (e.g. 4) and press ⌘R. Set it back to nil before
//      committing.
//   2. Or leave this file alone and add a launch argument instead:
//      Product ▸ Scheme ▸ Edit Scheme… ▸ Run ▸ Arguments ▸
//      "Arguments Passed On Launch" ▸ +  `-StartAtTouchpoint 4`
//      (tick/untick the checkbox to switch it on and off).
//
//   4 = Leo's PC (loops)       → MC by the bookshelf, PC glowing
//   5 = The painting (functions) → MC by the desk, painting glowing
//   (2 and 3 work too.)
//

import Foundation

enum DevStart {
    /// Set to 4 or 5 to start there. nil = the normal game.
    static let startAt: Int? = nil

    /// The touchpoint to start at, or nil for the normal game.
    static var touchpoint: Int? {
        #if DEBUG
        let fromLaunchArgument = UserDefaults.standard.integer(forKey: "StartAtTouchpoint")
        if (2...5).contains(fromLaunchArgument) { return fromLaunchArgument }
        if let startAt, (2...5).contains(startAt) { return startAt }
        #endif
        return nil
    }
}
