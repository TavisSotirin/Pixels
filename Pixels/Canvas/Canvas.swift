//
//  PixelCanvas.swift
//  tasotirin_FinalProject_Pixels
//
//  Created by Tavis Sotirin on 2/24/21.
//

import UIKit

enum Tool {
    case draw
    case erase
}

// Hard coded grid size - Can be changed for any grid size
let gridSize = CGFloat(64)

// Core drawing class - Controls drawing canvas and all interactions and updates for layers and overview
class Canvas: UIView, UIGestureRecognizerDelegate {
    // Core canvas vars
    let maxZoom = gridSize / 3
    var pixelSize = CGFloat(1)
    var pixelPoints: [CGRect] = []
    var canvasOverview: OverviewDelegate?
    
    // For current drawing task
    var curDelegate: PreviewDelegate?
    var curLayer: CALayer?
    var curShapeLayer: CAShapeLayer?
    var curTool: Tool = .draw
    var curColor: CGColor = UIColor.black.cgColor
    var bRandColor = false
    var activeLayerIndex = 0
    
    var redoStack: [CAShapeLayer] = []
    var halfBounds = CGFloat(1)
    // Zoom
    var activeCenter = CGPoint(x: 0, y: 0)
    var activeScale = CGFloat(1)
    var goalCenter = CGPoint(x: 0,y: 0)
    var goalScale = CGFloat(1)
    var reqTrans = CGPoint(x: 0,y: 0)
    // Pan
    var lastTrans = CGPoint(x: 0, y: 0)
    var bPanning = false
    let panningScale = CGFloat(1.4)
    
    // MARK: REDRAW
    override func draw(_ rect: CGRect) {
        // Get current context and active shape layer
        guard let context = UIGraphicsGetCurrentContext(), let _ = curLayer else {return}
        
        context.addRects(pixelPoints)
        
        // Set shape layer path to newly drawn context path with user color
        if let curpath = context.path {
            curShapeLayer!.fillColor = curTool == .draw ? curColor : UIColor.white.cgColor
            curShapeLayer!.path = curpath
        }
        
        updateLayerPreview()
        updateOverview()
    }
    
    // MARK: PREVIEW UPDATES
    // Update current layer preview (delegate) with image of current layer, even if hidden
    func updateLayerPreview() {
        let ogHidden = layer.isHidden
        layer.isHidden = false
        UIGraphicsBeginImageContext(bounds.size)
        
        if let curLayer = curLayer, let context = UIGraphicsGetCurrentContext(), let delegate = curDelegate {
            curLayer.render(in: context)
            delegate.SetCanvasPreview(UIGraphicsGetImageFromCurrentImageContext(), ogHidden)
        }
        
        UIGraphicsEndImageContext()
        layer.isHidden = ogHidden
    }
    
    // Update provided layer preview (delegate) with image of provided layer, even if hidden
    func updateLayerPreview(layer: CALayer, delegate: PreviewDelegate) {
        let ogHidden = layer.isHidden
        layer.isHidden = false
        UIGraphicsBeginImageContext(bounds.size)
        
        if let context = UIGraphicsGetCurrentContext() {
            layer.render(in: context)
            delegate.SetCanvasPreview(UIGraphicsGetImageFromCurrentImageContext(), ogHidden)
        }
        
        UIGraphicsEndImageContext()
        layer.isHidden = ogHidden
    }
    
    // Update overview preview (delegate) with image of all layers
    func updateOverview() {
        UIGraphicsBeginImageContext(bounds.size)
        
        if let context = UIGraphicsGetCurrentContext(), let delegate = canvasOverview {
            if let allLayers = layer.sublayers {
                for layer in allLayers {layer.render(in: context)}
            }
            delegate.SetCanvasPreview(UIGraphicsGetImageFromCurrentImageContext(), false)
        }
        
        UIGraphicsEndImageContext()
    }
    
    // MARK: UNDO/REDO
    func undo() {
        if let actLayer = curLayer, var subs = actLayer.sublayers, subs.count > 0 {
            if let last = subs.removeLast() as? CAShapeLayer {
                last.removeFromSuperlayer()
                redoStack.append(last)
                
                updateLayerPreview()
                updateOverview()
            }
        }
    }
    
    func redo() {
        if let actLayer = curLayer, redoStack.count > 0 {
            actLayer.addSublayer(redoStack.removeLast())
            
            updateLayerPreview()
            updateOverview()
        }
    }
    
    // MARK: LAYERS
    // New shape layer used per finger touch
    func newShapeLayer() {
        if let topLayer = curLayer {
            redoStack.removeAll(keepingCapacity: true)
            
            curShapeLayer = CAShapeLayer()
            topLayer.addSublayer(curShapeLayer!)
        }
    }
    
    // Add new layer with preview delegate
    func addLayer(newLayer: CALayer, delegate: PreviewDelegate?) {
        redoStack.removeAll(keepingCapacity: true)
        
        curDelegate = delegate
        curLayer = newLayer
        self.layer.addSublayer(newLayer)
        updateLayerPreview()
    }
    
    func insertLayer(newLayer: CALayer, at: UInt32, delegate: PreviewDelegate) {
        redoStack.removeAll(keepingCapacity: true)
        
        curDelegate = delegate
        curLayer = newLayer
        self.layer.insertSublayer(newLayer, at: at)
        updateLayerPreview()
    }
    
    // Delete layer at specified index (layer order)
    func deleteLayer(_ index: Int) {
        redoStack.removeAll(keepingCapacity: true)
        
        if let delLayer = self.layer.sublayers?.remove(at: index) {
            delLayer.removeFromSuperlayer()
            
            if self.layer.sublayers?.count == 0 || self.layer.sublayers?.count == nil {
                addLayer(newLayer: CALayer(), delegate: nil)
            }
            
            activeLayerIndex = 0
            curLayer = self.layer.sublayers?.first
            updateOverview()
        }
    }
    
    // Set active layer at index with given preview delegate
    func setActiveLayer(layerIndex: Int, delegate: PreviewDelegate?) {
        redoStack.removeAll(keepingCapacity: true)
        
        if let subs = self.layer.sublayers, subs.count > layerIndex {
            activeLayerIndex = layerIndex
            if delegate != nil { curDelegate = delegate! }
            curLayer = subs[layerIndex]
            updateLayerPreview()
        }
    }
    
    // MARK: DRAW TOOL
    // Add a single pixel given a point to the new to draw pixelPoints
    func addPixel(_ point: CGPoint) {
        // Touch in bounds of view
        if self.bounds.contains(point) {
            // Touch not already in touch list by pixel point
            for pixel in pixelPoints {
                if pixel.contains(point) {
                    return
                }
            }
            
            // Add pixel
            let x = floor(point.x / pixelSize) * pixelSize
            let y = floor(point.y / pixelSize) * pixelSize
            pixelPoints.append(CGRect(x: x, y: y, width: pixelSize, height: pixelSize))
            
            setNeedsDisplay()
        }
    }
    
    func getRandomColor() -> UIColor {
        UIColor(red: CGFloat(arc4random()) / CGFloat(UInt32.max), green: CGFloat(arc4random()) / CGFloat(UInt32.max), blue: CGFloat(arc4random()) / CGFloat(UInt32.max), alpha: 0.9)
    }

    // MARK: INITIALIZER
    func constructCanvas(_ layers: CALayer? = nil) {
        // Build gesture recognizers for zoom/pan functionality
        // Enable multi touch
        self.isMultipleTouchEnabled = true
        
        // Add one finger tap gesture
        let touchGestureOne = UITapGestureRecognizer(target: self, action: #selector(handleOneTap))
        touchGestureOne.delegate = self
        touchGestureOne.numberOfTouchesRequired = 1
        touchGestureOne.numberOfTapsRequired = 1
        self.addGestureRecognizer(touchGestureOne)
        
        // Add two finger tap gesture
        let touchGestureTwo = UITapGestureRecognizer(target: self, action: #selector(handleTwoTap))
        touchGestureTwo.delegate = self
        touchGestureTwo.numberOfTouchesRequired = 2
        touchGestureTwo.numberOfTapsRequired = 2
        self.addGestureRecognizer(touchGestureTwo)
        
        // Add one finger pan gesture
        let panGestureOne = UIPanGestureRecognizer(target: self, action: #selector(handleOnePan))
        panGestureOne.delegate = self
        panGestureOne.minimumNumberOfTouches = 1
        panGestureOne.maximumNumberOfTouches = 1
        self.addGestureRecognizer(panGestureOne)
        
        // Add two finger pan gesture
        let panGestureTwo = UIPanGestureRecognizer(target: self, action: #selector(handleTwoPan))
        panGestureTwo.delegate = self
        panGestureTwo.minimumNumberOfTouches = 2
        panGestureTwo.maximumNumberOfTouches = 2
        self.addGestureRecognizer(panGestureTwo)
        
        // Add pinch gesture
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        pinchGesture.delegate = self
        self.addGestureRecognizer(pinchGesture)
        
        // Set pixel size based on grid size and image size
        self.pixelSize = frame.width / gridSize
        // Reserve space for drawing pixel array
        self.pixelPoints.reserveCapacity(Int(gridSize) * 2)
        
        // Used to simplify math operations during zoom/pan ops
        halfBounds = self.bounds.width / 2
        
        // If layers were provided (from file data), rebuild image layers using them
        if layers != nil {reconstructLayers(layers!)}
    }
    
    // Rebuild image layers using provided layer object. Layers are stored in the same order for all files, so rebuild is possible by pulling layers out in correct order. Object passed will be copied, not emptied
    func reconstructLayers(_ layers: CALayer) {
        if let folderSublayers = layers.sublayers {
            for folderSubLayer in folderSublayers {
                let newFolderSubLayer = CALayer(layer: folderSubLayer)
                
                if let shapeSubLayers = folderSubLayer.sublayers {
                    for shapeSubLayer in shapeSubLayers {
                        if let shapeSubLayer = shapeSubLayer as? CAShapeLayer {
                            let newShapeSubLayer = CAShapeLayer(layer: shapeSubLayer)
                            
                            newShapeSubLayer.fillColor = shapeSubLayer.fillColor
                            newShapeSubLayer.path = shapeSubLayer.path?.copy()
                            
                            newFolderSubLayer.addSublayer(newShapeSubLayer)
                        }
                    }
                }
                
                self.layer.addSublayer(newFolderSubLayer)
            }
        }
        
        curLayer = self.layer.sublayers?.first
        activeLayerIndex = 1
        updateLayerPreview()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: TOUCH EVENTS
    var bStarted = false
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touchC = event?.touches(for: self)?.count
        
        // Used to avoid cross contamination with other gestures
        if touchC == 1 {
            if bRandColor { curColor = getRandomColor().cgColor }
            
            // Append new shape layer to handle current new draw line
            newShapeLayer()
            // Clear old drawn pixels
            pixelPoints.removeAll(keepingCapacity: true)
            // Add new touch points through addPixel
            for touch in touches {
                addPixel(touch.location(in: self))
            }
            
            bStarted = true
        }
    }
    
    // One finger tap - set drawing bool
    @objc func handleOneTap(_ gRec: UITapGestureRecognizer) {
        bStarted = false
    }
    
    // Two finger tap - reset zoom/pan
    @objc func handleTwoTap(_ gRec: UITapGestureRecognizer) {
        let trans = CGAffineTransform.identity
        layer.setAffineTransform(trans)
        updateOverviewBox(trans)
    }
    
    // MARK: 2 FINGER ZOOM
    // Zoom function takes pinch amount and center and zooms/pans towards that location. Zooming in will attempt to center pinch location, zooming out will attempt to recenter original location, zooming beyond that will keep original location centered. Zoom/pan is not allowed to force canvas out of bounds on any side
    @objc func handlePinch(_ gRec: UIPinchGestureRecognizer) {
        // If panning already simplify zoom
        if bPanning {
            var trans = layer.affineTransform().scaledBy(x: gRec.scale, y: gRec.scale)
            if trans.a < 1 {
                trans.a = 1
                trans.d = 1
            }
            else if trans.a > maxZoom {
                trans.a = maxZoom
                trans.d = maxZoom
            }
            
            gRec.scale = 1
            return
        }
        
        if gRec.state == .ended || gRec.state == .cancelled || gRec.state == .failed {
            return
        }
        
        let loc = gRec.location(in: self)
        let scale = gRec.scale
        
        var trans = layer.affineTransform()
        let maxTrans = (trans.a - 1) * halfBounds
        
        // Store zoom starting properties on begin
        if gRec.state == .began {
            // Store zoom level pre op
            activeScale = trans.a
            // Store screen center before zoom op
            activeCenter = CGPoint(x: trans.tx / activeScale, y: trans.ty / activeScale)
            
            // Compute required translate to center screen on zoom point
            let xDifScaled = (center.x - loc.x) / trans.a
            let yDifScaled = (center.x - loc.y) / trans.a
            reqTrans = CGPoint(x: xDifScaled, y: yDifScaled)
            // Compute zoom point desired actual screen center
            goalCenter = CGPoint(x: activeCenter.x + xDifScaled, y: activeCenter.y + yDifScaled)
            
            // Compute zoom level needed to scale screen to get desired center as center (max of zoom needed to get to x or y)
            goalScale = 1 + max(xDifScaled.magnitude, yDifScaled.magnitude) / halfBounds
            
            // Arbitrary goal needed if scale is already big enough to pan to desired center - scale up 20% to center appropriately
            if activeScale >= goalScale {
                goalScale = activeScale * 1.2
            }
        }
        
        // Set scale and confine between 1 and maxZoom (3 pixels)
        trans = trans.scaledBy(x: scale, y: scale)
        if trans.a < 1 {
            trans.a = 1
            trans.d = 1
        }
        else if trans.a > maxZoom {
            trans.a = maxZoom
            trans.d = maxZoom
        }
        
        // If user hasn't zoomed out from starting scale, and hasn't reached goal scale, keep trying to recenter
        // Translate is based on percentage current zoom is to goal zoom
        if trans.a < goalScale && trans.a >= activeScale && !bPanning{
            let scaleP = (trans.a - activeScale) / (goalScale - activeScale)
            let newX = (scaleP * reqTrans.x + activeCenter.x) * trans.a
            let newY = (scaleP * reqTrans.y + activeCenter.y) * trans.a
            
            trans.tx = newX
            trans.ty = newY
        }
        // Else if user has passed goal scale, keep goal center as center of screen as zooming continues
        else if trans.a >= activeScale && !bPanning {
            let newTx = trans.a * goalCenter.x
            let newTy = trans.a * goalCenter.y
            
            trans.tx = newTx
            trans.ty = newTy
        }
        // Else if user zoomed out from original zoom level, keep original center as center of screen as zooming continues
        else {
            let newTx = trans.a * activeCenter.x
            let newTy = trans.a * activeCenter.y
            
            trans.tx = newTx
            trans.ty = newTy
        }
        
        // Keep canvas translate within bounds of frame, maintaining sign
        if trans.tx.magnitude > maxTrans {
            trans.tx = trans.tx > 0 ? maxTrans : -maxTrans
        }
        if trans.ty.magnitude > maxTrans {
            trans.ty = trans.ty > 0 ? maxTrans : -maxTrans
        }
        
        // Update layer transform
        layer.setAffineTransform(trans)
        
        // Send translation/scale matrix to overview to update canvas overview 'current view' box
        updateOverviewBox(trans)
    
        // Reset scale to 1 to simpilfy tranform math
        gRec.scale = 1
    }
    
    // For a given canvas transform (zoom/pan), create bounding box on top of overview to indicate current viewpoint relative to entire canvas
    func updateOverviewBox(_ trans: CGAffineTransform) {
        if let del = canvasOverview {
            let extent = 1 / trans.a
            let y = 0.5 + extent * (trans.ty / self.bounds.width - 0.5)
            let x = 0.5 - extent * (trans.tx / self.bounds.width + 0.5)
            
            let boundingBox = CGRect(x: x, y: y, width: extent, height: extent)
            
            del.SetCanvasOverviewBox(boundingBox, self)
        }
    }
    
    // One finger move - draw
    @objc func handleOnePan(_ gRec: UIPanGestureRecognizer) {
        if !bStarted && gRec.state == .began {
            // Append new shape layer to handle current new draw line
            newShapeLayer()
            // Clear old drawn pixels
            pixelPoints.removeAll(keepingCapacity: true)
            // Add new touch points through addPixel
            addPixel(gRec.location(in: self))
            
            bStarted = true
        }
        else if gRec.state == .changed {
            addPixel(gRec.location(in: self))
        }
        else if gRec.state == .ended || gRec.state == .changed {
            bStarted = false
        }
    }
    
    // MARK: 2 FINGER PAN
    // Panning is not allowed to force canvas out of bounds on any side
    @objc func handleTwoPan(_ gRec: UIPanGestureRecognizer) {
        if gRec.state == .ended || gRec.state == .cancelled || gRec.state == .failed {
            bPanning = false
            return
        }
        
        let pan = gRec.translation(in: self)
        var trans = layer.affineTransform()
        let maxTrans = (trans.a - 1) * halfBounds
        
        if gRec.state == .began {
            bPanning = true
        }
        
        trans = trans.translatedBy(x: pan.x * panningScale, y: pan.y * panningScale)
        
        // Keep canvas translate within bounds of frame, maintaining sign
        if trans.tx.magnitude > maxTrans {
            trans.tx = trans.tx > 0 ? maxTrans : -maxTrans
        }
        if trans.ty.magnitude > maxTrans {
            trans.ty = trans.ty > 0 ? maxTrans : -maxTrans
        }
        
        layer.setAffineTransform(trans)
        updateOverviewBox(trans)
        gRec.setTranslation(.zero, in: self)
    }
    
    // MARK: GENERATE PREVIEWS
    // Return file image preview for file select cells
    func getFilePreview() -> UIImage? {
        var outImage: UIImage?
        
        UIGraphicsBeginImageContext(bounds.size)
        
        if let context = UIGraphicsGetCurrentContext() {
            if let allLayers = layer.sublayers {
                for layer in allLayers {layer.render(in: context)}
            }
            
            outImage = UIGraphicsGetImageFromCurrentImageContext()
        }
        
        UIGraphicsEndImageContext()
        
        return outImage
    }
    
    // Return layer image of given layer for layer screen cells, even if hidden
    func getLayerPreview(_ layer: CALayer) -> UIImage? {
        var outImage: UIImage?
        let ogHidden = layer.isHidden
        
        UIGraphicsBeginImageContext(bounds.size)
        
        if let context = UIGraphicsGetCurrentContext() {
            layer.isHidden = false
            layer.render(in: context)
            outImage = UIGraphicsGetImageFromCurrentImageContext()
        }
        
        UIGraphicsEndImageContext()
        
        layer.isHidden = ogHidden
        return outImage
    }
}
