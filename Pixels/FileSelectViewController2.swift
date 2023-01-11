//
//  FileSelectViewController.swift
//  tasotirin_FinalProject_Pixels
//
//  Created by Tavis Sotirin on 3/13/21.
//

import UIKit

class FileSelectViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.delegate = self
        self.tableView.dataSource = self
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 4
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "localFile", for: indexPath) as! FileCell
        
        cell.title.text = "Project title default"
        cell.details.text = "Updated on\nDate1\nCreated\nDate2"

        return cell

    }

}
