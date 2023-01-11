//
//  FileCell.swift
//  tasotirin_FinalProject_Pixels
//
//  Created by Tavis Sotirin on 3/9/21.
//

import UIKit

// Table and collection view cell objects

class FileCell: UITableViewCell {
    @IBOutlet var fileInfoText: UITextView!
    @IBOutlet var preview: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}

class LayerCell: UICollectionViewCell {
    @IBOutlet var preview: CanvasPreview!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
}

class LayerCellFull: UITableViewCell {
    @IBOutlet var preview: UIImageView!
    @IBOutlet var visibility: UISwitch!
    @IBOutlet var dupeButton: UIButton!
    
    var layerPtr: UnsafeMutablePointer<CALayer>?
    
    @IBAction func updateLayerVis(_ sender: UISwitch) {
        layerPtr?.pointee.isHidden = !sender.isOn
    }
}
