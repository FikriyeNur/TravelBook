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
    @IBOutlet weak var saveButton: UIButton!
    
    var locationManager = CLLocationManager()
    var choosenLatitude = Double()
    var choosenLongitude = Double()
    var selectedPlace = ""
    var selectedPlaceId : UUID?
    
    var annotationPlaceName = ""
    var annotationComment = ""
    var annotationLatitude = 0.0
    var annotationLongitude = 0.0
    
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
        
        if selectedPlace != "" {
            saveButton.isHidden = true
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let id = selectedPlaceId!.uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", id)
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                let results = try context.fetch(fetchRequest)
                if results.count > 0 {
                    for result in results as! [NSManagedObject] {
                        if let name = result.value(forKey: "placeName") as? String {
                            annotationPlaceName = name
                            
                            if let comment = result.value(forKey: "comment") as? String {
                                annotationComment = comment
                                
                                if let latitude = result.value(forKey: "latitude") as? Double {
                                    annotationLatitude = latitude
                                    
                                    if let longitude = result.value(forKey: "longitude") as? Double {
                                       annotationLongitude = longitude
                                        
                                        let annotation = MKPointAnnotation()
                                        annotation.title = annotationPlaceName
                                        annotation.subtitle = annotationComment
                                        let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                        annotation.coordinate = coordinate
                                        
                                        mapView.addAnnotation(annotation)
                                        nameText.text = annotationPlaceName
                                        commentText.text = annotationComment
                                        
                                        locationManager.stopUpdatingLocation()
                                        let span = MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
                                        let region = MKCoordinateRegion(center: coordinate, span: span)
                                        mapView.setRegion(region, animated: true)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            catch {
                alertMessage(title: "Error", message: "Selected location not found!")
            }
        }
        else {
            saveButton.isHidden = false
        }
    }

    @objc func chooseLocation(gestureRegocnizer : UILongPressGestureRecognizer) {
        if gestureRegocnizer.state == .began{
            let touchPoint = gestureRegocnizer.location(in: self.mapView)
            let touchedCoordinates = self.mapView.convert(touchPoint, toCoordinateFrom: self.mapView)
            
            if nameText.text == "" {
                alertMessage(title: "Error", message: "Enter Name")
            }
            else if commentText.text == "" {
                alertMessage(title: "Error", message: "Enter Comment")
            }
            else {
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
        if selectedPlace  == "" {
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.purple
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        }
        else {
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectedPlace != "" && annotationLatitude != 0 && annotationLongitude != 0 {
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            CLGeocoder().reverseGeocodeLocation(requestLocation) { placemarks, error in
                if let placeMark = placemarks {
                    if placeMark.count > 0 {
                        let newPlaceMark = MKPlacemark(placemark: placeMark[0])
                        let item = MKMapItem(placemark: newPlaceMark)
                        item.name = self.annotationPlaceName
                        
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                    }
                }
            }
        }
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
                NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil)
                navigationController?.popViewController(animated: true)
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

