//
//  ABFRealmMapViewController.m
//
//  Created by Adam Fish on 6/3/15.
//  Copyright (c) 2015 Adam Fish. All rights reserved.
//

#import "ABFRealmMapView.h"

#import "ABFLocationFetchRequest.h"
#import "ABFClusterAnnotationView.h"

#pragma mark - Constants

static NSString * const ABFAnnotationViewReuseId = @"ABFAnnotationViewReuseId";

#pragma mark - ABFRealmMapView

@interface ABFRealmMapView () <MKMapViewDelegate>

@property (nonatomic, strong) NSOperationQueue *mapQueue;

@property (nonatomic, weak) id<MKMapViewDelegate>externalDelegate;

@property (nonatomic, strong) RLMNotificationToken *notificationToken;

@property (nonatomic, strong) id<RLMCollection> notificationCollection;

@property (nonatomic, strong) NSRunLoop *notificationRunLoop;

@end

@implementation ABFRealmMapView
@synthesize realmConfiguration = _realmConfiguration;
@dynamic resultsLimit;

#pragma mark - Init

- (instancetype)initWithEntityName:(NSString *)entityName
                           inRealm:(RLMRealm *)realm
                   latitudeKeyPath:(NSString *)latitudeKeyPath
                  longitudeKeyPath:(NSString *)longitudeKeyPath
                      titleKeypath:(NSString *)titleKeyPath
                   subtitleKeyPath:(NSString *)subtitleKeyPath
{
    self = [self init];
    
    if (self) {
        _entityName = entityName;
        _realmConfiguration = realm.configuration;
        _latitudeKeyPath = latitudeKeyPath;
        _longitudeKeyPath = longitudeKeyPath;
        _titleKeyPath = titleKeyPath;
        _subtitleKeyPath = subtitleKeyPath;
        
        _mapQueue = [[NSOperationQueue alloc] init];
        _mapQueue.maxConcurrentOperationCount = 1;
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        [self commonInit];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [self commonInit];
    }
    
    return self;
}

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        [self commonInit];
    }
    
    return self;
}

- (void)commonInit
{
    // Set the main delegate (we will proxy if user sets delegate)
    [super setDelegate:self];
    
    _fetchResultsController = [[ABFLocationFetchedResultsController alloc] init];
    
    _clusterAnnotations = YES;
    _autoRefresh = YES;
    _zoomOnFirstRefresh = YES;
    _maxZoomLevelForClustering = 20;
    _animateAnnotations = YES;
    _canShowCallout = YES;
    
    _mapQueue = [[NSOperationQueue alloc] init];
    _mapQueue.maxConcurrentOperationCount = 1;
}

- (void)dealloc
{
    [self registerChangeNotification:NO];
}

#pragma mark - <MKMapViewDelegate>

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
    id<MKMapViewDelegate> delegate = self.externalDelegate;
    
    if ([delegate respondsToSelector:@selector(mapView:regionWillChangeAnimated:)]) {
        [delegate mapView:self regionWillChangeAnimated:animated];
    }
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    if (self.autoRefresh) {
        [self refreshMapView];
    }
    
    id<MKMapViewDelegate> delegate = self.externalDelegate;
    
    if ([delegate respondsToSelector:@selector(mapView:regionDidChangeAnimated:)]) {
        [delegate mapView:self regionDidChangeAnimated:animated];
    }
}

- (void)mapViewWillStartLoadingMap:(MKMapView *)mapView
{
    id<MKMapViewDelegate> delegate = self.externalDelegate;
    
    if ([delegate respondsToSelector:@selector(mapViewWillStartLoadingMap:)]) {
        [delegate mapViewWillStartLoadingMap:mapView];
    }
}

- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView
{
    id<MKMapViewDelegate> delegate = self.externalDelegate;
    
    if ([delegate respondsToSelector:@selector(mapViewDidFinishLoadingMap:)]) {
        [delegate mapViewDidFinishLoadingMap:mapView];
    }
}

- (void)mapViewDidFailLoadingMap:(MKMapView *)mapView withError:(NSError *)error
{
    id<MKMapViewDelegate> delegate = self.externalDelegate;
    
    if ([delegate respondsToSelector:@selector(mapViewDidFailLoadingMap:withError:)]) {
        [delegate mapViewDidFailLoadingMap:mapView withError:error];
    }
}

- (void)mapViewWillStartRenderingMap:(MKMapView *)mapView
{
    id<MKMapViewDelegate> delegate = self.externalDelegate;
    
    if ([delegate respondsToSelector:@selector(mapViewWillStartRenderingMap:)]) {
        [delegate mapViewWillStartRenderingMap:mapView];
    }
}

- (void)mapViewDidFinishRenderingMap:(MKMapView *)mapView fullyRendered:(BOOL)fullyRendered
{
    id<MKMapViewDelegate> delegate = self.externalDelegate;
    
    if ([delegate respondsToSelector:@selector(mapViewDidFinishRenderingMap:fullyRendered:)]) {
        [delegate mapViewDidFinishRenderingMap:mapView fullyRendered:fullyRendered];
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    id<MKMapViewDelegate> delegate = self.externalDelegate;
    
    if ([delegate respondsToSelector:@selector(mapView:viewForAnnotation:)]) {
        
        return [delegate mapView:mapView viewForAnnotation:annotation];
    }
    else if ([annotation isKindOfClass:[ABFAnnotation class]]) {
        
        ABFAnnotation *fetchedAnnotation = (ABFAnnotation *)annotation;
        
        ABFClusterAnnotationView *annotationView = (ABFClusterAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:ABFAnnotationViewReuseId];
        
        if (!annotationView) {
            annotationView = [[ABFClusterAnnotationView alloc] initWithAnnotation:fetchedAnnotation
                                                                  reuseIdentifier:ABFAnnotationViewReuseId];
            annotationView.canShowCallout = self.canShowCallout;
        }
        
        annotationView.count = fetchedAnnotation.safeObjects.count;
        annotationView.annotation = fetchedAnnotation;
        
        return annotationView;
    }
    
    return nil;
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views
{
    if (self.animateAnnotations) {
        for (UIView *view in views) {
            [self addAnimationToView:view];
        }
    }
    
    id<MKMapViewDelegate> delegate = self.externalDelegate;
    
    if ([delegate respondsToSelector:@selector(mapView:didAddAnnotationViews:)]) {
        [delegate mapView:mapView didAddAnnotationViews:views];
    }
}

#if TARGET_OS_IPHONE
- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    id<MKMapViewDelegate> delegate = self.externalDelegate;
    
    if ([delegate respondsToSelector:@selector(mapView:annotationView:calloutAccessoryControlTapped:)]) {
        [delegate mapView:mapView annotationView:view calloutAccessoryControlTapped:control];
    }
}
#endif

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    id<MKMapViewDelegate> delegate = self.externalDelegate;
    
    if ([delegate respondsToSelector:@selector(mapView:didSelectAnnotationView:)]) {
        [delegate mapView:mapView didSelectAnnotationView:view];
    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
    id<MKMapViewDelegate> delegate = self.externalDelegate;
    
    if ([delegate respondsToSelector:@selector(mapView:didDeselectAnnotationView:)]) {
        [delegate mapView:mapView didDeselectAnnotationView:view];
    }
}

- (void)mapViewWillStartLocatingUser:(MKMapView *)mapView
{
    id<MKMapViewDelegate> delegate = self.externalDelegate;
    
    if ([delegate respondsToSelector:@selector(mapViewWillStartLocatingUser:)]) {
        [delegate mapViewWillStartLocatingUser:mapView];
    }
}

- (void)mapViewDidStopLocatingUser:(MKMapView *)mapView
{
    id<MKMapViewDelegate> delegate = self.externalDelegate;
    
    if ([delegate respondsToSelector:@selector(mapViewDidStopLocatingUser:)]) {
        [delegate mapViewDidStopLocatingUser:mapView];
    }
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    id<MKMapViewDelegate> delegate = self.externalDelegate;
    
    if ([delegate respondsToSelector:@selector(mapView:didUpdateUserLocation:)]) {
        [delegate mapView:mapView didUpdateUserLocation:userLocation];
    }
}

- (void)mapView:(MKMapView *)mapView didFailToLocateUserWithError:(NSError *)error
{
    id<MKMapViewDelegate> delegate = self.externalDelegate;
    
    if ([delegate respondsToSelector:@selector(mapView:didFailToLocateUserWithError:)]) {
        [delegate mapView:mapView didFailToLocateUserWithError:error];
    }
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view didChangeDragState:(MKAnnotationViewDragState)newState
   fromOldState:(MKAnnotationViewDragState)oldState
{
    id<MKMapViewDelegate> delegate = self.externalDelegate;
    
    if ([delegate respondsToSelector:@selector(mapView:annotationView:didChangeDragState:fromOldState:)]) {
        [delegate mapView:mapView annotationView:view didChangeDragState:newState fromOldState:oldState];
    }
}

#if TARGET_OS_IPHONE
- (void)mapView:(MKMapView *)mapView didChangeUserTrackingMode:(MKUserTrackingMode)mode animated:(BOOL)animated
{
    id<MKMapViewDelegate> delegate = self.externalDelegate;
    
    if ([delegate respondsToSelector:@selector(mapView:didChangeUserTrackingMode:animated:)]) {
        [delegate mapView:mapView didChangeUserTrackingMode:mode animated:animated];
    }
}
#endif

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id <MKOverlay>)overlay
{
    id<MKMapViewDelegate> delegate = self.externalDelegate;
    
    if ([delegate respondsToSelector:@selector(mapView:rendererForOverlay:)]) {
        return [delegate mapView:mapView rendererForOverlay:overlay];
    }
    
    return nil;
}

- (void)mapView:(MKMapView *)mapView didAddOverlayRenderers:(NSArray *)renderers
{
    id<MKMapViewDelegate> delegate = self.externalDelegate;
    
    if ([delegate respondsToSelector:@selector(mapView:didAddOverlayRenderers:)]) {
        [delegate mapView:mapView didAddOverlayRenderers:renderers];
    }
}

#if TARGET_OS_IPHONE
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay
{
    id<MKMapViewDelegate> delegate = self.externalDelegate;
    
    if ([delegate respondsToSelector:@selector(mapView:viewForOverlay:)]) {
        return [delegate mapView:mapView viewForOverlay:overlay];
    }
    
    return nil;
}

- (void)mapView:(MKMapView *)mapView didAddOverlayViews:(NSArray *)overlayViews
{
    id<MKMapViewDelegate> delegate = self.externalDelegate;
    
    if ([delegate respondsToSelector:@selector(mapView:didAddOverlayViews:)]) {
        [delegate mapView:mapView didAddOverlayViews:overlayViews];
    }
}
#pragma clang diagnostic pop
#endif

#pragma mark - Setters

- (void)setDelegate:(id<MKMapViewDelegate>)delegate
{
    if (delegate == self) {
        [super setDelegate:delegate];
    }
    else {
        _externalDelegate = delegate;
    }
}

- (void)setRealmConfiguration:(RLMRealmConfiguration *)realmConfiguration
{
    @synchronized(self) {
        _realmConfiguration = realmConfiguration;
    }
}

- (void)setEntityName:(NSString *)entityName
{
    @synchronized(self) {
        _entityName = entityName;
    }
}

- (void)setLatitudeKeyPath:(NSString *)latitudeKeyPath
{
    @synchronized(self) {
        _latitudeKeyPath = latitudeKeyPath;
    }
}

- (void)setLongitudeKeyPath:(NSString *)longitudeKeyPath
{
    @synchronized(self) {
        _longitudeKeyPath = longitudeKeyPath;
    }
}

- (void)setTitleKeyPath:(NSString *)titleKeyPath
{
    @synchronized(self) {
        _titleKeyPath = titleKeyPath;
    }
}

- (void)setSubtitleKeyPath:(NSString *)subtitleKeyPath
{
    @synchronized(self) {
        _subtitleKeyPath = subtitleKeyPath;
    }
}

- (void)setResultsLimit:(ABFResultsLimit)resultsLimit
{
    self.fetchResultsController.resultsLimit = resultsLimit;
}

#pragma mark - Getters

- (RLMRealm *)realm
{
    if (self.realmConfiguration) {
        return [RLMRealm realmWithConfiguration:self.realmConfiguration error:nil];
    }
    
    return [RLMRealm defaultRealm];
}

- (RLMRealmConfiguration *)realmConfiguration
{
    if (_realmConfiguration) {
        return _realmConfiguration;
    }
    
    return [RLMRealmConfiguration defaultConfiguration];
}

- (ABFResultsLimit)resultsLimit
{
    return self.fetchResultsController.resultsLimit;
}

#pragma mark - Public Instance

- (void)refreshMapView
{
    @synchronized(self) {
        [self.mapQueue cancelAllOperations];
        
        MKCoordinateRegion currentRegion = self.region;
        
        ABFLocationFetchRequest *fetchRequest =
        [ABFLocationFetchRequest locationFetchRequestWithEntityName:self.entityName
                                                            inRealm:self.realm
                                                    latitudeKeyPath:self.latitudeKeyPath
                                                   longitudeKeyPath:self.longitudeKeyPath
                                                          forRegion:currentRegion];
        
        if (self.basePredicate) {
            NSCompoundPredicate *compPred =
            [NSCompoundPredicate andPredicateWithSubpredicates:@[fetchRequest.predicate,self.basePredicate]];
            
            fetchRequest.predicate = compPred;
        }
        
        [self.fetchResultsController updateLocationFetchRequest:fetchRequest
                                                   titleKeyPath:self.titleKeyPath
                                                subtitleKeyPath:self.subtitleKeyPath];
        
        typeof(self) __weak weakSelf = self;
        
        NSBlockOperation *refreshOperation = [[NSBlockOperation alloc] init];
        
        NSBlockOperation __weak *weakOp = refreshOperation;
        
        MKMapRect visibleMapRect = self.visibleMapRect;
        
        ABFZoomLevel currentZoomLevel = ABFZoomLevelForVisibleMapRect(visibleMapRect);
        
        if (self.clusterAnnotations &&
            currentZoomLevel <= self.maxZoomLevelForClustering) {
            
            MKZoomScale zoomScale = MKZoomScaleForMapView(self);
            
            [refreshOperation addExecutionBlock:^{
                if (![weakOp isCancelled]) {
                    [weakSelf.fetchResultsController performClusteringFetchForVisibleMapRect:visibleMapRect
                                                                                   zoomScale:zoomScale];
                    
                    [weakSelf addAnnotationsToMapView:weakSelf.fetchResultsController.annotations];
                    
                    [weakSelf registerChangeNotification:weakSelf.autoRefresh];
                }
            }];
        }
        else {
            [refreshOperation addExecutionBlock:^{
                if (![weakOp isCancelled]) {
                    [weakSelf.fetchResultsController performFetch];
                    
                    [weakSelf addAnnotationsToMapView:weakSelf.fetchResultsController.annotations];
                    
                    [weakSelf registerChangeNotification:weakSelf.autoRefresh];
                }
            }];
        }
        
        [self.mapQueue addOperation:refreshOperation];
    }
}

#pragma mark - Private Instance

- (void)addAnnotationsToMapView:(NSSet *)annotations
{
    typeof(self) __weak weakSelf = self;
    
    NSMutableSet *currentAnnotations = nil;
    
    /**
     *  Must wrap calls to self.annotations in try block
     *
     *  Internally the map view creates the array on demand and will
     *  throw an exception for a nil object occasionally!
     */
    @try {
        if (self.annotations) {
            currentAnnotations = [NSMutableSet setWithArray:self.annotations];
        }
    }
    @catch (NSException *exception) {
        // Ignoring exceptions thrown!
    }
        
    NSSet *newAnnotations = annotations;
    
    // Find current annotations we are keeping
    NSMutableSet *toKeep = [NSMutableSet setWithSet:currentAnnotations];
    
    [toKeep intersectSet:newAnnotations];
    
    // Find the new annotations we need to add form toKeep
    NSMutableSet *toAdd = [NSMutableSet setWithSet:newAnnotations];
    
    [toAdd minusSet:toKeep];
    
    // Find the current annotations to remove from the new ones
    NSMutableSet *toRemove = [NSMutableSet setWithSet:currentAnnotations];
    
    [toRemove minusSet:newAnnotations];
    
    NSArray *safeObjects = self.fetchResultsController.safeObjects;
    
    // Trigger display on map view
    [[NSOperationQueue mainQueue] addOperationWithBlock:^() {
        
        // Trigger zoom on first run if necessary
        if (weakSelf.zoomOnFirstRefresh &&
            safeObjects.count > 0) {
            weakSelf.zoomOnFirstRefresh = NO;
            
            MKCoordinateRegion region = [weakSelf coordinateRegionForSafeObjects:safeObjects];
            
            [weakSelf setRegion:region animated:YES];
        }
        else {
            [weakSelf addAnnotations:[toAdd allObjects]];
            [weakSelf removeAnnotations:[toRemove allObjects]];
        }
    }];
}

- (void)addAnimationToView:(UIView *)view
{
    view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.05, 0.05);
    
    [UIView animateWithDuration:0.6
                          delay:0
         usingSpringWithDamping:0.5
          initialSpringVelocity:1
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^(){
                         view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0, 1.0);
                     }
                     completion:nil];
}

- (MKCoordinateRegion)coordinateRegionForSafeObjects:(NSArray *)safeObjects
{
    MKMapRect rect = MKMapRectNull;
    
    for (ABFLocationSafeRealmObject *safeObject in safeObjects) {
        MKMapPoint point = MKMapPointForCoordinate(safeObject.coordinate);
        
        rect = MKMapRectUnion(rect, MKMapRectMake(point.x, point.y, 0, 0));
    }
    
    MKCoordinateRegion region = MKCoordinateRegionForMapRect(rect);
    
    region = [self regionThatFits:region];
    
    region.span.latitudeDelta *= 1.3;
    region.span.longitudeDelta *= 1.3;
    
    return region;
}

- (void)registerChangeNotification:(BOOL)registerNotifications
{    
    if (registerNotifications) {
        typeof(self) __weak weakSelf = self;
        
        // Setup run loop
        if (!self.notificationRunLoop) {
            dispatch_semaphore_t sem = dispatch_semaphore_create(0);
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                CFRunLoopPerformBlock(CFRunLoopGetCurrent(), kCFRunLoopDefaultMode, ^{
                    weakSelf.notificationRunLoop = [NSRunLoop currentRunLoop];
                    
                    dispatch_semaphore_signal(sem);
                });
                
                CFRunLoopRun();
            });
            
            dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        }
        
        CFRunLoopPerformBlock(self.notificationRunLoop.getCFRunLoop, kCFRunLoopDefaultMode, ^{
            if (weakSelf.notificationToken) {
                [weakSelf.notificationToken stop];
                weakSelf.notificationToken = nil;
                weakSelf.notificationCollection = nil;
            }
            
            weakSelf.notificationCollection = weakSelf.fetchResultsController.fetchRequest.fetchObjects;
            weakSelf.notificationToken = [weakSelf.notificationCollection
                                          addNotificationBlock:^(id<RLMCollection>  _Nullable collection,
                                                                 RLMCollectionChange * _Nullable change,
                                                                 NSError * _Nullable error) {
                                              if (!error &&
                                                  change) {
                                                  [weakSelf refreshMapView];
                                              }
                                          }];
        });
        
        CFRunLoopWakeUp(self.notificationRunLoop.getCFRunLoop);
    }
    else if (self.notificationRunLoop) {
        CFRunLoopStop(self.notificationRunLoop.getCFRunLoop);
        self.notificationRunLoop = nil;
    }
}

@end
