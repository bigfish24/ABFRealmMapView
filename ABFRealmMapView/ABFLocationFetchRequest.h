//
//  ABFLocationFetchRequest.h
//  ABFRealmMapViewControllerExample
//
//  Created by Adam Fish on 6/3/15.
//  Copyright (c) 2015 Adam Fish. All rights reserved.
//

@import MapKit;

#if __has_include(<RealmMapView/RealmMapView.h>)
@import Realm;
#else
#import <Realm/Realm.h>
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
@interface ABFLocationFetchRequest : NSObject

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
 *  RLMObject class name for the fetch request
 */
@property (nonatomic, readonly, nonnull) NSString *entityName;

/**
 *  The Realm in which the entity for the fetch request is persisted.
 */
@property (nonatomic, readonly, nonnull) RLMRealm *realm;

/**
 *  The configuration object used to create an instance of RLMRealm for the fetch request
 */
@property (nonatomic, readonly, nonnull) RLMRealmConfiguration *realmConfiguration;

/**
 *  Predicate supported by Realm
 *
 *  http://realm.io/docs/cocoa/0.89.2/#querying-with-predicates
 */
@property (nonatomic, strong, nullable) NSPredicate *predicate;

/**
 *  Array of RLMSortDescriptors
 *
 *  http://realm.io/docs/cocoa/0.89.2/#ordering-results
 */
@property(nonatomic, strong, nullable) NSArray<RLMSortDescriptor *> *sortDescriptors;

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

/**
 *  Retrieve all the RLMObjects for this fetch request in its realm.
 *
 *  @return RLMResults or RLMArray for all the objects in the fetch request (not thread-safe).
 */
- (nonnull id<RLMCollection>)fetchObjects;

/**
 *  Should this object be in our fetch results?
 *
 *  Intended to be used by the RBQFetchedResultsController to evaluate incremental changes. For
 *  simple fetch requests this just evaluates the NSPredicate, but subclasses may have a more
 *  complicated implementaiton.
 *
 *  @param object Realm object of appropriate type
 *
 *  @return YES if performing fetch would include this object
 */
- (BOOL)evaluateObject:(nonnull RLMObject *)object;

/**
 *  Create RBQFetchRequest in RLMRealm instance with an entity name
 *
 *  @param entityName       the Realm object name (class name)
 *  @param realm            the RLMRealm in which the entity(s) exist
 *  @param latitudeKeyPath  the latitude key path for the value to test the latitude limits against
 *  @param longitudeKeyPath the longitude key path for the value to test the longitude limits against
 *  @param region           the region that represents the search boundary
 *
 *  @return an instance of ABFLocationFetchRequest that contains the NSPredicate for the fetch
 */
- (nonnull instancetype)initWithEntityName:(nonnull NSString *)entityName
                                   inRealm:(nonnull RLMRealm *)realm
                           latitudeKeyPath:(nonnull NSString *)latitudeKeyPath
                          longitudeKeyPath:(nonnull NSString *)longitudeKeyPath
                                 forRegion:(MKCoordinateRegion)region;
@end
