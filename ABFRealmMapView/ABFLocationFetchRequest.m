//
//  ABFLocationFetchRequest.m
//  ABFRealmMapViewControllerExample
//
//  Created by Adam Fish on 6/3/15.
//  Copyright (c) 2015 Adam Fish. All rights reserved.
//

#import "ABFLocationFetchRequest.h"

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

#pragma mark - ABFLocationFetchRequest

@implementation ABFLocationFetchRequest

+ (instancetype)locationFetchRequestWithEntityName:(NSString *)entityName
                                           inRealm:(RLMRealm *)realm
                                   latitudeKeyPath:(NSString *)latitudeKeyPath
                                  longitudeKeyPath:(NSString *)longitudeKeyPath
                                         forRegion:(MKCoordinateRegion)region
{
    // Create the predicate from the coordinate region
    NSPredicate *predicate = NSPredicateForCoordinateRegion(region, latitudeKeyPath, longitudeKeyPath);
    
    ABFLocationFetchRequest *fetchRequest = [[self alloc] initWithEntityName:entityName inRealm:realm];
    
    fetchRequest.predicate = predicate;
    fetchRequest->_region = region;
    fetchRequest->_latitudeKeyPath = latitudeKeyPath;
    fetchRequest->_longitudeKeyPath = longitudeKeyPath;
    
    return fetchRequest;
}

@end
