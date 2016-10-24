//
//  FiltersViewController.swift
//  Yelp
//
//  Created by DINGKaile on 10/23/16.
//  Copyright © 2016 Timothy Lee. All rights reserved.
//

import UIKit

@objc protocol FiltersViewControllerDelegate {
    @objc optional func filtersViewController(filtersViewController: FiltersViewController, didUpdateFilters filters: [String: AnyObject])
}

class FiltersViewController: UITableViewController, SwitchCellDelegate {

    
    @IBOutlet var filterTable: UITableView!
    
    var distanceExpand: Bool = false
    var sortExpand: Bool = false
    var categoryExpand: Bool = false
    
    var tableStructure: [[String]]!
    
    var categories: [[String: String]]!
    var categoryNames: [String]!
    var switchStates = [Int: Bool]()
    var dealState: Bool = false
    var distanceIndex: Int = 0
    var sortByIndex: Int = 0
    
    weak var delegate: FiltersViewControllerDelegate?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        if let navBar = self.navigationController?.navigationBar {
            let shadow = NSShadow()
            shadow.shadowColor = UIColor.lightGray.withAlphaComponent(0.5)
            shadow.shadowOffset = CGSize(width: 2, height: 2)
            shadow.shadowBlurRadius = 4
            navBar.titleTextAttributes = [
                NSFontAttributeName : UIFont.boldSystemFont(ofSize: 18),
                NSForegroundColorAttributeName: UIColor.white,
                NSShadowAttributeName: shadow
            ]
        }
        
        self.categories = yelpCategories()
        self.categoryNames = [String]()
        for i in 0..<self.categories.count {
            self.categoryNames.append(self.categories[i]["name"]!)
        }
        
        self.filterTable.dataSource = self
        self.filterTable.delegate = self
        self.filterTable.rowHeight = UITableViewAutomaticDimension
        self.filterTable.estimatedRowHeight = 30
        self.filterTable.tableHeaderView?.backgroundColor = UIColor.white
        self.filterTable.tableHeaderView?.tintColor = UIColor.white
        
        self.tableStructure = [["Offering a Deal"],
                               ["Auto", "0.3 miles", "1 mile", "5 miles", "20 miles"],
                               ["Best Match", "Distance", "Highest Rated"],
                               categoryNames]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    /*********************************
    // MARK: - Table view functions
    *********************************/
 
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        if self.tableStructure != nil {
            return self.tableStructure.count
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        
        switch section {
        case 0:
            return 1
        case 1:
            return (self.distanceExpand ? self.tableStructure[1].count : 1)
        case 2:
            return (self.sortExpand ? self.tableStructure[2].count : 1)
        case 3:
            return (self.categoryExpand ? (self.tableStructure[3].count+1) : 4)
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        
        switch indexPath.section {
        case 0:
            cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as! SwitchCell
            (cell as! SwitchCell).switchLabel.text = self.tableStructure[0][indexPath.row]
        case 1:
            cell = tableView.dequeueReusableCell(withIdentifier: "CheckCell", for: indexPath) as! CheckCell
            if distanceExpand {
                (cell as! CheckCell).checkLabel.text = self.tableStructure[1][indexPath.row]
                if indexPath.row == self.distanceIndex {
                    (cell as! CheckCell).checkImage.image = UIImage(named: "check")
                } else {
                    (cell as! CheckCell).checkImage.image = UIImage(named: "circle")
                }
            } else {
                (cell as! CheckCell).checkLabel.text = self.tableStructure[1][self.distanceIndex]
                (cell as! CheckCell).checkImage.image = UIImage(named: "disclosure")
            }
            (cell as! CheckCell).checkImage.alpha = 0.5
        case 2:
            cell = tableView.dequeueReusableCell(withIdentifier: "CheckCell", for: indexPath) as! CheckCell
            if sortExpand {
                (cell as! CheckCell).checkLabel.text = self.tableStructure[2][indexPath.row]
                if indexPath.row == self.sortByIndex {
                    (cell as! CheckCell).checkImage.image = UIImage(named: "check")
                } else {
                    (cell as! CheckCell).checkImage.image = UIImage(named: "circle")
                }
            } else {
                (cell as! CheckCell).checkLabel.text = self.tableStructure[2][self.sortByIndex]
                (cell as! CheckCell).checkImage.image = UIImage(named: "disclosure")
            }
            (cell as! CheckCell).checkImage.alpha = 0.5
        case 3:
            if !(self.categoryExpand) && indexPath.row == 3 {
                cell = tableView.dequeueReusableCell(withIdentifier: "SeeAllCell", for: indexPath)
            } else if self.categoryExpand && indexPath.row == self.categoryNames.count {
                cell = tableView.dequeueReusableCell(withIdentifier: "SeeAllCell", for: indexPath)
                cell.textLabel?.text = "See Fewer"
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as! SwitchCell
                (cell as! SwitchCell).switchLabel.text = self.tableStructure[3][indexPath.row]
                (cell as! SwitchCell).delegate = self
                if self.switchStates[indexPath.row] != nil {
                    (cell as! SwitchCell).onSwitch.isOn = switchStates[indexPath.row]!
                } else {
                    (cell as! SwitchCell).onSwitch.isOn = false
                }
            }
            
        default:
            return UITableViewCell()
        }
        
        let contentView = cell?.contentView
        contentView?.layer.borderColor = UIColor.gray.cgColor
        contentView?.layer.cornerRadius = 3
        contentView?.clipsToBounds = true
        contentView?.layer.borderWidth = 1.0
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section == 1 {
            if self.distanceExpand {
                let cell = tableView.cellForRow(at: indexPath) as! CheckCell
                if indexPath.row != self.distanceIndex {
                    let oldCell = tableView.cellForRow(at: IndexPath(row: self.distanceIndex, section: 1)) as! CheckCell
                    UIView.animate(withDuration: 0.7, animations: {
                        oldCell.checkImage.image = UIImage(named: "circle")
                        cell.checkImage.image = UIImage(named: "check")
                    })
                }
            }
        } else if indexPath.section == 2 {
            if self.sortExpand {
                let cell = tableView.cellForRow(at: indexPath) as! CheckCell
                if indexPath.row != self.sortByIndex {
                    let oldCell = tableView.cellForRow(at: IndexPath(row: self.sortByIndex, section: 2)) as! CheckCell
                    UIView.animate(withDuration: 0.7, animations: {
                        oldCell.checkImage.image = UIImage(named: "circle")
                        cell.checkImage.image = UIImage(named: "check")
                    })
                }
            }
        }
        
        return indexPath
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1 {
            if self.distanceExpand {
                self.distanceExpand = false
                self.distanceIndex = indexPath.row
            } else {
                self.distanceExpand = true
            }
            self.filterTable.reloadSections([indexPath.section], with: UITableViewRowAnimation.automatic)
        } else if indexPath.section == 2 {
            if self.sortExpand {
                self.sortExpand = false
                self.sortByIndex = indexPath.row
            } else {
                self.sortExpand = true
            }
            self.filterTable.reloadSections([indexPath.section], with: UITableViewRowAnimation.automatic)
        } else if indexPath.section == 3 {
            if self.categoryExpand {
                if indexPath.row == self.categoryNames.count {
                    self.categoryExpand = false
                    self.filterTable.reloadSections([indexPath.section], with: UITableViewRowAnimation.automatic)
                }
            } else if indexPath.row == 3 {
                self.categoryExpand = true
                self.filterTable.reloadSections([indexPath.section], with: UITableViewRowAnimation.automatic)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 10.0
        } else {
            return 30.0
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let frameWidth = self.filterTable.frame.size.width
        var frameHeight = 30.0
        if section == 0 {
            frameHeight = 10.0
        }
        let headerView = UITableViewHeaderFooterView(frame: CGRect(x: 0.0, y: 0.0, width: Double(frameWidth), height: frameHeight))
        headerView.backgroundColor = UIColor.white
        switch section {
        case 1:
            headerView.textLabel?.text = "Distance"
            headerView.textLabel?.textColor = UIColor.red
            headerView.textLabel?.font = UIFont(name: "System Regular", size: 10.0)
        case 2:
            headerView.textLabel?.text = "Sort By"
            headerView.textLabel?.textColor = UIColor.black
            headerView.textLabel?.font = UIFont(name: "System Regular", size: 14.0)
        case 3:
            headerView.textLabel?.text = "Category"
            headerView.textLabel?.textColor = UIColor.black
            headerView.textLabel?.font = UIFont(name: "System Regular", size: 14.0)
        default:
            break
        }
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header: UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        header.backgroundColor = UIColor.white
        switch section {
        case 1:
            header.textLabel?.text = "Distance"
            header.textLabel?.textColor = UIColor.red
            header.textLabel?.font = UIFont(name: "System Regular", size: 10.0)
        case 2:
            header.textLabel?.text = "Sort By"
            header.textLabel?.textColor = UIColor.black
            header.textLabel?.font = UIFont(name: "System Regular", size: 14.0)
        case 3:
            header.textLabel?.text = "Category"
            header.textLabel?.textColor = UIColor.black
            header.textLabel?.font = UIFont(name: "System Regular", size: 14.0)
        default:
            break
        }
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func onCancelButton(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
        
    }
    
    @IBAction func onSearchButton(_ sender: AnyObject) {
        
        print("\nonSearchButton clicked")
        
        dismiss(animated: true, completion: nil)
        var filters = [String: AnyObject]()
        var selectedCategories = [String]()
        for (row, isSelected) in self.switchStates {
            if isSelected {
                selectedCategories.append(self.categories[row]["code"]!)
            }
        }
        if selectedCategories.count > 0 {
            filters["categories"] = selectedCategories as AnyObject?
        }
        filters["deal"] = self.dealState as AnyObject?
        filters["sort"] = self.sortByIndex as AnyObject?
        print("ready to call delegate function\n")
        self.delegate?.filtersViewController?(filtersViewController: self, didUpdateFilters: filters)
    }
    
    func switchCell(switchCell: SwitchCell, didChangeValue value: Bool) {
        let indexPath = tableView.indexPath(for: (switchCell as UITableViewCell))!
        if indexPath.section == 0 {
            self.dealState = value
        } else if indexPath.section == 3 {
            self.switchStates[indexPath.row] = value
        }
        
        print("filters view controller got the switch event")
    }
    
    func yelpCategories() -> [[String: String]] {
        return [["name": "Afghan", "code": "afghani"],
                ["name": "African", "code": "african"],
                ["name": "American, New", "code": "newamerican"],
                ["name": "American, Traditional", "code": "tradamerican"],
                ["name": "Arabian", "code": "arabian"],
                ["name": "Argentine", "code": "argentine"],
                ["name": "Armenian", "code": "armenian"],
                ["name": "Asian Fusion", "code": "asianfusion"],
                ["name": "Asturian", "code": "asturian"],
                ["name": "Australian", "code": "australian"],
                ["name": "Austrian", "code": "austrian"],
                ["name": "Baguettes", "code": "baguettes"],
                ["name": "Bangladeshi", "code": "bangladeshi"],
                ["name": "Barbeque", "code": "bbq"],
                ["name": "Basque", "code": "basque"],
                ["name": "Bavarian", "code": "bavarian"],
                ["name": "Beer Garden", "code": "beergarden"],
                ["name": "Beer Hall", "code": "beerhall"],
                ["name": "Beisl", "code": "beisl"],
                ["name": "Belgian", "code": "belgian"],
                ["name": "Bistros", "code": "bistros"],
                ["name": "Black Sea", "code": "blacksea"],
                ["name": "Brasseries", "code": "brasseries"],
                ["name": "Brazilian", "code": "brazilian"],
                ["name": "Breakfast & Brunch", "code": "breakfast_brunch"],
                ["name": "British", "code": "british"],
                ["name": "Buffets", "code": "buffets"],
                ["name": "Bulgarian", "code": "bulgarian"],
                ["name": "Burmese", "code": "burmese"],
                ["name": "Cafes", "code": "cafes"],
                ["name": "Cafeteria", "code": "cafeteria"],
                ["name": "Cajun/Creole", "code": "cajun"],
                ["name": "Cambodian", "code": "cambodian"],
                ["name": "Canadian", "code": "New)"]
        ]
    }
    
}
