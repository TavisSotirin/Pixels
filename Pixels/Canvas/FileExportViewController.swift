//
//  FileExportViewController.swift
//  tasotirin_FinalProject_Pixels
//
//  Created by Tavis Sotirin on 3/14/21.
//

import UIKit

// View controller for file export screen
// Responsible for saving files to photo library
class FileExportViewController: UIViewController {
    @IBOutlet var previewView: UIImageView!
    var preview: UIImage?
    var alert: AlertCreator?
    var borderDraw: BorderDraw?

    // On load create border draw object and set imageview with segue passed canvas image
    override func viewDidLoad() {
        super.viewDidLoad()
        alert = AlertCreator(self)
        
        borderDraw = BorderDraw(borderSize: 2, frame: self.view.frame)
        self.view.insertSubview(borderDraw!, at: 0)
        
        previewView.image = preview
    }
    
    // Add border around image
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        borderDraw?.addBorder(previewView.frame, .black)
    }
    
    // On button press, save image to library
    // Pop up alert informing user of save status
    @IBAction func saveImage(_ sender: UIButton) {
        if let im = preview {
            UIImageWriteToSavedPhotosAlbum(im, self, #selector(saveError), nil)
            alert?.displayPopUp(popTitle: "Save Succesful", message: "Image was saved successfully!")
        }
        else {
            alert?.displayPopUp(popTitle: "Save Error", message: "Something went wrong.\nThe image was not saved.")
        }
    }
    
    @objc func saveError(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        return
    }
}
