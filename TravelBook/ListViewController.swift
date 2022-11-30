//
//  ListViewController.swift
//  TravelBook
//
//  Created by Fikriye Nur Harmandar on 29.11.2022.
//

import UIKit
import CoreData

class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    var idArray = [UUID]()
    var nameArray = [String]()
    var choosenPlace = ""
    var choosenPlaceId : UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addLocation))
        
        getData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name("newPlace"), object: nil)
    }
    
    @objc func getData () {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
        request.returnsObjectsAsFaults = false
        
        do {
            let results = try context.fetch(request)
            if results.count > 0 {
                self.idArray.removeAll(keepingCapacity: false)
                self.nameArray.removeAll(keepingCapacity: false)
                
                for result in results as! [NSManagedObject] {
                    if let id = result.value(forKey: "id") as? UUID {
                        self.idArray.append(id)
                    }
                    
                    if let name = result.value(forKey: "placeName") as? String {
                        self.nameArray.append(name)
                    }
                    
                    tableView.reloadData()
                }
            }
        }
        catch {
            print("Error")
        }
    }
    
    @objc func addLocation() {
        choosenPlace = ""
        performSegue(withIdentifier: "toListVC", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nameArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        var content = cell.defaultContentConfiguration()
        content.text = nameArray[indexPath.row]
        cell.contentConfiguration = content
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        choosenPlaceId = idArray[indexPath.row]
        choosenPlace = nameArray[indexPath.row]
        performSegue(withIdentifier: "toListVC", sender: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toListVC" {
            let destinationVC = segue.destination as! ViewController
            destinationVC.selectedPlaceId = choosenPlaceId
            destinationVC.selectedPlace = choosenPlace
        }
    }
}
