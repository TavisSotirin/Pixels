//
//  BorderDraw.swift
//  tasotirin_FinalProject_Pixels
//
//  Created by Tavis Sotirin on 2/24/21.
//

import UIKit

// Background view to create outside bounds borders on objects within another view - needs to be at bottom of view heirarchy
class BorderDraw: UIView {
    var borders: [(CGRect,CGColor)] = []
    var borderSize = CGFloat(10)
    
    func setup() {
        self.backgroundColor = .clear
    }
    
    required init(borderSize: CGFloat, frame: CGRect) {
        super.init(frame: frame)
        self.borderSize = borderSize
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        for (rect,color) in borders {
            context.setLineWidth(borderSize)
            context.setStrokeColor(color)
            context.stroke(rect)
        }
    }
    
    // Add rect to border list with borderSize offsets
    func addBorder(_ rect: CGRect, _ color: UIColor) {
        let extent = rect.width + borderSize
        let newBorder = CGRect(x: rect.minX - borderSize / 2, y: rect.minY - borderSize / 2, width: extent, height: extent)
        borders.append((newBorder, color.cgColor))
        setNeedsDisplay()
    }
}
