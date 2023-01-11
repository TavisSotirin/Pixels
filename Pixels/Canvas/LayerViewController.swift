//
//  LayerViewController.swift
//  tasotirin_FinalProject_Pixels
//
//  Created by Tavis Sotirin on 3/15/21.
//

import UIKit

// View controller for detailed layer view with editing abilities
class LayerViewController: UITableViewController {
    var canvas: CanvasViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // When view is dismissed update canvas overview and layer collection view to reflect any changes
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isBeingDismissed {
            canvas?.bPullingLayerScreen = false
            canvas?.layerScroll.reloadData()
            canvas?.canvas.updateOverview()
        }
    }
    
    // MARK: TABLEVIEW
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    // File data count hold active layer count
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return canvas?.fileData?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Layer", for: indexPath) as! LayerCellFull
        
        cell.layer.borderWidth = 2.0
        cell.layer.borderColor = UIColor.black.cgColor
        
        cell.preview.layer.borderWidth = 1.0
        cell.preview.layer.borderColor = UIColor.black.cgColor
        
        // Organize cells to display layers backwards to show 'highest' layer first
        if let layerCount = canvas?.canvas.layer.sublayers?.count, let layer = canvas?.canvas.layer.sublayers?[layerCount - indexPath.row - 1] {
            cell.preview.image = canvas?.canvas.getLayerPreview(layer)
            cell.visibility.isOn = !layer.isHidden
            
            // Set pointer to layer to cell to avoid reference issues
            let layerPtr = UnsafeMutablePointer<CALayer>.allocate(capacity: 1)
            layerPtr.initialize(to: layer)
            cell.layerPtr = layerPtr
        }

        return cell
    }
    
    // Delete layer on swipe
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let layerCount = canvas?.canvas.layer.sublayers?.count, let _ = canvas?.canvas.layer.sublayers?[layerCount - indexPath.row - 1] {
                // If only one layer left don't update layer count (delete and readd new layer)
                if layerCount <= 1  {
                    canvas?.canvas.deleteLayer(layerCount - indexPath.row - 1)
                    tableView.reloadData()
                    canvas?.layerScroll.reloadData()
                    return
                }
                canvas?.fileData?.count -= 1
                canvas?.canvas.deleteLayer(layerCount - indexPath.row - 1)

                tableView.beginUpdates()
                tableView.deleteRows(at: [indexPath], with: .fade)
                tableView.endUpdates()
                
                let scrollIndexPath = IndexPath(row: layerCount - indexPath.row - 1, section: 0)
                canvas?.layerScroll.deleteItems(at: [scrollIndexPath])
            }
        }
    }
    
    // MARK: PREPARE
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? CanvasViewController {
            dest.updateNonActiveCells()
            dest.bPullingLayerScreen = false
        }
    }
}
