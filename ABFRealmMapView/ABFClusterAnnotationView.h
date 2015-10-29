//
//  ABFClusterAnnotationView.h
//  ABFRealmMapViewControllerExample
//
//  Created by Adam Fish on 6/5/15.
//  Copyright (c) 2015 Adam Fish. All rights reserved.
//

@import MapKit;

@class RLMResults, ABFLocationSafeRealmObject;

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
 *  Default is UIColor redColor
 */
@property (nonatomic, strong, nonnull) UIColor *color;

/**
 *  The label that displays the count.
 *
 *  Default font is bold system font at size 12 with white color.
 */
@property (nonatomic, readonly, nonnull) UILabel *countLabel;

/**
 *  Returns the safe location objects in the cluster annotation related to the cluster annotation view.
 *
 *  @param annotationView an instance of MKAnnotationView (returns nil if not ABFClusterAnnotationView subclass)
 *
 *  @return array of safe location objects contained in the cluster related to the annotation view
 */
+ (nullable NSArray<ABFLocationSafeRealmObject *> *)safeObjectsForClusterAnnotationView:(nullable MKAnnotationView *)annotationView;

@end
