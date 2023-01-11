//
//  CanvasPreview.swift
//  tasotirin_FinalProject_Pixels
//
//  Created by Tavis Sotirin on 2/28/21.
//

import UIKit

// Enhanced UIView with connection to canvas through delegate protocol. Used for live updating seperate layer views
class CanvasPreview: UIView, PreviewDelegate {
    var preview: UIImage?
    var delegate: LayerDelegate?
    var layerIndex: Int = -1
    var bSetTransform = true
    var bHidden = false
    
    func setup() {
        // Enable user touch
        isUserInteractionEnabled = true
        
        // No background color
        self.backgroundColor = .clear
        
        if bSetTransform {
            // Set layer transform to be vertically flipped to match how images are drawn
            let trans = layer.affineTransform().scaledBy(x: 1, y: -1)
            layer.setAffineTransform(trans)
            bSetTransform = false
        }
    }
    
    // Display passed image on this view
    func SetCanvasPreview(_ preview: UIImage?, _ isHidden: Bool) {
        self.bHidden = isHidden
        self.preview = preview
        setNeedsDisplay()
    }
    
    // Draw passed image on view
    func drawPreview(to: CGContext) {
        if let preview = preview?.cgImage {
            to.setAlpha(bHidden ? 0.1 : 0.9)
            to.draw(preview, in: bounds)
        }
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {return}
        drawPreview(to: context)
    }
    
    // Touch start
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouch(.began,touches)
        //print(bounds)
    }
    
    // Touch dragged
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouch(.moved,touches)
    }
    
    // Natural touch end
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouch(.end,touches)
    }
    
    // Touch interrupted by something (e.g. home button pressed)
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouch(.cancel,touches)
    }

    // One layer touch, update currently active layer
    func handleTouch(_ type: touchType, _ touches: Set<UITouch>) {
        if type == .end, layerIndex > -1 {
            delegate?.setActiveLayer(layerIndex: layerIndex)
        }
    }
}
