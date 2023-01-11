//
//  CanvasDelegates.swift
//  tasotirin_FinalProject_Pixels
//
//  Created by Tavis Sotirin on 3/14/21.
//

import UIKit

enum touchType: String {
    case began = "Begin"
    case moved = "Move"
    case end = "End"
    case cancel = "Cancel"
}

// Delegates for layer, file, export, and overview objects. Used for live update/communication between canvas and seperate displays

protocol PreviewDelegate {
    func SetCanvasPreview(_ preview: UIImage?, _ isHidden: Bool)
}

protocol OverviewDelegate: PreviewDelegate {
    func SetCanvasOverviewBox(_ box: CGRect, _ view: UIView)
}

protocol LayerDelegate {
    func setActiveLayer(layerIndex: Int)
}
