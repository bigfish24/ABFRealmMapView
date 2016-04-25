//
//  ABFRealmMapView.h
//
//  Created by Adam Fish on 6/3/15.
//  Copyright (c) 2015 Adam Fish. All rights reserved.
//

#import "ABFLocationFetchedResultsController.h"

@import MapKit;

#if __has_include(<RealmMapView/RealmMapView-BridgingHeader.h>)
@import Realm;
#else
#import <Realm/Realm.h>
#endif

/**
 *  The class creates a map interface to display annotations representing Realm object locations.
 *
 *  ABFRealmMapView inherits MKMapView and is editable from Interface Builder. Simply drag a MKMapView onto your Xib or Storyboard and replace the class with ABFRealmMapView.
 *
 *  The class will create a ABFLocationFetchedResultsController internally to manage retrieving Realm objects based on the current visible map rectangle. The Realm objects must contain a key path to latitude and longitude values.
 *
 *  The class will display annotations and uses the supplied title and subtitle key paths to create the annotation values. By default the class will cluster the annotations based on the zoom level.
 */
@interface ABFRealmMapView : MKMapView

/**
 *  The Realm in which the specified entity exists
 *
 *  Default returns Realm at default path.
 *
 *  @see realmPath
 *  @see initWithEntityName:inRealm:latitudeKeyPath:longitudeKeyPath:titleKeypath:subtitleKeyPath:
 */
@property (nonatomic, readonly, nonnull) RLMRealm *realm;

/**
 *  The configuration for the Realm in which the entity resides
 */
@property (nonatomic, strong, nullable) RLMRealmConfiguration *realmConfiguration;

/**
 *  The internal controller that fetches the Realm objects
 *
 *  @see ABFLocationFetchedResultsController clusterTitleFormatString to localize the subtitle string
 */
@property (nonatomic, readonly, nonnull) ABFLocationFetchedResultsController *fetchResultsController;

/**
 *  The Realm object's name being fetched for the map view
 */
@property (nonatomic, strong, nullable) IBInspectable NSString *entityName;

/**
 *  The key path on fetched Realm objects for the latitude value
 */
@property (nonatomic, strong, nullable) IBInspectable NSString *latitudeKeyPath;

/**
 *  The key path on fetched Realm objects for the longitude value
 */
@property (nonatomic, strong, nullable) IBInspectable NSString *longitudeKeyPath;

/**
 *  The key path on fetched Realm objects for the title of the annotation view
 */
@property (nonatomic, strong, nullable) IBInspectable NSString *titleKeyPath;

/**
 *  The key path on fetched Realm objects for the subtitle of the annotation view
 */
@property (nonatomic, strong, nullable) IBInspectable NSString *subtitleKeyPath;

/**
 *  Designates if the map view will cluster the annotations
 *
 *  Default is YES
 */
@property (nonatomic, assign) IBInspectable BOOL clusterAnnotations;

/**
 *  Designates if the map view automatically refreshes when the map moves
 *
 *  Also will respond to change notifications in Realm to autorefresh
 *
 *  Default is YES
 */
@property (nonatomic, assign) IBInspectable BOOL autoRefresh;

/**
 *  Designates if the map view will zoom to a region that contains all points
 *  on the first refresh of the map annotations (presumably on viewWillAppear)
 *
 *  Default is YES
 */
@property (nonatomic, assign) IBInspectable BOOL zoomOnFirstRefresh;

/**
 *  If enabled, annotation views will be animated when added to the map.
 *
 *  Default is YES
 */
@property (nonatomic, assign) IBInspectable BOOL animateAnnotations;

/**
 *  If YES, a standard callout bubble will be shown when the annotation is selected.
 *  The annotation must have a title for the callout to be shown.
 *
 *  Default is YES
 */
@property (nonatomic, assign) IBInspectable BOOL canShowCallout;

/**
 *  Max zoom level of the map view to perform clustering on.
 *
 *  ABFZoomLevel is inherited from MapKit's Google days:
 *  0 is the entire 2D Earth
 *  20 is max zoom
 *
 *  Default is 20, which means clustering will occur at every zoom level if clusterAnnotations is YES
 */
@property (nonatomic, assign) ABFZoomLevel maxZoomLevelForClustering;

/**
 *  The limit on how many results from Realm will be added to the map.
 *
 *  This applies whether or not clustering is enabled.
 *
 *  Default is -1, or unlimited results.
 */
@property (nonatomic, assign) ABFResultsLimit resultsLimit;

/**
 *  Use this property to filter items found by the map. This predicate will be included, via AND,
 *  along with the generated predicate for the location bounding box.
 */
@property (nonatomic, strong, nullable) NSPredicate *basePredicate;

/**
 *  Creates a map view that automatically handles fetching Realm objects and displaying annotations
 *
 *  @param entityName       the class name for the Realm objects to fetch
 *  @param realm            the Realm in which the fetched Realm objects exists
 *  @param latitudeKeyPath  the key path on fetched Realm objects for the latitude value
 *  @param longitudeKeyPath the key path on fetched Realm objects for the longitude value
 *  @param titleKeyPath     the key path on fetched Realm objects for the title of the annotation view
 *  @param subtitleKeyPath  the key path on fetched Realm objects for the subtitle of the annotation view
 *
 *  @return instance of ABFRealmMapView
 */
- (nonnull instancetype)initWithEntityName:(nonnull NSString *)entityName
                                   inRealm:(nonnull RLMRealm *)realm
                           latitudeKeyPath:(nonnull NSString *)latitudeKeyPath
                          longitudeKeyPath:(nonnull NSString *)longitudeKeyPath
                              titleKeypath:(nonnull NSString *)titleKeyPath
                           subtitleKeyPath:(nonnull NSString *)subtitleKeyPath;

/**
 *  Performs a fresh fetch for Realm objects based on the current visible map rect
 *
 *  @see autoRefresh
 */
- (void)refreshMapView;

@end
