//
//  RealmMapView.swift
//  RealmMapViewExample
//
//  Created by Adam Fish on 9/29/15.
//  Copyright © 2015 Adam Fish. All rights reserved.
//

import MapKit
import RealmSwift

/**
The RealmMapView class creates an interface object that inherits MKMapView and manages fetching and displaying annotations for a Realm Swift object class that contains coordinate data.
*/
public class RealmMapView: MKMapView {
    // MARK: Properties
    
    /// The configuration for the Realm in which the entity resides
    ///
    /// Default is [RLMRealmConfiguration defaultConfiguration]
    public var realmConfiguration: Realm.Configuration {
        set {
            self.internalConfiguration = newValue
        }
        get {
            if let configuration = self.internalConfiguration {
                return configuration
            }
            
            return Realm.Configuration.defaultConfiguration
        }
    }
    
    /// The Realm in which the given entity resides in
    public var realm: Realm {
        return try! Realm(configuration: self.realmConfiguration)
    }
    
    /// The internal controller that fetches the Realm objects
    public var fetchedResultsController: ABFLocationFetchedResultsController = {
        let controller = ABFLocationFetchedResultsController()
        
        return controller
    }()
    
    /// The Realm object's name being fetched for the map view
    @IBInspectable public var entityName: String?
    
    /// The key path on fetched Realm objects for the latitude value
    @IBInspectable public var latitudeKeyPath: String?
    
    /// The key path on fetched Realm objects for the longitude value
    @IBInspectable public var longitudeKeyPath: String?
    
    /// The key path on fetched Realm objects for the title of the annotation view
    ///
    /// If nil, then no title will be shown
    @IBInspectable public var titleKeyPath: String?
    
    /// The key path on fetched Realm objects for the subtitle of the annotation view
    ///
    /// If nil, then no subtitle
    @IBInspectable public var subtitleKeyPath: String?
    
    /// Designates if the map view will cluster the annotations
    @IBInspectable public var clusterAnnotations = true
    
    /// Designates if the map view automatically refreshes when the map moves
    @IBInspectable public var autoRefresh = true
    
    /// Designates if the map view will zoom to a region that contains all points
    /// on the first refresh of the map annotations (presumably on viewWillAppear)
    @IBInspectable public var zoomOnFirstRefresh = true
    
    /// If enabled, annotation views will be animated when added to the map.
    ///
    /// Default is YES
    @IBInspectable public var animateAnnotations = true
    
    /// If YES, a standard callout bubble will be shown when the annotation is selected.
    /// The annotation must have a title for the callout to be shown.
    @IBInspectable public var canShowCallout = true
    
    /// Max zoom level of the map view to perform clustering on.
    ///
    /// ABFZoomLevel is inherited from MapKit's Google days:
    /// 0 is the entire 2D Earth
    /// 20 is max zoom
    ///
    /// Default is 20, which means clustering will occur at every zoom level if clusterAnnotations is YES
    public var maxZoomLevelForClustering: ABFZoomLevel = 20
    
    /// The limit on how many results from Realm will be added to the map.
    ///
    /// This applies whether or not clustering is enabled.
    ///
    /// Default is -1, or unlimited results.
    public var resultsLimit: ABFResultsLimit {
        set {
            self.fetchedResultsController.resultsLimit = newValue
        }
        get {
            return self.fetchedResultsController.resultsLimit
        }
    }
    
    /// Use this property to filter items found by the map. This predicate will be included, via AND,
    /// along with the generated predicate for the location bounding box.
    public var basePredicate: NSPredicate?
    
    // MARK: Functions
    
    /// Performs a fresh fetch for Realm objects based on the current visible map rect
    public func refreshMapView() {
        objc_sync_enter(self)
        
        self.mapQueue.cancelAllOperations()
        
        let currentRegion = self.region
        
        let rlmConfig = self.toRLMConfiguration(self.realmConfiguration)
        
        if let rlmRealm = try? RLMRealm(configuration: rlmConfig) {
            
            let fetchRequest = ABFLocationFetchRequest(entityName: self.entityName!, inRealm: rlmRealm, latitudeKeyPath: self.latitudeKeyPath!, longitudeKeyPath: self.longitudeKeyPath!, forRegion: currentRegion)
            
            if let basePred = self.basePredicate, let pred = fetchRequest.predicate {
                let compPred = NSCompoundPredicate(andPredicateWithSubpredicates: [pred, basePred])
                fetchRequest.predicate = compPred
            }
            
            self.fetchedResultsController.updateLocationFetchRequest(fetchRequest, titleKeyPath: self.titleKeyPath, subtitleKeyPath: self.subtitleKeyPath)
            
            var refreshOperation: NSBlockOperation?
            
            let visibleMapRect = self.visibleMapRect
            
            let currentZoomLevel = ABFZoomLevelForVisibleMapRect(visibleMapRect)
            
            if self.clusterAnnotations && currentZoomLevel <= self.maxZoomLevelForClustering {
                
                let zoomScale = MKZoomScaleForMapView(self)
                
                refreshOperation = NSBlockOperation(block: { [weak self] () -> Void in
                    self?.fetchedResultsController.performClusteringFetchForVisibleMapRect(visibleMapRect, zoomScale: zoomScale)
                    
                    if let annotations = self?.fetchedResultsController.annotations {
                        self?.addAnnotationsToMapView(annotations)
                    }
                })
            }
            else {
                refreshOperation = NSBlockOperation(block: { [weak self] () -> Void in
                    self?.fetchedResultsController.performFetch()
                    
                    if let annotations = self?.fetchedResultsController.annotations {
                        self?.addAnnotationsToMapView(annotations)
                    }
                })
            }
            
            self.mapQueue.addOperation(refreshOperation!)
        }
        
        objc_sync_exit(self)
    }
    
    // MARK: Initialization
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        super.delegate = self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        super.delegate = self
    }
    
    // MARK: Setters
    override weak public var delegate: MKMapViewDelegate? {
        get {
            return externalDelegate
        }
        set(newDelegate) {
            self.externalDelegate = newDelegate
        }
    }
    
    // MARK: Private
    private var internalConfiguration: Realm.Configuration?
    
    private let ABFAnnotationViewReuseId = "ABFAnnotationViewReuseId"
    
    private let mapQueue: NSOperationQueue = {
        let queue = NSOperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        return queue
    }()
    
    weak private var externalDelegate: MKMapViewDelegate?
    
    private func addAnnotationsToMapView(annotations: Set<ABFAnnotation>) {
        let currentAnnotations = NSMutableSet(array: self.annotations)
        
        let newAnnotations = annotations
        
        let toKeep = NSMutableSet(set: currentAnnotations)
        
        toKeep.intersectSet(newAnnotations as Set<NSObject>)
        
        let toAdd = NSMutableSet(set: newAnnotations)
        
        toAdd.minusSet(toKeep as Set<NSObject>)
        
        let toRemove = NSMutableSet(set: currentAnnotations)
        
        toRemove.minusSet(newAnnotations)
        
        let safeObjects = self.fetchedResultsController.safeObjects
        
        NSOperationQueue.mainQueue().addOperationWithBlock({ [weak self] () -> Void in
            
            if let strongSelf = self {
                
                if strongSelf.zoomOnFirstRefresh && safeObjects.count > 0 {
                    
                    strongSelf.zoomOnFirstRefresh = false
                    
                    let region = strongSelf.coordinateRegion(safeObjects)
                    
                    strongSelf.setRegion(region, animated: true)
                }
                else {
                    if let addAnnotations = toAdd.allObjects as? [MKAnnotation] {
                        
                        if let removeAnnotations = toRemove.allObjects as? [MKAnnotation] {
                            
                            strongSelf.addAnnotations(addAnnotations)
                            strongSelf.removeAnnotations(removeAnnotations)
                        }
                    }
                }
            }
        })
    }
    
    private func addAnimation(view: UIView) {
        view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.05, 0.05)
        
        UIView.animateWithDuration(0.6, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            
                view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0, 1.0)
            
            }, completion: nil)
    }
    
    private func coordinateRegion(safeObjects: [ABFLocationSafeRealmObject]) -> MKCoordinateRegion {
        var rect = MKMapRectNull
        
        for safeObject in safeObjects {
            let point = MKMapPointForCoordinate(safeObject.coordinate)
            
            rect = MKMapRectUnion(rect, MKMapRectMake(point.x, point.y, 0, 0))
        }
        
        var region = MKCoordinateRegionForMapRect(rect)
        
        region = self.regionThatFits(region)
        
        region.span.latitudeDelta *= 1.3
        region.span.longitudeDelta *= 1.3
        
        return region
    }
    
    private func toRLMConfiguration(configuration: Realm.Configuration) -> RLMRealmConfiguration {
        let rlmConfiguration = RLMRealmConfiguration()
        
        if (configuration.path != nil) {
            rlmConfiguration.path = configuration.path
        }
        
        if (configuration.inMemoryIdentifier != nil) {
            rlmConfiguration.inMemoryIdentifier = configuration.inMemoryIdentifier
        }
        
        rlmConfiguration.encryptionKey = configuration.encryptionKey
        rlmConfiguration.readOnly = configuration.readOnly
        rlmConfiguration.schemaVersion = configuration.schemaVersion
        return rlmConfiguration
    }
}

/**
Delegate proxy that allows the controller to trigger auto refresh and then rebroadcast to main delegate.

:nodoc:
*/
extension RealmMapView: MKMapViewDelegate {
    public func mapView(mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        self.externalDelegate?.mapView?(mapView, regionWillChangeAnimated: animated)
    }
    
    public func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        if self.autoRefresh {
            self.refreshMapView()
        }
        
        self.externalDelegate?.mapView?(mapView, regionDidChangeAnimated: animated)
    }
    
    public func mapViewWillStartLoadingMap(mapView: MKMapView) {
        self.externalDelegate?.mapViewWillStartLoadingMap?(mapView)
    }
    
    public func mapViewDidFinishLoadingMap(mapView: MKMapView) {
        self.externalDelegate?.mapViewDidFinishLoadingMap?(mapView)
    }
    
    public func mapViewDidFailLoadingMap(mapView: MKMapView, withError error: NSError) {
        self.externalDelegate?.mapViewDidFailLoadingMap?(mapView, withError: error)
    }
    
    public func mapViewWillStartRenderingMap(mapView: MKMapView) {
        self.externalDelegate?.mapViewWillStartRenderingMap?(mapView)
    }
    
    public func mapViewDidFinishRenderingMap(mapView: MKMapView, fullyRendered: Bool) {
        self.externalDelegate?.mapViewDidFinishRenderingMap?(mapView, fullyRendered: fullyRendered)
    }
    
    public func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        if let delegate = self.externalDelegate, let method = delegate.mapView?(mapView, viewForAnnotation: annotation) {
            return method
        }
        else if let fetchedAnnotation = annotation as? ABFAnnotation {
            
            var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(ABFAnnotationViewReuseId) as! ABFClusterAnnotationView?
            
            if annotationView == nil {
                annotationView = ABFClusterAnnotationView(annotation: fetchedAnnotation, reuseIdentifier: ABFAnnotationViewReuseId)
                
                annotationView!.canShowCallout = self.canShowCallout
            }
            
            annotationView!.count = UInt(fetchedAnnotation.safeObjects.count)
            annotationView!.annotation = fetchedAnnotation
            
            return annotationView!
        }
        
        return nil
    }
    
    public func mapView(mapView: MKMapView, didAddAnnotationViews views: [MKAnnotationView]) {
        
        if self.animateAnnotations {
            for view in views {
                self.addAnimation(view)
            }
        }
        
        self.externalDelegate?.mapView?(mapView, didAddAnnotationViews: views)
    }
    
    public func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        self.externalDelegate?.mapView?(mapView, annotationView: view, calloutAccessoryControlTapped: control)
    }
    
    public func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        self.externalDelegate?.mapView?(mapView, didSelectAnnotationView: view)
    }
    
    public func mapView(mapView: MKMapView, didDeselectAnnotationView view: MKAnnotationView) {
        self.externalDelegate?.mapView?(mapView, didDeselectAnnotationView: view)
    }
    
    public func mapViewWillStartLocatingUser(mapView: MKMapView) {
        self.externalDelegate?.mapViewDidStopLocatingUser?(mapView)
    }
    
    public func mapViewDidStopLocatingUser(mapView: MKMapView) {
        self.externalDelegate?.mapViewDidStopLocatingUser?(mapView)
    }
    
    public func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        self.externalDelegate?.mapView?(mapView, didUpdateUserLocation: userLocation)
    }
    
    public func mapView(mapView: MKMapView, didFailToLocateUserWithError error: NSError) {
        self.externalDelegate?.mapView?(mapView, didFailToLocateUserWithError: error)
    }
    
    public func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        self.externalDelegate?.mapView?(mapView, annotationView: view, didChangeDragState: newState, fromOldState: oldState)
    }
    
    public func mapView(mapView: MKMapView, didChangeUserTrackingMode mode: MKUserTrackingMode, animated: Bool) {
        self.externalDelegate?.mapView?(mapView, didChangeUserTrackingMode: mode, animated: animated)
    }
    
    public func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        return (self.externalDelegate?.mapView?(mapView, rendererForOverlay: overlay))!
    }
    
    public func mapView(mapView: MKMapView, didAddOverlayRenderers renderers: [MKOverlayRenderer]) {
        self.externalDelegate?.mapView?(mapView, didAddOverlayRenderers: renderers)
    }
}

/// Extension to ABFLocationSafeRealmObject to convert back to original Object type
extension ABFLocationSafeRealmObject {
    public func toObject<T>(type: T.Type) -> T {
        return unsafeBitCast(self.RLMObject(), T.self)
    }
}
