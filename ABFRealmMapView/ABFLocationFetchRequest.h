//
//  ABFLocationFetchRequest.h
//  ABFRealmMapViewControllerExample
//
//  Created by Adam Fish on 6/3/15.
//  Copyright (c) 2015 Adam Fish. All rights reserved.
//

@import MapKit;

#if __has_include(<RealmMapView/RealmMapView-BridgingHeader.h>)
@import RBQFetchedResultsController;
#elif __has_include("RBQFetchRequest.h")
#import "RBQFetchRequest.h"
#else
#import <RBQFetchedResultsController/RBQFetchRequest.h>
#endif

/**
 *  Converts a MKCoordinate region to an NSPredicate
 *
 *  If the region span cross the -180/180 longitude meridian, the return value is an NSCompoundPredicate containing two NSPredicates that comprise of the region before the meridian and another region of the overflow beyond it.
 *
 *  @param region           MKCoordinate region representing the location fetch limits
 *  @param latitudeKeyPath  the latitude key path for the value to test the latitude limits against
 *  @param longitudeKeyPath the longitude key path for the value to test the longitude limits against
 *
 *  @return instance of NSPredicate (can be NSCompoundPredicate, see description for more info)
 */
NS_ASSUME_NONNULL_BEGIN
extern NSPredicate * NSPredicateForCoordinateRegion(MKCoordinateRegion region,
                                                    NSString *latitudeKeyPath,
                                                    NSString *longitudeKeyPath);
NS_ASSUME_NONNULL_END

/**
 *  Location specific subclass of RBQFetchRequest that allows for location fetching on Realm objects that contain latitude and longitude values.
 *
 *  Location fetch is defined by a MKCoordinate region and is converted into a predicate for Realm querying.
 */
@interface ABFLocationFetchRequest : RBQFetchRequest

/**
 *  Latitude key path on the Realm object for entityName
 */
@property (nonatomic, readonly, nonnull) NSString *latitudeKeyPath;

/**
 *  Longitude key path on the Realm object for entityName
 */
@property (nonatomic, readonly, nonnull) NSString *longitudeKeyPath;

/**
 *  Region that defines the fetch boundaries
 */
@property (nonatomic, readonly) MKCoordinateRegion region;

/**
 *  Creates a ABFLocationFetchRequest instance that defines a fetch based off of a coordinate region boundary.
 *
 *  @param entityName       the Realm object name (class name)
 *  @param realm            the RLMRealm in which the entity(s) exist
 *  @param latitudeKeyPath  the latitude key path for the value to test the latitude limits against
 *  @param longitudeKeyPath the longitude key path for the value to test the longitude limits against
 *  @param region           the region that represents the search boundary
 *
 *  @return an instance of ABFLocationFetchRequest that contains the NSPredicate for the fetch
 */
+ (nonnull instancetype)locationFetchRequestWithEntityName:(nonnull NSString *)entityName
                                                   inRealm:(nonnull RLMRealm *)realm
                                           latitudeKeyPath:(nonnull NSString *)latitudeKeyPath
                                          longitudeKeyPath:(nonnull NSString *)longitudeKeyPath
                                                 forRegion:(MKCoordinateRegion)region;
@end
