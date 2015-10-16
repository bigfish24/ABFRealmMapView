//
//  ViewController.m
//  ABFRealmMapViewExample
//
//  Created by Adam Fish on 6/10/15.
//  Copyright (c) 2015 Adam Fish. All rights reserved.
//

#import "ViewController.h"

#import "ABFRealmMapView.h"
#import "ABFClusterAnnotationView.h"

#import <RealmSFRestaurantData/SFRestaurantScores.h>

@import MapKit;

@interface ViewController () <CLLocationManagerDelegate, MKMapViewDelegate>

@property (nonatomic, strong) IBOutlet ABFRealmMapView *mapView;

@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    /**
     *  Set the Realm path to be the Restaurant Realm path
     */
    
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    config.path = ABFRestaurantScoresPath();
    
    self.mapView.realmConfiguration = config;
    
    self.mapView.delegate = self;
    
    /**
     *  Set the cluster title format string
     *  $OBJECTSCOUNT variable track cluster count
     */
    self.mapView.fetchResultsController.clusterTitleFormatString = @"$OBJECTSCOUNT restaurants in this area";
    
    /**
     *  Handle user location auth
     */
    [self setupLocationManager];
    
    [self requestLocationAuthorization];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.mapView refreshMapView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - <CLLocationManagerDelegate>

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        self.mapView.showsUserLocation = YES;
    }
}

#pragma mar - MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    NSArray<ABFLocationSafeRealmObject *> *safeObjects = [ABFClusterAnnotationView safeObjectsForClusterAnnotationView:view];
    
    ABFRestaurantObject *firstObject = safeObjects.firstObject.RLMObject;
    
    NSLog(@"First Object: %@",firstObject.name);
    NSLog(@"Cluster Count: %lu",safeObjects.count);
}

#pragma mark - Private

- (void)setupLocationManager
{
    if (!self.locationManager) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
    }
}

- (void)requestLocationAuthorization
{
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
        self.mapView.showsUserLocation = YES;
    }
}

@end
