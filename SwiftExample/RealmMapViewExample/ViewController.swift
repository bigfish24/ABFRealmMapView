//
//  ViewController.swift
//  RealmMapViewExample
//
//  Created by Adam Fish on 9/28/15.
//  Copyright © 2015 Adam Fish. All rights reserved.
//

import UIKit
import MapKit
import RealmSwift
import RealmSwiftSFRestaurantData

class ViewController: UIViewController {

    @IBOutlet var mapView: RealmMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /**
        *   Set the Realm path to be the Restaurant Realm path
        */
        
        var config = Realm.Configuration.defaultConfiguration
        config.path = ABFRestaurantScoresPath()
        
        self.mapView.realmConfiguration = config
        
        self.mapView.delegate = self
        
        /**
        *  Set the cluster title format string
        *  $OBJECTSCOUNT variable track cluster count
        */
        self.mapView.fetchedResultsController.clusterTitleFormatString = "$OBJECTSCOUNT restaurants in this area"
        
        /**
        *  Add filtering to the result set in addition to the bounding box filter
        */
        self.mapView.basePredicate = NSPredicate(format: "name BEGINSWITH 'A'");
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.mapView.refreshMapView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController: MKMapViewDelegate {
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if let safeObjects = ABFClusterAnnotationView.safeObjectsForClusterAnnotationView(view) {
            
            if let firstObjectName = safeObjects.first?.toObject(ABFRestaurantObject).name {
                print("First Object: \(firstObjectName)")
            }
            
            print("Count: \(safeObjects.count)")
        }
    }
}

