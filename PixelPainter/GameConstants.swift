//
//  GameConstants.swift
//  PixelPainter
//
//  Created by Philip Lee on 10/31/24.
//

import Foundation
import UIKit

enum GameConstants {
    enum PowerUp {
        static let maxShufflePieces = 3
    }
    enum PowerUpTimers {
        static let timeStopCooldown = 5.0
        static let flashCooldown = 5.0
    }
    enum GeneralGamePlay {
        static let timeWarningThreshold = 3.0
        static let hintWaitTime = 3.0
        static let idleHintWaitTime = 3.5
        static let wrongPlacementBufferTime = 0.5
    }

    enum DeviceSizes {
        static let SE_HEIGHT: CGFloat = 667

        static var isIPad: Bool {
            return UIDevice.current.userInterfaceIdiom == .pad
        }
    }

}
