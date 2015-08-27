//
//  ViewController.m
//  ABFRealmMapViewExample
//
//  Created by Adam Fish on 6/10/15.
//  Copyright (c) 2015 Adam Fish. All rights reserved.
//

#import "ViewController.h"

#import "ABFRealmMapView.h"

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
    
    [self moveMapToRealmHeadquarters];
    
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

- (void)moveMapToRealmHeadquarters
{
    CLLocationCoordinate2D realmHeadquarters = CLLocationCoordinate2DMake(37.7799247, -122.3919823);
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(realmHeadquarters, 1000, 1000);
    
    [self.mapView setRegion:region animated:NO];
}

@end
