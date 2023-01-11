//
//  CanvasOverview.swift
//  tasotirin_FinalProject_Pixels
//
//  Created by Tavis Sotirin on 3/8/21.
//

import UIKit

// Singleton subclass of CanvasPreview specifically for the overview object
class CanvasOverview: CanvasPreview, OverviewDelegate {
    var boundingBox: CGRect?
    
    override func setup() {
        super.setup()
        isUserInteractionEnabled = true
    }

    // Set tracking box
    func SetCanvasOverviewBox(_ box: CGRect, _ view: UIView) {
        let overviewBounds = box.width * bounds.width
        boundingBox = CGRect(x: box.minX * bounds.width, y: box.minY * bounds.width, width: overviewBounds, height: overviewBounds)
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {return}
        
        // Draw canvas to screen
        drawPreview(to: context)
        
        // Draw bounding box to show current view bounds
        if let box = boundingBox {
            context.setAlpha(1)
            UIColor.red.setStroke()
            context.setLineWidth(2)
            context.stroke(box)
        }
    }
}
