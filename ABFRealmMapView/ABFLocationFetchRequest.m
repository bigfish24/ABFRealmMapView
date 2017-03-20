//
//  ABFLocationFetchRequest.m
//  ABFRealmMapViewControllerExample
//
//  Created by Adam Fish on 6/3/15.
//  Copyright (c) 2015 Adam Fish. All rights reserved.
//

#import "ABFLocationFetchRequest.h"
#import <Realm/RLMRealm_Dynamic.h>

#pragma mark - Public Functions

NSPredicate * NSPredicateForCoordinateRegion(MKCoordinateRegion region,
                                             NSString *latitudeKeyPath,
                                             NSString *longitudeKeyPath)
{
    CLLocationDegrees centerLat = region.center.latitude;
    CLLocationDegrees centerLong = region.center.longitude;
    
    CLLocationDegrees latDelta = region.span.latitudeDelta;
    CLLocationDegrees longDelta = region.span.longitudeDelta;
    
    CLLocationDegrees halfLatDelta = latDelta/2;
    CLLocationDegrees halfLongDelta = longDelta/2;
    
    CLLocationDegrees maxLat = centerLat + halfLatDelta;
    CLLocationDegrees minLat = centerLat - halfLatDelta;
    CLLocationDegrees maxLong = centerLong + halfLongDelta;
    CLLocationDegrees minLong = centerLong - halfLongDelta;
    
    if (maxLong > 180) {
        // Create overflow region
        CLLocationDegrees overflowLongDelta = maxLong - 180;
        CLLocationDegrees halfOverflowLongDelta = overflowLongDelta/2;
        CLLocationCoordinate2D overflowCenter = CLLocationCoordinate2DMake(centerLat, -180 + halfOverflowLongDelta);
        
        MKCoordinateSpan overflowRegionSpan = MKCoordinateSpanMake(latDelta, overflowLongDelta);
        MKCoordinateRegion overflowRegion = MKCoordinateRegionMake(overflowCenter, overflowRegionSpan);
        
        // Create region without overflow
        CLLocationDegrees boundedLongDelta = 180 - minLong;
        CLLocationDegrees halfBoundedLongDelta = boundedLongDelta/2;
        CLLocationCoordinate2D boundedCenter = CLLocationCoordinate2DMake(centerLat, 180 - halfBoundedLongDelta);
        
        MKCoordinateSpan boundedRegionSpan = MKCoordinateSpanMake(latDelta, boundedLongDelta);
        MKCoordinateRegion boundedRegion = MKCoordinateRegionMake(boundedCenter, boundedRegionSpan);
        
        NSPredicate *overflowPredicate = NSPredicateForCoordinateRegion(overflowRegion, latitudeKeyPath, longitudeKeyPath);
        NSPredicate *boundedPredicate = NSPredicateForCoordinateRegion(boundedRegion, latitudeKeyPath, longitudeKeyPath);
        
        NSCompoundPredicate *compoundPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[overflowPredicate,boundedPredicate]];
        
        return compoundPredicate;
    }
    else if (minLong < -180) {
        // Create overflow region
        CLLocationDegrees overflowLongDelta = -minLong - 180;
        CLLocationDegrees halfOverflowLongDelta = overflowLongDelta/2;
        CLLocationCoordinate2D overflowCenter = CLLocationCoordinate2DMake(centerLat, 180 - halfOverflowLongDelta);
        
        MKCoordinateSpan overflowRegionSpan = MKCoordinateSpanMake(latDelta, overflowLongDelta);
        MKCoordinateRegion overflowRegion = MKCoordinateRegionMake(overflowCenter, overflowRegionSpan);
        
        // Create region without overflow
        CLLocationDegrees boundedLongDelta = maxLong + 180;
        CLLocationDegrees halfBoundedLongDelta = boundedLongDelta/2;
        CLLocationCoordinate2D boundedCenter = CLLocationCoordinate2DMake(centerLat, -180 + halfBoundedLongDelta);
        
        MKCoordinateSpan boundedRegionSpan = MKCoordinateSpanMake(latDelta, boundedLongDelta);
        MKCoordinateRegion boundedRegion = MKCoordinateRegionMake(boundedCenter, boundedRegionSpan);
        
        NSPredicate *overflowPredicate = NSPredicateForCoordinateRegion(overflowRegion, latitudeKeyPath, longitudeKeyPath);
        NSPredicate *boundedPredicate = NSPredicateForCoordinateRegion(boundedRegion, latitudeKeyPath, longitudeKeyPath);
        
        NSCompoundPredicate *compoundPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[overflowPredicate,boundedPredicate]];
        
        return compoundPredicate;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K < %f AND %K > %f AND %K < %f AND %K > %f",latitudeKeyPath,maxLat,latitudeKeyPath,minLat,longitudeKeyPath,maxLong,longitudeKeyPath,minLong];
    
    return predicate;
}

@interface ABFLocationFetchRequest ()

@property (strong, nonatomic) RLMRealm *realmForMainThread; // Improves scroll performance

@end

#pragma mark - ABFLocationFetchRequest

@implementation ABFLocationFetchRequest
@synthesize entityName = _entityName,
realmConfiguration = _realmConfiguration;

+ (instancetype)locationFetchRequestWithEntityName:(NSString *)entityName
                                           inRealm:(RLMRealm *)realm
                                   latitudeKeyPath:(NSString *)latitudeKeyPath
                                  longitudeKeyPath:(NSString *)longitudeKeyPath
                                         forRegion:(MKCoordinateRegion)region
{
    // Create the predicate from the coordinate region
    NSPredicate *predicate = NSPredicateForCoordinateRegion(region, latitudeKeyPath, longitudeKeyPath);
    
    ABFLocationFetchRequest *fetchRequest = [[self alloc] initWithEntityName:entityName
                                                                     inRealm:realm
                                                             latitudeKeyPath:latitudeKeyPath
                                                            longitudeKeyPath:longitudeKeyPath
                                                                   forRegion:region];
    
    fetchRequest.predicate = predicate;
    
    return fetchRequest;
}

#pragma mark - Public Instance

- (instancetype)initWithEntityName:(NSString *)entityName
                           inRealm:(RLMRealm *)realm
                   latitudeKeyPath:(NSString *)latitudeKeyPath
                  longitudeKeyPath:(NSString *)longitudeKeyPath
                         forRegion:(MKCoordinateRegion)region
{
    self = [super init];
    
    if (self) {
        // Returns the appropriate class name for Obj-C or Swift
        _entityName = entityName;
        _realmConfiguration = realm.configuration;
        _latitudeKeyPath = latitudeKeyPath;
        _longitudeKeyPath = longitudeKeyPath;
        _region = region;
    }
    
    return self;
}

- (id<RLMCollection>)fetchObjects
{
    RLMResults *fetchResults = [self.realm allObjects:self.entityName];
    
    // If we have a predicate use it
    if (self.predicate) {
        fetchResults = [fetchResults objectsWithPredicate:self.predicate];
    }
    
    // If we have sort descriptors then use them
    if (self.sortDescriptors.count > 0) {
        fetchResults = [fetchResults sortedResultsUsingDescriptors:self.sortDescriptors];
    }
    
    return fetchResults;
}

- (BOOL)evaluateObject:(RLMObject *)object
{
    // If we have a predicate, use it
    if (self.predicate) {
        return [self.predicate evaluateWithObject:object];
    }
    
    // Verify the class name of object match the entity name of fetch request
    NSString *className = [[object class] className];
    
    BOOL sameEntity = [className isEqualToString:self.entityName];
    
    return sameEntity;
}

#pragma mark - Getter

- (RLMRealm *)realm
{
    if ([NSThread isMainThread] &&
        !self.realmForMainThread) {
        
        self.realmForMainThread = [RLMRealm realmWithConfiguration:self.realmConfiguration
                                                             error:nil];
    }
    
    if ([NSThread isMainThread]) {
        
        return self.realmForMainThread;
    }
    
    return [RLMRealm realmWithConfiguration:self.realmConfiguration
                                      error:nil];
}

#pragma mark - Hash

- (NSUInteger)hash
{
    if (self.predicate &&
        self.sortDescriptors) {
        
        NSUInteger sortHash = 1;
        
        for (RLMSortDescriptor *sortDescriptor in self.sortDescriptors) {
            sortHash = sortHash ^ sortDescriptor.hash;
        }
        
        return self.predicate.hash ^ sortHash ^ self.entityName.hash;
    }
    else if (self.predicate &&
             self.entityName) {
        return self.predicate.hash ^ self.entityName.hash;
    }
    else {
        return [super hash];
    }
}

@end
