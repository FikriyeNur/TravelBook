//
//  ViewController.swift
//  TravelBook
//
//  Created by Fikriye Nur Harmandar on 29.11.2022.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var commentText: UITextField!
    
    var locationManager = CLLocationManager()
    var choosenLatitude = Double()
    var choosenLongitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // best pil ömrünü kısaltır
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRegocnizer:)))
        gestureRecognizer.minimumPressDuration = 2
        mapView.addGestureRecognizer(gestureRecognizer)
        
        let keyboardRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(keyboardRecognizer)
    }

    @objc func chooseLocation(gestureRegocnizer : UILongPressGestureRecognizer) {
        if gestureRegocnizer.state == .began{
            let touchPoint = gestureRegocnizer.location(in: self.mapView)
            let touchedCoordinates = self.mapView.convert(touchPoint, toCoordinateFrom: self.mapView)
            
            if nameText.text == "" {
                alertMessage(title: "Error", message: "Enter Name")
            }
            else if commentText.text == "" {
                alertMessage(title: "Erro", message: "Enter Comment")
            }
            else{
                choosenLatitude = touchedCoordinates.latitude
                choosenLongitude = touchedCoordinates.longitude
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = touchedCoordinates
                annotation.title = nameText.text
                annotation.subtitle = commentText.text
                self.mapView.addAnnotation(annotation)
            }
        }
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: true)
        
    }

    @IBAction func saveLocation(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context  = appDelegate.persistentContainer.viewContext
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        
        if nameText.text == "" {
            alertMessage(title: "Error", message: "Enter Location")
        }
        else if commentText.text == ""  {
            alertMessage(title: "Error", message: "Enter Comment")
        }
        else if choosenLatitude == 0 {
            alertMessage(title: "Error", message: "Choose Location")
        }
        else if choosenLongitude == 0 {
            alertMessage(title: "Error", message: "Choose Location")
        }
        else {
            newPlace.setValue(UUID(), forKey: "id")
            newPlace.setValue(nameText.text, forKey: "placeName")
            newPlace.setValue(commentText.text, forKey: "comment")
            newPlace.setValue(choosenLatitude, forKey: "latitude")
            newPlace.setValue(choosenLongitude, forKey: "longitude")
            
            do {
                try context.save()
                alertMessage(title: "Success", message: "Location successfully saved.")
            } catch {
                alertMessage(title: "Error", message: "There's something wrong!")
            }
        }
    }
    
    func alertMessage(title: String, message: String) {
        let okButton = UIAlertAction(title: "OK", style: UIAlertAction.Style.destructive)
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(okButton)
        self.present(alert, animated: true, completion: nil)
    }
    
}

