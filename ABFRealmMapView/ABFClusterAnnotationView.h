//
//  ABFClusterAnnotationView.h
//  ABFRealmMapViewControllerExample
//
//  Created by Adam Fish on 6/5/15.
//  Copyright (c) 2015 Adam Fish. All rights reserved.
//

#import <MapKit/MapKit.h>

/**
 *  Creates a circular view to represent a map annotation cluster
 *
 *  Derived from: https://github.com/thoughtbot/TBAnnotationClustering/blob/master/TBAnnotationClustering/TBClusterAnnotationView.h
 */
@interface ABFClusterAnnotationView : MKAnnotationView

/**
 *  The count of the cluster
 */
@property (nonatomic, assign) NSUInteger count;

/**
 *  The color of the cluster annotation
 *
 *  Default is [UIColor redColor]
 */
@property (nonatomic, strong) UIColor *color;

@end
