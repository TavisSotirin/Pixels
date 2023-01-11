//
//  CanvasViewController.swift
//  tasotirin_FinalProject_Pixels
//
//  Created by Tavis Sotirin on 3/13/21.
//

import UIKit

// View Controller responsible for canvas screen - handles communication setup and generation of layer cells, and data passing between all other views
class CanvasViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIColorPickerViewControllerDelegate, UIGestureRecognizerDelegate, LayerDelegate {
    @IBOutlet var canvas: Canvas!
    @IBOutlet var canvasOverview: CanvasOverview!
    @IBOutlet var layerScroll: UICollectionView!
    @IBOutlet var selectColorButton: UIButton!
    @IBOutlet var colorPresets: [UIButton]!
    @IBOutlet var drawTool: UIButton!
    @IBOutlet var eraseTool: UIButton!
    @IBOutlet var eyeTool: UIButton!
    @IBOutlet var newLayerButton: UIButton!
    
    var alert: AlertCreator?
    var bLayoutSubviews = true
    var borderDraw: BorderDraw?
    let selectColorButtonLayer = CAShapeLayer()
    let phoneFeedback = UINotificationFeedbackGenerator()
    
    var fileData: DrawingFile?
    var bPullingLayerScreen = false
    
    // Hide status bar 1/2
    override var prefersStatusBarHidden: Bool { true }

    // MARK: SETUP
    override func viewDidLoad() {
        super.viewDidLoad()
        canvas.backgroundColor = .clear
        
        // Hide status bar 2/2
        modalPresentationCapturesStatusBarAppearance = true
        // Alert popup creator object
        alert = AlertCreator(self)
        
        // Set collection view delegates
        self.layerScroll.delegate = self
        self.layerScroll.dataSource = self
        
        // Recognizer to pull up layer screen
        let panUp = UIPanGestureRecognizer(target: self, action: #selector(toLayerScreen))
        panUp.delegate = self
        layerScroll.addGestureRecognizer(panUp)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // This func runs twice at startup but layout should only happen once
        if bLayoutSubviews {
            if let firstLayerCell = layerScroll.cellForItem(at: IndexPath(row: 0, section: 0)) as? LayerCell {
                // Create framing view to clip canvas to - needed to avoid canvas zooming/panning going out of bounds
                let framingView = UIView(frame: canvas.frame)
                framingView.clipsToBounds = true
                self.view.addSubview(framingView)
                framingView.addSubview(canvas)
                
                setupButtons()
                
                // Build canvas
                canvas.constructCanvas(fileData?.layers)
                canvas.canvasOverview = canvasOverview
                canvas.curDelegate = firstLayerCell.preview
                
                // Setup overview
                canvasOverview.setup()
                
                // Update preview delegates in case file was loaded
                for indexPath in layerScroll.indexPathsForVisibleItems {
                    let cell = layerScroll.cellForItem(at: indexPath) as! LayerCell
                    
                    if let layer = canvas.layer.sublayers?[indexPath.row] {
                        canvas.updateLayerPreview(layer: layer, delegate: cell.preview)
                    }
                }
                
                // Create and append border creator to subview
                borderDraw = BorderDraw(borderSize: 2, frame: self.view.frame)
                self.view.insertSubview(borderDraw!, at: 0)
                
                borderDraw?.addBorder(canvasOverview.frame, .black)
                borderDraw?.addBorder(framingView.frame, .black)
                
                bLayoutSubviews = false
            }
        }
    }
    
    // Set up color buttons and tools
    func setupButtons() {
        let brColor = UIColor.black.cgColor
        
        drawTool.layer.borderWidth = 2.0
        drawTool.layer.borderColor = UIColor.red.cgColor
        
        eraseTool.layer.borderWidth = 2.0
        eraseTool.layer.borderColor = brColor
        
        // Draw color button
        selectColorButton.layer.borderWidth = 2.0
        selectColorButton.layer.borderColor = brColor
        
        let scale = CGFloat(0.9)
        let bFrame = selectColorButton.layer.frame
        var innerRect = bFrame.applying(CGAffineTransform(scaleX: scale, y: scale))
        
        let transX = bFrame.midX - innerRect.width / 2
        let transY = bFrame.midY - innerRect.height / 2
        
        innerRect = innerRect.applying(CGAffineTransform(translationX: transX, y: transY))
        
        selectColorButtonLayer.path  = UIBezierPath(ovalIn: innerRect).cgPath
        selectColorButtonLayer.fillColor = brColor
        selectColorButton.layer.addSublayer(selectColorButtonLayer)
        
        // Set up last used color buttons
        for (i,button) in colorPresets.enumerated() {
            button.layer.borderColor = brColor
            button.layer.borderWidth = 1.0
            
            button.backgroundColor = i==0 ? .black : .clear
        }
    }
    
    // MARK: BUTTONS
    // Confirm pan is vertical or horizontal to avoid ignoring layer cell scrolling
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let panRec = gestureRecognizer as? UIPanGestureRecognizer {
            let vel = panRec.velocity(in: layerScroll)
            return abs(vel.y) > abs(vel.x)
        }
        return true
    }
    
    @IBAction func setTool(_ sender: UIButton) {
        drawTool.layer.borderColor = UIColor.black.cgColor
        eraseTool.layer.borderColor = UIColor.black.cgColor
        
        sender.layer.borderColor = UIColor.red.cgColor
        canvas.curTool = sender.tag == 1 ? .erase : .draw
    }
    
    @IBAction func unredo(_ sender: UIButton) {
        if sender.tag == 0 {
            canvas.undo()
        }
        else if sender.tag == 1 {
            canvas.redo()
        }
    }
    
    @IBAction func selectColor() {
        let picker = UIColorPickerViewController()
        picker.selectedColor = UIColor(cgColor: canvas.curColor)
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
    }
    
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        // Don't allow zero alpha colors
        let colorPtr = UnsafeMutablePointer<CGFloat>.allocate(capacity: 2)
        viewController.selectedColor.getWhite(colorPtr, alpha: colorPtr.advanced(by: 1))
        
        if colorPtr.advanced(by: 1).pointee == 0 {
            colorPtr.deallocate()
            return
        }
        colorPtr.deallocate()
        
        // Update selected color
        canvas.curColor = viewController.selectedColor.cgColor
        selectColorButtonLayer.fillColor = viewController.selectedColor.cgColor
        
        // Update recently used color preset buttons
        if let first = colorPresets.first {
            var color: UIColor? = first.backgroundColor
            first.backgroundColor = viewController.selectedColor
            
            for (i,button) in colorPresets.enumerated() {
                if let lastColor = color, i != 0, lastColor != .clear {
                    let tmpColor = button.backgroundColor
                    button.backgroundColor = lastColor
                    color = tmpColor
                }
            }
        }
    }
    
    @IBAction func presetColor(_ sender: UIButton) {
        if let color = sender.backgroundColor, color != .clear {
            canvas.curColor = color.cgColor
            selectColorButtonLayer.fillColor = color.cgColor
        }
    }
    
    // MARK: NEW LAYER
    // Add new layer to image
    @IBAction func NewLayer(_ sender: UIButton) {
        // Change cells back to black border
        updateNonActiveCells()
        
        if let count = canvas.layer.sublayers?.count {
            // Add layer to canvas
            let indexPath = IndexPath(row: count, section: 0)
            let newLayer = CALayer()
            canvas.addLayer(newLayer: newLayer, delegate: nil)
        
            // Update canvas and file data
            canvas.activeLayerIndex = indexPath.row
            fileData?.count += 1
            
            // Update collection view
            layerScroll.insertItems(at: [indexPath])
                
            // If new cell is visible, update canvas preview delegate
            if let cell = layerScroll.cellForItem(at: indexPath) as? LayerCell {
                canvas.curDelegate = cell.preview
                canvas.updateLayerPreview()
            }
        }
    }
    
    // MARK: COLLECTION VIEW
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fileData?.count ?? 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "layerCell", for: indexPath) as! LayerCell
        cell.layer.borderWidth = 1.0
        cell.layer.borderColor = UIColor.black.cgColor
        
        cell.preview.delegate = self
        cell.preview.layerIndex = indexPath.row
        cell.preview.setup()
        
        // Active cell has red border
        if canvas.activeLayerIndex == indexPath.row {
            canvas.curDelegate = cell.preview
            cell.layer.borderWidth = 2.0
            cell.layer.borderColor = UIColor.red.cgColor
        }
        
        // Update layer previews when cells become visible
        if let subs = canvas.layer.sublayers {
            if subs.endIndex > indexPath.row {
                let layer = subs[indexPath.row]
                canvas.updateLayerPreview(layer: layer, delegate: cell.preview)
                if layer.isHidden {cell.preview.backgroundColor = .lightGray}
                else {cell.preview.backgroundColor = .clear}
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.height, height: collectionView.bounds.height)
    }
    
    // Update active layer
    func setActiveLayer(layerIndex: Int) {
        if let cell = layerScroll.cellForItem(at: IndexPath.init(row: layerIndex, section: 0)) as? LayerCell {
            canvas.setActiveLayer(layerIndex: layerIndex, delegate: cell.preview)
            
            updateNonActiveCells()
            cell.layer.borderWidth = 2.0
            cell.layer.borderColor = UIColor.red.cgColor
        }
    }
    
    // Set visible cells to black borders
    func updateNonActiveCells() {
        for cell in layerScroll.visibleCells {
            cell.layer.borderWidth = 1.0
            cell.layer.borderColor = UIColor.black.cgColor
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // To File Select Screen
        if let _ = segue.destination as? FileSelectViewController {
            // Update last edit date to now
            if let file = fileData {
                file.lastUpdated = Date()
            }
            
            // Update file preview
            fileData?.preview = canvas.getFilePreview()
        }
        // To Save Image Screen
        else if let dest = segue.destination as? FileExportViewController {
            dest.preview = canvas.getFilePreview()
        }
        // To Layer Detail Controller
        else if let dest = segue.destination as? LayerViewController {
            dest.canvas = self
        }
    }
    
    // Confirm leave canvas
    @IBAction func toFileSelect(_ sender: UIButton) {
        alert?.displayPopUp(popTitle: "Return to File Select?", message: "File will be saved while app is running", actionList: ["Cancel":({},.cancel), "To File Select":(segueUnwindToFileSelect, .default)], style: .alert)
    }
    
    // Update file data and unwind to file select
    func segueUnwindToFileSelect() {
        fileData?.layers = canvas.layer
        self.performSegue(withIdentifier: "unwindToFileSelect", sender: self)
    }
    
    // Pull up layer screen, only once since pan is continous
    @objc func toLayerScreen(_ gRec: UIPanGestureRecognizer) {
        if !bPullingLayerScreen {
            performSegue(withIdentifier: "toLayerScreen", sender: self)
            bPullingLayerScreen = true
        }
    }
    
    @IBAction func unwindFromLayer(unwindSegue: UIStoryboardSegue) {
        for indexPath in layerScroll.indexPathsForVisibleItems {
            if let layer = canvas.layer.sublayers?[indexPath.row] {
                canvas.updateLayerPreview(layer: layer, delegate: (layerScroll.cellForItem(at: indexPath) as! LayerCell).preview)
            }
        }
    }
}
