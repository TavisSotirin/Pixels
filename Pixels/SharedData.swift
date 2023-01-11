//
//  SharedFunctions.swift
//  tasotirin_FinalProject_Pixels
//
//  Created by Tavis Sotirin on 3/13/21.
//

import UIKit

// File data passed between file selector and canvas

class DrawingFile {
    var title: String
    var createdOn: Date
    var lastUpdated: Date
    var layers: CALayer
    private var imCopy: UIImage?
    
    var count: Int = 1
    
    var preview: UIImage? {
        get {
            return imCopy
        }
        set(inIm) {
            imCopy = inIm
            cell?.preview.image = inIm
        }
    }
    
    var cell: FileCell?
    
    init(title: String, createdOn: Date) {
        self.title = title
        self.createdOn = createdOn
        self.lastUpdated = createdOn
        self.layers = CALayer()
        self.layers.addSublayer(CALayer())
    }
    
    // Copy constructor
    init(toCopy file: DrawingFile) {
        self.title = file.title + "_2"
        self.createdOn = Date()
        self.lastUpdated = Date()
        self.layers = CALayer(layer: file.layers)
        self.count = file.count
        self.imCopy = file.imCopy
        
        // Copy a set of CALayer objects
        if let folderSublayers = file.layers.sublayers {
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
                
                self.layers.addSublayer(newFolderSubLayer)
            }
        }
    }
}

class FileData {
    static let fileData = FileData()
    private var fileList: [DrawingFile] = []
    var count: Int {
        get {fileList.count}
    }
    
    private init() {
        // Implement - create file list from memory
    }
    
    func get(at: Int) -> DrawingFile {
        fileList[at]
    }
    
    func addFile(file: DrawingFile, isCopy: Bool = false) {
        fileList.insert(isCopy ? DrawingFile(toCopy: file) : file, at: 0)
    }
    
    func deleteFile(at: Int) {
        fileList.remove(at: at)
    }
    
    func copyFile(file: DrawingFile) -> DrawingFile {
        let newFile = DrawingFile(title: file.title, createdOn: Date())
        newFile.preview = file.preview
        
        // Main canvas layer
        if let subs = file.layers.sublayers, let newFileTopLayer = newFile.layers.sublayers?.first {
            // Image layers
            for topLayer in subs {
                // Shape layers
                if let topSubs = topLayer.sublayers {
                    let newLayer = CALayer()
                    
                    for layer in topSubs {
                        if let layer = layer as? CAShapeLayer, let path = layer.path?.copy() {
                            let newShapeLayer = CAShapeLayer()
                            newShapeLayer.path = path
                            newShapeLayer.fillColor = layer.fillColor
                            newLayer.addSublayer(newShapeLayer)
                        }
                    }
                    
                    newFileTopLayer.addSublayer(newLayer)
                }
            }
        }
        
        return newFile
    }
}
