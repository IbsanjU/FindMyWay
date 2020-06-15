//
//  ViewController.swift
//  FindMyWay
//
//  Created by Admin on 14/06/2020.
//  Copyright © 2020 IbsanjU. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class customPin: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    
    init(pinTitle:String, pinSubTitle:String, location:CLLocationCoordinate2D) {
        self.title = pinTitle
        self.subtitle = pinSubTitle
        self.coordinate = location
    }
}

class ViewController: UIViewController {
    
    private let locationManager = CLLocationManager()
    private var currentCoordinate: CLLocationCoordinate2D?
    private var destinations: [MKPointAnnotation] = []
    private var currentRoute: MKRoute?
    var currentLoc: CLLocationCoordinate2D!
    var destinationLoc: CLLocationCoordinate2D!
    
    
    @IBOutlet weak var mapView: MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        gesture()
        configureLocationServices()
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
//    private func doubleTapGesture(){
//        let tap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
//        tap.numberOfTapsRequired = 2
//        view.addGestureRecognizer(tap)
//
//    }
//    @objc func doubleTapped(sender: UIGestureRecognizer) {
//        let locationInView = sender.location(in: mapView)
//        let locationOnMap = mapView.convert(locationInView, toCoordinateFrom: mapView)
//        addAnnotation(location: locationOnMap)
//    }

    private func gesture(){
        mapView.delegate = self
        let longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(longTap))
        mapView.addGestureRecognizer(longTapGesture)
   }

    
    @objc func longTap(sender: UIGestureRecognizer){
        print("long tap")
        if sender.state == .began {
            let locationInView = sender.location(in: mapView)
            let locationOnMap = mapView.convert(locationInView, toCoordinateFrom: mapView)
            addAnnotation(location: locationOnMap)
        }
    }
    
    func addAnnotation(location: CLLocationCoordinate2D){
        removeAnnotation()
        clearPoly()
        destinationLoc = location
        let annotation = MKPointAnnotation()
        annotation.coordinate = location
        annotation.title = "Get Directions here"
        annotation.subtitle = ""
        self.mapView.addAnnotation(annotation)
        print(location)
        //zoomToLatestLocation(with: destinationLoc)
        
    }
    func removeAnnotation(){
        let annotationsToRemove = mapView.annotations.filter { $0 !== mapView.userLocation }
        mapView.removeAnnotations( annotationsToRemove )
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
//    --------------------
    @IBAction func ButtonGetLocation(_ sender: Any) {
        //configureLocationServices()
        getDirections()
        //userLocationUpdate()
    }
    
    func userLocationUpdate(){
        if(CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
            CLLocationManager.authorizationStatus() == .authorizedAlways) {
            currentLoc = locationManager.location?.coordinate
            //zoomToLatestLocation(with: currentLoc)
        }
    }
    func clearPoly(){
        for poll in mapView.overlays {
            
            mapView.remove(poll)
        }
    }
    

    
    
    func getDirections(){
        if currentLoc == nil || destinationLoc == nil {
            clearPoly()
            userLocationUpdate()
            let alert : UIAlertView = UIAlertView(title: "No Destination!", message: "Long press to select a destination",       delegate: nil, cancelButtonTitle: "Okay")
            alert.show()
            print("no destination set")
        }
        else{
            userLocationUpdate()
            removeAnnotation()
            clearPoly()
            let sourcePin = customPin(pinTitle: "Your location", pinSubTitle: "", location: currentLoc)
            let destinationPin = customPin(pinTitle: "Destination Point", pinSubTitle: "", location: destinationLoc)
            self.mapView.addAnnotation(sourcePin)
            self.mapView.addAnnotation(destinationPin)
        
        let sourcePlaceMark                 = MKPlacemark(coordinate: currentLoc)
        let destinationPlaceMark            = MKPlacemark(coordinate: destinationLoc)
        
        let directionRequest                = MKDirectionsRequest()
        directionRequest.source             = MKMapItem(placemark: sourcePlaceMark)
        directionRequest.destination        = MKMapItem(placemark: destinationPlaceMark)
        directionRequest.transportType      = .automobile
        directionRequest.requestsAlternateRoutes = true
        
        let directions = MKDirections(request: directionRequest)
        directions.calculate { (response, error) in
            guard let directionResonse = response else {
                if let error = error {
                    print("we have error getting directions==\(error.localizedDescription)")
                }
                return
            }
            
            for route in directionResonse.routes {
                self.mapView.add(route.polyline, level: .aboveRoads)
                let rect = route.polyline.boundingMapRect
                self.mapView.setRegion(MKCoordinateRegionForMapRect(rect), animated: true)
            }
            
        }
        
        self.mapView.delegate = self
        
        }
        //MARK:- MapKit delegates
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor.blue
            renderer.lineWidth = 4.0
            return renderer
        }
        
    }
//    =======================
    private func configureLocationServices(){
        locationManager.delegate = self
        
        let status = CLLocationManager.authorizationStatus()
        
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        }else if status == .authorizedAlways || status == .authorizedWhenInUse {
            beginLocationUpdates(locationManager: locationManager)
        }
    }
    
    private func beginLocationUpdates(locationManager: CLLocationManager){
        mapView.showsUserLocation = true
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        
    }
    
    private func zoomToLatestLocation(with coordinate: CLLocationCoordinate2D){
        let zoomRegion = MKCoordinateRegionMakeWithDistance(coordinate, 1000, 1000)
        mapView.setRegion(zoomRegion, animated: true)
        currentLoc = coordinate
        //locationManager.stopUpdatingLocation()
        
    }

}
extension ViewController: CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("Did get latest Location")
        
        guard let latestLocation = locations.first else { return }
        
        //zoomToLatestLocation(with: latestLocation.coordinate)
        if ( currentCoordinate == nil )  {
            zoomToLatestLocation(with: latestLocation.coordinate)
        }
        
        currentCoordinate = latestLocation.coordinate
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("The status changed")
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            beginLocationUpdates(locationManager: manager)
        }
    }
    
}

extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.blue
        renderer.lineWidth = 3.0
        
        
        return renderer
        
    }
}

