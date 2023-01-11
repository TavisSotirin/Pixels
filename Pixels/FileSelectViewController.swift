//
//  FileSelectViewController.swift
//  tasotirin_FinalProject_Pixels
//
//  Created by Tavis Sotirin on 3/13/21.
//

import UIKit

// Store attributed text info for building file descriptions
struct TextData {
    static let placeholderTextDefault = NSAttributedString(string: "Create new file", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
    
    static let headerAttr: [NSAttributedString.Key : Any] = [
    .font: UIFont(name: "HelveticaNeue-Bold", size: 17)!
    ]

    static let subHeaderAttr: [NSAttributedString.Key : Any] = [
    .font: UIFont(name: "HelveticaNeue", size: 13)!
    ]

    static let dateAttr: [NSAttributedString.Key : Any] = [
        .foregroundColor: UIColor(red: 136/255, green: 136/255, blue: 136/255, alpha: 1.0),
        .font: UIFont(name: "HelveticaNeue", size: 11)!
    ]
}

// Start screen - Builds files from filelist, displayed as cells. Updated as canvasVC returns
class FileSelectViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var nfImage: UIImageView!
    @IBOutlet var nfTextField: UITextField!
    
    var alert: AlertCreator?
    var tapRec: UITapGestureRecognizer?
    let phoneFeedback = UINotificationFeedbackGenerator()
    
    let files = FileData.fileData
    var resetTimer: Timer?
    
    // MARK: VIEW LOAD
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        // Set alert creator object
        alert = AlertCreator(self)
        
        nfTextField.textColor = .black
        resetNewFileText()
        
        // Add tap rec for keyboard dismissal
        tapRec = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapRec!.cancelsTouchesInView = false
        tapRec!.delegate = self
        tableView.addGestureRecognizer(tapRec!)
        // Add long press rec for dupe/delete options on files
        let lpRec = UILongPressGestureRecognizer(target: self, action: #selector(handleCellLongPress))
        lpRec.minimumPressDuration = 0.35
        lpRec.delegate = self
        tableView.addGestureRecognizer(lpRec)
    }
    
    // On return update cells
    @IBAction func unwindFromCanvas(unwindSegue: UIStoryboardSegue) {
        tableView.reloadData()
    }
    
    // MARK: TEXT FIELD
    // Resign keyboard
    @objc func dismissKeyboard() {
        nfTextField.resignFirstResponder()
        resetNewFileText()
    }
    
    @IBAction func textEditStart(_ sender: UITextField) {
        nfTextField.placeholder = "Enter file name"
    }
    
    // Add timer for dismissing without return and invalidate timer in return key pressed
    @IBAction func textEditDismissed(_ sender: UITextField) {
        resetTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) {_ in self.resetNewFileText()}
    }
    
    func resetNewFileText() {
        nfTextField.text = ""
        nfTextField.attributedPlaceholder = TextData.placeholderTextDefault
    }
    
    // On return key press build new file
    @IBAction func returnKeyPressed(_ sender: UITextField) {
        let text = sender.text
        resetNewFileText()
        sender.resignFirstResponder()
        resetTimer?.invalidate()
        
        if let enteredTitle = text, enteredTitle.count > 0 {
            files.addFile(file: DrawingFile(title: enteredTitle, createdOn: Date()))
            tableView.beginUpdates()
            tableView.insertRows(at: [IndexPath.init(row: 0, section: 0)], with: .automatic)
            tableView.endUpdates()
        }
    }
    
    // Pop up for dupe/delete file
    @objc func handleCellLongPress(gRec: UILongPressGestureRecognizer) {
        if gRec.state == .began {
            let p = gRec.location(in: tableView)
            
            if let path = tableView.indexPathForRow(at: p) {
                let file = files.get(at: path.row)
                let title = file.title
                
                phoneFeedback.notificationOccurred(.success)
                alert?.displayPopUp(popTitle: "Edit File", message: "\(title)", actionList: ["Duplicate File":(buildClosure(self.duplicateFile, path),.default), "Delete File":(buildClosure(self.deleteFile, path),.destructive), "Cancel":({},.cancel)], style: .actionSheet)
            }
        }
    }
    
    // MARK: FILE OPERATIONS
    func deleteFile(_ path: IndexPath) {
        files.deleteFile(at: path.row)
        tableView.beginUpdates()
        tableView.deleteRows(at: [path], with: .fade)
        tableView.endUpdates()
    }
    
    func duplicateFile(_ path: IndexPath) {
        let file = files.get(at: path.row)
        files.addFile(file: file, isCopy: true)
        
        tableView.beginUpdates()
        tableView.insertRows(at: [path], with: .fade)
        tableView.endUpdates()
    }
    
    // MARK: TABLEVIEW
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // File list is holding cell data
   func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "localFile", for: indexPath) as! FileCell
        let file = files.get(at: indexPath.row)
        
        cell.preview.image = file.preview
        cell.preview.layer.borderWidth = 1.0
        cell.preview.layer.borderColor = UIColor.black.cgColor
        
        // Build description text
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d y HH:mm"
        
        let date1 = formatter.string(from: file.lastUpdated)
        let date2 = formatter.string(from: file.createdOn)
        
        let title = file.title
        
        let sep = "   "
        
        let t1 = "\(title)\n"
        let t2 = "\(sep)Last Updated\n"
        let t3 = "\(sep)  \(date1)\n"
        let t4 = "\(sep)Created\n"
        let t5 = "\(sep)  \(date2)"
        
        let attributedString = NSMutableAttributedString(string: t1+t2+t3+t4+t5)
        
        var loc = 0
        // Title
        attributedString.addAttributes(TextData.headerAttr, range: NSRange(location: 0, length: t1.count))
        loc += t1.count
        
        // Last updated
        attributedString.addAttributes(TextData.subHeaderAttr, range: NSRange(location: loc, length: t2.count))
        loc += t2.count
        
        // Date1
        attributedString.addAttributes(TextData.dateAttr, range: NSRange(location: loc, length: t3.count))
        loc += t3.count
        
        // Created
        attributedString.addAttributes(TextData.subHeaderAttr, range: NSRange(location: loc, length: t4.count))
        loc += t4.count
        
        // Date2
        attributedString.addAttributes(TextData.dateAttr, range: NSRange(location: loc, length: t5.count))
        
        cell.fileInfoText.attributedText = attributedString
        
        file.cell = cell
        
        return cell
    }
    
    // Delete on swipe - popup to confirm
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let file = files.get(at: indexPath.row)
            let title = file.title
            alert?.displayPopUp(popTitle: "Confirm Delete", message: "Are you sure you want to delete \(title)?", actionList: ["Delete File":(buildClosure(self.deleteFile,indexPath),.destructive), "Cancel":({},.cancel)], style: .alert)
        }
    }
    
    // MARK: PREPARE
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? CanvasViewController {
           if let indexPath = self.tableView.indexPathForSelectedRow {
            let file = files.get(at: indexPath.row)
            dest.fileData = file
           }
       }
    }
}
