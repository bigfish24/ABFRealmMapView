# ABFRealmMapView

The `ABFRealmMapView` class creates an interface object that inherits `MKMapView` and manages real-time fetching and displaying annotations for a Realm object class that contains coordinate data. In addition, by default the map view clusters annotations based on zoom level.

_**This allows for the creation of a map interface with as little as no code via Interface Builder!**_

Realm Swift support was added in version 1.3 with an identical API.

####Screenshot
The demo app uses [RealmSFRestaurantData](https://github.com/bigfish24/RealmSFRestaurantData) to search through restaurants in San Francisco.

![SF Restaurant Map View](/images/ABFRealmMapView.gif?raw=true "SF Restaurant Map View")

####Tutorial
1. Add `MKMapView` to your Xib or storyboard and replace the class with `ABFRealmMapView` (`RealmMapView` for Swift version)
![Add MKMapView to storyboard](/images/xcode-storyboard1.png?raw=true "Add MKMapView to storyboard")

2. Adjust the Realm Map View properties to specify the fetched Realm entity name and key paths for latitude, longitude, and annotation view title and subtitles.
![Add MKMapView to storyboard](/images/xcode-storyboard2.png?raw=true "Add MKMapView to storyboard")

_**3. That's It!**_

####Documentation
**Objective-C**
[Click Here](http://htmlpreview.github.io/?https://raw.githubusercontent.com/bigfish24/ABFRealmMapView/master/Documentation/ObjcDocs/index.html)

**Swift**
[Click Here](http://htmlpreview.github.io/?https://raw.githubusercontent.com/bigfish24/ABFRealmMapView/master/Documentation/SwiftDocs/index.html)

####Installation
`ABFRealmMapView` is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

**Objective-C**
```
pod 'ABFRealmMapView'
```
**Swift**
```
pod 'RealmMapView'
```

####Demo

Build and run/test the Example project in Xcode to see `ABFRealmMapView` in action. This project uses CocoaPods. If you don't have [CocoaPods](http://cocoapods.org/) installed, grab it with [sudo] gem install cocoapods.

**Objective-C**
```
git clone https://github.com/bigfish24/ABFRealmMapView.git
cd ABFRealmMapView/ABFRealmMapViewExample
pod install
open ABFRealmMapView.xcworkspace
```
#####Requirements
* iOS 7+
* Xcode 6

**Swift**
```
git clone https://github.com/bigfish24/ABFRealmMapView.git
cd ABFRealmMapView/SwiftExample
pod install
open RealmMapViewExample.xcworkspace
```
#####Requirements
* iOS 8+
* Xcode 7
