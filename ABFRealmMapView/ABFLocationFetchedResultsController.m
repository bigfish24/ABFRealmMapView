//
//  ABFLocationFetchedResultsController.m
//  ABFRealmMapViewControllerExample
//
//  Created by Adam Fish on 6/4/15.
//  Copyright (c) 2015 Adam Fish. All rights reserved.
//

#import "ABFLocationFetchedResultsController.h"

#pragma mark - Constants

const double ABFNoDistance = DBL_MAX;

#pragma mark - ABFLocationSafeRealmObject

@implementation ABFLocationSafeRealmObject

#pragma mark - Public Class

+ (instancetype)safeLocationObjectFromObject:(RLMObject *)object
                                  coordinate:(CLLocationCoordinate2D)coordinate
                                       title:(NSString *)title
                                    subtitle:(NSString *)subtitle
{
    ABFLocationSafeRealmObject *safeObject = [self safeObjectFromObject:object];
    safeObject->_coordinate = coordinate;
    safeObject->_title = title ? title : @"";
    safeObject->_subtitle = subtitle ? subtitle : @"";
    
    return safeObject;
}

#pragma mark - Getters

- (CLLocationDistance)currentDistance
{
    if (_currentDistance) {
        return _currentDistance;
    }
    
    return ABFNoDistance;
}

@end

#pragma mark - Private Functions

static const NSUInteger ABFMaxPrecision = 22;
static const NSUInteger ABFBitsPerBase32Char = 5;
static const char ABFBase32Chars[] = "0123456789bcdefghjkmnpqrstuvwxyz";

static char ABFValueToBase32Character(NSUInteger value)
{
    if (value > 31) {
        @throw [NSException exceptionWithName:@"ABFException" reason:@"Not a valid base32 value" userInfo:nil];
    }
    
    return ABFBase32Chars[value];
}

static NSString *ABFGeoHashWithCoordinate(CLLocationCoordinate2D coordinate,
                                          NSUInteger precision)
{
    if (precision > ABFMaxPrecision) {
        
        NSInteger precisionLimit = ABFMaxPrecision + 1;
        
        NSString *exceptionString = [NSString stringWithFormat:@"Precision must be less than %td",precisionLimit];
        
        @throw [NSException exceptionWithName:@"ABFException" reason:exceptionString userInfo:nil];
    }
    
    double longitudeRange[] = {-180, 180};
    double latitudeRange[] = {-90, 90};
    
    char buffer[precision+1];
    buffer[precision] = 0;
    
    for (NSUInteger i = 0; i < precision; i++) {
        NSUInteger hashVal = 0;
        for (NSUInteger j = 0; j < ABFBitsPerBase32Char; j++) {
            BOOL even = ((i*ABFBitsPerBase32Char)+j) % 2 == 0;
            double val = even ? coordinate.longitude : coordinate.latitude;
            double* range = even ? longitudeRange : latitudeRange;
            double mid = (range[0] + range[1])/2;
            if (val > mid) {
                hashVal = (hashVal << 1) + 1;
                range[0] = mid;
            } else {
                hashVal = (hashVal << 1) + 0;
                range[1] = mid;
            }
        }
        buffer[i] = ABFValueToBase32Character(hashVal);
    }
    NSString *geoHashValue = [NSString stringWithUTF8String:buffer];
    
    return geoHashValue;
}


#pragma mark - ABFAnnotation

@interface ABFAnnotation ()

@property (nonatomic, strong) NSMutableArray *internalSafeObjects;

@property (nonatomic, strong) NSString *geoHash;

- (void)addSafeObject:(ABFLocationSafeRealmObject *)safeObject;

@end

@implementation ABFAnnotation

#pragma mark - Public Class

+ (instancetype)annotationWithType:(ABFAnnotationType)type
{
    ABFAnnotation *annotation = [[self alloc] init];
    annotation->_type = type;
    
    return annotation;
}

#pragma mark - Public Instance

- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate
{
    [self willChangeValueForKey:@"coordinate"];
    _coordinate = newCoordinate;
    [self didChangeValueForKey:@"coordinate"];
}

- (void)setTitle:(NSString *)title
{
    [self willChangeValueForKey:@"title"];
    _title = title;
    [self didChangeValueForKey:@"title"];
}

- (void)setSubtitle:(NSString *)subtitle
{
    [self willChangeValueForKey:@"subtitle"];
    _subtitle = subtitle;
    [self didChangeValueForKey:@"subtitle"];
}

#pragma mark - Private Instance

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _internalSafeObjects = [NSMutableArray array];
    }
    
    return self;
}

- (void)addSafeObject:(ABFLocationSafeRealmObject *)safeObject
{
    @synchronized(self) {
        [self.internalSafeObjects addObject:safeObject];
    }
}

#pragma mark - Getters

- (NSArray *)safeObjects
{
    return self.internalSafeObjects.copy;
}

- (NSString *)geoHash
{
    if (!_geoHash) {
        _geoHash = ABFGeoHashWithCoordinate(self.coordinate, ABFMaxPrecision);
    }
    
    return _geoHash;
}

#pragma mark - Equality

- (NSUInteger)hash
{
    return [self.geoHash hash];
}

- (BOOL)isEqual:(id)object
{
    if (object == self) {
        return YES;
    }
    else if (!object ||
             ![object isKindOfClass:[ABFAnnotation class]]) {
        
        return NO;
    }

    ABFAnnotation *annotation = (ABFAnnotation *)object;
    
    NSString *objectGeoHash = ABFGeoHashWithCoordinate(annotation.coordinate, ABFMaxPrecision);
    
    if ([self.geoHash isEqualToString:objectGeoHash]) {
        
        return self.type == annotation.type;
    }
    
    return NO;
}

@end

#pragma mark - ABFLocationSortDescriptor

@implementation ABFLocationSortDescriptor

#pragma mark - Public Class

+ (instancetype)sortDescriptorWithCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate
                                      nearestFirst:(BOOL)nearestFirst
{
    ABFLocationSortDescriptor *sortDescriptor = [[self alloc] init];
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:centerCoordinate.latitude
                                                      longitude:centerCoordinate.longitude];
    sortDescriptor->_location = location;
    sortDescriptor->_nearestFirst = nearestFirst;
    
    return sortDescriptor;
}

#pragma mark - Public Instance

- (instancetype)reverseSort
{
    CLLocationCoordinate2D centerCoordinate = self.location.coordinate;
    
    BOOL nearestFirst = self.nearestFirst;
    
    ABFLocationSortDescriptor *reverseSort = [ABFLocationSortDescriptor sortDescriptorWithCenterCoordinate:centerCoordinate
                                                                                              nearestFirst:!nearestFirst];
    
    return reverseSort;
}

@end

#pragma mark - Public Functions

MKZoomScale MKZoomScaleForMapView(MKMapView *mapView)
{
    MKZoomScale currentZoomScale = mapView.bounds.size.width / mapView.visibleMapRect.size.width;
    
    return currentZoomScale;
}

ABFZoomLevel ABFZoomLevelForVisibleMapRect(MKMapRect visibleMapRect)
{
    // MapKit mercator projection has 2^20 256 square pixel tiles:
    // double maxTiles = MKMapSizeWorld.width/256.0;
    // double log2Tiles = log2(maxTiles);
    
    double visibleTiles = visibleMapRect.size.width/256.0;
    double log2VisibleTiles = log2(visibleTiles);
    
    // Convert to ABFZoomLevel
    NSUInteger zoomLevel = -floor(log2VisibleTiles) + 20;
    
    return zoomLevel;
}

#pragma mark - Private Functions

ABFClusterSizeForZoomLevel ABFDefaultClusterSizeForZoomLevel()
{
    return ^NSUInteger(ABFZoomLevel zoomLevel) {
        switch (zoomLevel) {
            case 0:
            case 1:
            case 2:
            case 3:
            case 4:
            case 5:
            case 6:
            case 7:
            case 8:
            case 9:
            case 10:
            case 11:
            case 12:
            case 13:
            case 14:
            case 15:
                return 64;
            case 16:
            case 17:
            case 18:
                return 32;
            case 19:
                return 16;
            case 20:
            default:
                return 88;
        }
    };
}

#pragma mark - ABFLocationFetchedResultsController

@interface ABFLocationFetchedResultsController ()

@end

@implementation ABFLocationFetchedResultsController

#pragma mark - Public Instance

- (instancetype)initWithLocationFetchRequest:(ABFLocationFetchRequest *)fetchRequest
                                titleKeyPath:(NSString *)titleKeyPath
                             subtitleKeyPath:(NSString *)subtitleKeyPath
{
    self = [self init];
    
    if (self) {
        _fetchRequest = fetchRequest;
        _titleKeyPath = titleKeyPath;
        _subtitleKeyPath = subtitleKeyPath;
    }
    
    return self;
}

- (id)init
{
    self = [super init];
    
    if (self) {
        _clusterTitleFormatString = @"$OBJECTSCOUNT objects in this area";
        _safeObjects = [[NSArray alloc] init];
        _annotations = [[NSSet alloc] init];
        _clusterSizeBlock = ABFDefaultClusterSizeForZoomLevel();
        _resultsLimit = -1;
    }
    
    return self;
}

- (BOOL)performFetch
{
    @synchronized(self) {
        // Get the safe objects
        _safeObjects = [self safeObjectsFromFetchResults:self.fetchRequest.fetchObjects];
        
        _annotations = [self uniqueAnnotationsFromSafeObjects:_safeObjects];
        
        return YES;
    }
}

- (BOOL)performClusteringFetchForVisibleMapRect:(MKMapRect)visibleMapRect
                                      zoomScale:(MKZoomScale)zoomScale
{
    @synchronized(self) {
        ABFZoomLevel zoomLevel = ABFZoomLevelForVisibleMapRect(visibleMapRect);
        
        // Cluster size in pixels
        NSUInteger clusterSize = self.clusterSizeBlock(zoomLevel);
        
        // Create scale factor based on zoom scale and cluster size
        double scaleFactor = zoomScale/(double)clusterSize;
        
        NSMutableDictionary *clusterGrid = [NSMutableDictionary dictionary];
        
        // Get the safe objects
        _safeObjects = [self safeObjectsFromFetchResults:self.fetchRequest.fetchObjects];
        
        // Insert safe objects into cluster array
        for (ABFLocationSafeRealmObject *safeObject in _safeObjects) {
            
            MKMapPoint safeObjectPoint = MKMapPointForCoordinate(safeObject.coordinate);
            
            // Get x/y values adjusted for scale factor
            NSUInteger x = floor(safeObjectPoint.x * scaleFactor);
            NSUInteger y = floor(safeObjectPoint.y * scaleFactor);
            
            NSMutableDictionary *yDict = [clusterGrid objectForKey:@(x)];
            
            // Create the dictionary for y values
            if (!yDict) {
                
                yDict = [NSMutableDictionary dictionary];
                
                [clusterGrid setObject:yDict
                                forKey:@(x)];
            }
            
            NSMutableArray *cluster = [yDict objectForKey:@(y)];
            
            if (!cluster) {
                
                cluster = [NSMutableArray array];
                
                [yDict setObject:cluster
                          forKey:@(y)];
            }
            
            [cluster addObject:safeObject];
        }
        
        // Create annotations from cluster array
        _annotations = [self clusterAnnotationsFromClusterGrid:clusterGrid.copy];
        
        return YES;
    }
}

- (void)updateLocationFetchRequest:(ABFLocationFetchRequest *)fetchRequest
                      titleKeyPath:(NSString *)titleKeyPath
                   subtitleKeyPath:(NSString *)subtitleKeyPath
{
    @synchronized(self) {
        _fetchRequest = fetchRequest;
        _titleKeyPath = titleKeyPath;
        _subtitleKeyPath = subtitleKeyPath;
    }
}

#pragma mark - Setters

- (void)setClusterTitleFormatString:(NSString *)clusterTitleFormatString
{
    if (![clusterTitleFormatString containsString:@"$OBJECTSCOUNT"]) {
        
        @throw [NSException exceptionWithName:@"ABFException"
                                       reason:@"Cluster title string must contain '$OBJECTSCOUNT' variable"
                                     userInfo:nil];
    }
    
    _clusterTitleFormatString = clusterTitleFormatString;
}

#pragma mark - Private Instance

- (NSArray *)safeObjectsFromFetchResults:(id<RLMCollection>)fetchResults
{
    NSMutableArray *safeObjects = [NSMutableArray arrayWithCapacity:fetchResults.count];
    
    NSUInteger count = 0;
    
    for (RLMObject *object in fetchResults) {
        
        if (count == self.resultsLimit) {
            break;
        }
        
        CLLocationCoordinate2D coordinate = [self coordinateForObject:object];
        
        NSString *title = [self titleForObject:object];
        
        NSString *subtitle = [self subtitleForObject:object];
        
        ABFLocationSafeRealmObject *safeObject = [ABFLocationSafeRealmObject safeLocationObjectFromObject:object
                                                                                               coordinate:coordinate
                                                                                                    title:title
                                                                                                 subtitle:subtitle];
        
        if (self.sortDescriptor) {
            
            CLLocation *safeObjectLocation = [[CLLocation alloc] initWithLatitude:safeObject.coordinate.latitude
                                                                        longitude:safeObject.coordinate.longitude];
            
            CLLocationDistance distance = [safeObjectLocation distanceFromLocation:self.sortDescriptor.location];
            
            safeObject.currentDistance = distance;
        }
        
        [safeObjects addObject:safeObject];
        
        count ++;
    }
    
    if (self.sortDescriptor) {
        
        BOOL nearestFirst = self.sortDescriptor.nearestFirst;
        
        // Sort the objects
        [safeObjects sortUsingComparator:^NSComparisonResult(ABFLocationSafeRealmObject *obj1,
                                                             ABFLocationSafeRealmObject *obj2) {
            
            if (!nearestFirst) {
                return [@(obj2.currentDistance) compare:@(obj1.currentDistance)];
            }
            
            return [@(obj1.currentDistance) compare:@(obj2.currentDistance)];
        }];
    }
    
    return safeObjects.copy;
}

- (NSSet *)uniqueAnnotationsFromSafeObjects:(NSArray *)safeObjects
{
    NSMutableSet *annotations = [NSMutableSet setWithCapacity:safeObjects.count];
    
    for (ABFLocationSafeRealmObject *safeObject in safeObjects) {
        
        ABFAnnotation *annotation = [ABFAnnotation annotationWithType:ABFAnnotationTypeUnique];
        
        [annotation setTitle:safeObject.title];
        [annotation setSubtitle:safeObject.subtitle];
        [annotation setCoordinate:safeObject.coordinate];
        
        [annotation addSafeObject:safeObject];
        
        [annotations addObject:annotation];
    }
    
    return annotations.copy;
}

- (NSSet *)clusterAnnotationsFromClusterGrid:(NSDictionary *)clusterGrid
{
    NSMutableSet *annotations = [NSMutableSet set];
    
    for (NSNumber *xKey in clusterGrid) {
        
        NSDictionary *yDict = [clusterGrid objectForKey:xKey];
        
        for (NSNumber *yKey in yDict) {
            
            NSArray *cluster = [yDict objectForKey:yKey];
            
            ABFAnnotation *annotation = [ABFAnnotation annotationWithType:ABFAnnotationTypeCluster];
            
            NSUInteger clusterCount = cluster.count;
            
            NSString *title = @"";
            
            if (clusterCount > 1) {
                NSString *countString = [NSString stringWithFormat:@"%lu",(unsigned long)clusterCount];
                
                title = [self.clusterTitleFormatString stringByReplacingOccurrencesOfString:@"$OBJECTSCOUNT" withString:countString];
            }
            else {
                ABFLocationSafeRealmObject *safeObject = cluster.firstObject;
                
                title = safeObject.title;
                [annotation setSubtitle:safeObject.subtitle];
            }
            
            [annotation setTitle:title];
            
            double totalLat = 0;
            double totalLong = 0;
            
            for (ABFLocationSafeRealmObject *safeObject in cluster) {
                totalLat += safeObject.coordinate.latitude;
                totalLong += safeObject.coordinate.longitude;
                
                [annotation addSafeObject:safeObject];
            }
            
            // Get the average lat/long for the cluster coordinate
            CLLocationDegrees annotationLat = totalLat/clusterCount;
            CLLocationDegrees annotationLong = totalLong/clusterCount;
            
            CLLocationCoordinate2D annotationCoordinate = CLLocationCoordinate2DMake(annotationLat, annotationLong);
            
            [annotation setCoordinate:annotationCoordinate];
            
            [annotations addObject:annotation];
        }
    }
    
    return annotations.copy;
}

- (CLLocationCoordinate2D)coordinateForObject:(RLMObject *)object
{
    CLLocationDegrees latitude = 0;
    CLLocationDegrees longitude = 0;
    
    @try {
        latitude = ((NSNumber *)[object valueForKeyPath:self.fetchRequest.latitudeKeyPath]).doubleValue;
    }
    @catch (NSException *exception) {
        @throw [NSException exceptionWithName:@"ABFException"
                                       reason:@"Latitude key path for fetch request entity name not valid"
                                     userInfo:nil];
    }
    
    @try {
        longitude = ((NSNumber *)[object valueForKeyPath:self.fetchRequest.longitudeKeyPath]).doubleValue;
    }
    @catch (NSException *exception) {
        @throw [NSException exceptionWithName:@"ABFException"
                                       reason:@"Longitude key path for fetch request entity name not valid"
                                     userInfo:nil];
    }
    
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
    
    return coordinate;
}

- (NSString *)titleForObject:(RLMObject *)object
{
    NSString *title = @"";
    
    if (self.titleKeyPath) {
        @try {
            title = (NSString *)[object valueForKeyPath:self.titleKeyPath];
        }
        @catch (NSException *exception) {
            @throw [NSException exceptionWithName:@"ABFException"
                                           reason:@"Title key path for fetch request entity name not valid"
                                         userInfo:nil];
        }
    }
    
    return title;
}

- (NSString *)subtitleForObject:(RLMObject *)object
{
    NSString *subtitle = @"";
    
    if (self.subtitleKeyPath) {
        @try {
            subtitle = (NSString *)[object valueForKeyPath:self.subtitleKeyPath];
        }
        @catch (NSException *exception) {
            @throw [NSException exceptionWithName:@"ABFException"
                                           reason:@"Subtitle key path for fetch request entity name not valid"
                                         userInfo:nil];
        }
    }
    
    return subtitle;
}

@end
