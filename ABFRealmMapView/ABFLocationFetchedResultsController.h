//
//  ABFLocationFetchedResultsController.h
//  ABFRealmMapViewControllerExample
//
//  Created by Adam Fish on 6/4/15.
//  Copyright (c) 2015 Adam Fish. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RBQFetchedResultsController/RBQSafeRealmObject.h>

#import "ABFLocationFetchRequest.h"

@import MapKit;

/**
 *  Value of ABFLocationSafeRealmObject currentDistance when there is no distance.
 */
extern const double ABFNoDistance;

/**
 *  Subclass of RBQSafeRealmObject to hold a representation of Realm object that works across threads.
 *
 *  Adds support to hold location information.
 */
@interface ABFLocationSafeRealmObject : RBQSafeRealmObject

/**
 *  The coordinate location of the Realm object
 */
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

/**
 *  The title of the object
 */
@property (nonatomic, readonly) NSString *title;

/**
 *  The subtitle of the object
 */
@property (nonatomic, readonly) NSString *subtitle;

/**
 *  Transient property used to perform distance sorting.
 *
 *  If sorting was not applied, the current distance will be ABFNoDistance
 */
@property (nonatomic, assign) CLLocationDistance currentDistance;

/**
 *  Creates an instance of ABFLocationSafeRealmObject.
 *
 *  @param object       the original Realm object
 *  @param coordinate   the coordinate location for the Realm object
 *  @param title        the title of the object (for use with map annotations)
 *  @param subtitle     the subtitle of the object (for use with map annotations)
 *
 *  @return instance of ABFLoationSafeRealmObject
 */
+ (instancetype)safeLocationObjectFromObject:(RLMObject *)object
                                  coordinate:(CLLocationCoordinate2D)coordinate
                                       title:(NSString *)title
                                    subtitle:(NSString *)subtitle;

@end

/**
 *  Defines the types of ABFAnnotation
 */
typedef NS_ENUM(NSUInteger, ABFAnnotationType){
    /**
     *  The ABFAnnotation represents one unique Realm object
     */
    ABFAnnotationTypeUnique,
    /**
     *  The ABFAnnotation represents a cluster of Realm objects
     */
    ABFAnnotationTypeCluster,
};

/**
 *  Class conforms to MKAnnotation and serves as the source of information for a map annotation.
 *
 *  The class has two types (ABFAnnotationType) defining whether the annotation represents
 *  a unique Realm object or a cluster of Realm objects
 */
@interface ABFAnnotation : NSObject <MKAnnotation>

/**
 *  The location for the annotation
 *
 *  Return kCLLocationCoordinate2DInvalid if no safe objects in the annotation.
 */
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

/**
 *  The title of the annotation. If the annotation is a cluster then this title is computed,
 *  for example '6 objects in this area'.
 *
 *  @see ABFLocationFetchedResultsController clusterTitleFormatString
 */
@property (nonatomic, readonly, copy) NSString *title;

/**
 *  The subtitle for the annotation. If the annotation is a cluster then this will be nil.
 */
@property (nonatomic, readonly, copy) NSString *subtitle;

/**
 *  The type of annotation.
 *
 *  @see ABFAnnotationType
 */
@property (nonatomic, readonly) ABFAnnotationType type;

/**
 *  An array of ABFLocationSafeRealmObject(s).
 *
 *  If type is ABFAnnotationTypeUnique, then this array will contain only 1 safe object.
 */
@property (nonatomic, readonly) NSArray *safeObjects;

/**
 *  Creates an instance of ABFAnnotation for a given type
 *
 *  @param type the type of annotation
 *
 *  @return instance of ABFAnnotationType
 */
+ (instancetype)annotationWithType:(ABFAnnotationType)type;

/**
 *  KVO compliant setter for coordinate
 *
 *  @param newCoordinate new coordinate value for the annotation
 */
- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate;

/**
 *  KVO compliant setter for title
 *
 *  @param title new title for the annotation
 */
- (void)setTitle:(NSString *)title;

/**
 *  KVO compliant setter for subtitle
 *
 *  @param subtitle new subtitle for the annotation
 */
- (void)setSubtitle:(NSString *)subtitle;

@end

/**
 *  An ABFLocationSortDescriptor stores a center coordinate and sort order for use with
 *  ABFLocationFetchedResultsController to perform a location fetch and return
 *  objects sorted by distance.
 */
@interface ABFLocationSortDescriptor : NSObject

/**
 *  The center location to calculate relative distances from.
 */
@property (nonatomic, readonly) CLLocation *location;

/**
 *  The sort order. Objects will be sorted by distance to center coordinate.
 */
@property (nonatomic, readonly) BOOL nearestFirst;

/**
 *  Creates instance of ABFLocationSortDescriptor with a center coordinate and sort order.
 *
 *  @param centerCoordinate the center coordinate to calculate relative distances from.
 *  @param nearestFirst     the sort order; objects will be sorted by distance to center coordinate.
 *
 *  @return an instance of ABFLocationSortDescriptor
 */
+ (instancetype)sortDescriptorWithCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate nearestFirst:(BOOL)nearestFirst;

/**
 *  Returns a new instance of ABFLocationSortDescriptor that has a reversed sort order.
 *
 *  @return an instance of ABFLocationSortDescriptor
 */
- (instancetype)reverseSort;

@end

/**
 *  Zoom level of the map view. 
 *
 *  Inherited from MapKit's Google days:
 *  0 is the entire 2D Earth
 *  20 is max zoom
 */
typedef NSUInteger ABFZoomLevel;

/**
 *  Calculates the MKZoomScale for a given map view state
 *
 *  @param mapView instance of MKMapView
 *
 *  @return MKZoomScale that represents the zoom level at the current map view state
 */
extern MKZoomScale MKZoomScaleForMapView(MKMapView *mapView);

/**
 *  Calculates the ABFZoomLevel based on a given visble map rect
 *
 *  @see ABFZoomLevel
 *
 *  @param visibleMapRect the current visible map rect of a MKMapView
 *
 *  @return 0-20 ABFZoomLevel
 */
extern ABFZoomLevel ABFZoomLevelForVisibleMapRect(MKMapRect visibleMapRect);

/**
 *  This class acts as a controller to perform location fetches against a Realm object 
 *  that contains latitude and longitude values (the object must also contain a primary key).
 *
 *  The controller performs the fetch and creates ABFAnnotations. If a sort descriptor is 
 *  specified the resulting objects will be sorted by distance.
 *
 *  Finally, the controller can also cluster the objects based off the visible map rect size 
 *  and zoom level. If a clustering fetch is performed, the resulting ABFAnnotations will
 *  be type ABFAnnotationTypeCluster and contain all of the objects in the cluster.
 */
@interface ABFLocationFetchedResultsController : NSObject

/**
 *  The current location fetch request
 *
 *  @see ABFLocationFetchRequest
 */
@property (nonatomic, readonly) ABFLocationFetchRequest *fetchRequest;

/**
 *  Specify a sort descriptor to sort the objects by distance.
 *
 *  @see ABFLocationSortDescriptor
 */
@property (nonatomic, strong) ABFLocationSortDescriptor *sortDescriptor;

/**
 *  An array of ABFLocationSafeRealmObject(s) representing the objects found in the fetch.
 *
 *  If sort descriptor was specified then the objects will be sorted by distance.
 */
@property (nonatomic, readonly) NSArray *safeObjects;

/**
 *  Collection of ABFAnnotations representing the objects in the fetch.
 *
 *  If performClusteringFetchForVisibleMapRect:atZoomScale: was called then the 
 *  annotations will be clusters of objects
 */
@property (nonatomic, readonly) NSSet *annotations;

/**
 *  The title key path on the Realm objects that correspond to the annotation title
 */
@property (nonatomic, readonly) NSString *titleKeyPath;

/**
 *  The subtitle key path on the Realm objects that correspond to the annotation subtitle
 */
@property (nonatomic, readonly) NSString *subtitleKeyPath;

/**
 *  If clustering fetch is performed, the title of the annotations with multiple objects will be computed.
 *
 *  @warning The string must contain `$OBJECTSCOUNT` which will be replaced with the number of objects in the cluster
 *
 *  Default is `@"$OBJECTSCOUNT objects in this area"`
 *
 *  @see ABFAnnotation title
 */
@property (nonatomic, strong) NSString *clusterTitleFormatString;

/**
 *  Creates an instance of ABFLocationFetchedResultsController. 
 *
 *  Controller performs a fetch against a Realm object that contains latitude and 
 *  longitude properties.
 *
 *  @see ABFLocationFetchRequest
 *
 *  @param fetchRequest    the current fetch request for the controller to perform
 *  @param titleKeyPath    the title key path on the Realm objects that correspond to the annotation title
 *  @param subtitleKeyPath the subtitle key path on the Realm objects that correspond to the annotation subtitle
 *
 *  @return instance of ABFLocationFetchedResultsController
 */
- (instancetype)initWithLocationFetchRequest:(ABFLocationFetchRequest *)fetchRequest
                                titleKeyPath:(NSString *)titleKeyPath
                             subtitleKeyPath:(NSString *)subtitleKeyPath;

/**
 *  Performs a fetch using the current fetch request.
 *
 *  If a sort descriptor is specified then the resulting objects will be sorted by distance.
 *
 *  @return BOOL value indicating if the fetch was successful
 */
- (BOOL)performFetch;

/**
 *  Performs a fetch and then clusters the results based off the current map view state.
 *
 *  If a sort descriptor is specified then the resulting objects will be sorted by distance.
 *
 *  @param visibleMapRect   the current visible map rect for the map view
 *  @param zoomScale        the map view's zoom scale (use MKZoomScaleForMapView)
 *
 *  @return BOOL value indicating if the fetch was successful
 */
- (BOOL)performClusteringFetchForVisibleMapRect:(MKMapRect)visibleMapRect
                                      zoomScale:(MKZoomScale)zoomScale;

/**
 *  Updates the current fetch request to a new instance.
 *
 *  @warning Must call performFetch or performClusteringFetchForVisibleMapRect:atZoomScale: after to trigger the fetch.
 *
 *  @param fetchRequest    a new instance of ABFLocationFetchRequest (typical use case is to update the fetch request after the user moves the map)
 *  @param titleKeyPath    the title key path on the Realm objects that correspond to the annotation title
 *  @param subtitleKeyPath the subtitle key path on the Realm objects that correspond to the annotation subtitle
 */
- (void)updateLocationFetchRequest:(ABFLocationFetchRequest *)fetchRequest
                      titleKeyPath:(NSString *)titleKeyPath
                   subtitleKeyPath:(NSString *)subtitleKeyPath;

@end
