# ABFRealmMapView

The `ABFRealmMapView` class creates an interface object that inherits `MKMapView` and manages real-time fetching and displaying annotations for a [Realm](http://www.realm.io) object class that contains coordinate data. In addition, by default the map view clusters annotations based on zoom level.

_**This allows for the creation of a map interface with as little as no code via Interface Builder!**_

[Realm Swift](https://realm.io/docs/swift/latest/) support was added in version 1.4 with an identical API.

_Did you find this library and haven't heard of Realm?_

The quick overview is that Realm is a replacement to Core Data or SQLite. It is extremely fast (enabling the instant map searching and clustering) and free to use. For more details head over to [Realm.io](http://www.realm.io)

####Screenshot
The demo app uses [RealmSFRestaurantData](https://github.com/bigfish24/RealmSFRestaurantData) to search through restaurants in San Francisco.

![SF Restaurant Map View](http://giant.gfycat.com/CleanSmartBadger.gif "SF Restaurant Map View")

####Tutorial
1. Add `MKMapView` to your Xib or storyboard and replace the class with `ABFRealmMapView` (`RealmMapView` for Swift version)
![Add MKMapView to storyboard](/images/xcode-storyboard1.png?raw=true "Add MKMapView to storyboard")

2. Adjust the Realm Map View properties to specify the fetched Realm entity name and key paths for latitude, longitude, and annotation view title and subtitles.
![Add MKMapView to storyboard](/images/xcode-storyboard2.png?raw=true "Add MKMapView to storyboard")

_**3. That's It!**_

If you still have questions, a slightly longer tutorial is available [here](https://realm.io/news/building-an-ios-clustered-map-view-in-objective-c/)

####Documentation
**Objective-C**
[Click Here](http://htmlpreview.github.io/?https://raw.githubusercontent.com/bigfish24/ABFRealmMapView/master/Documentation/ObjcDocs/index.html)

**Swift**
[Click Here](http://htmlpreview.github.io/?https://raw.githubusercontent.com/bigfish24/ABFRealmMapView/master/Documentation/SwiftDocs/index.html)

####Installation
`ABFRealmMapView` is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

_**Starting with Xcode 7.1, there is an issue with CocoaPods 0.39 that caused the interop of the Objective-C code for `ABFRealmMapView` to fail on compile when used in `RealmMapView`. This problem has now been resolved as of v1.6.6. Please be sure to use this version or higher with Xcode 7.1.**_

**Objective-C**
```
pod 'ABFRealmMapView'
```
**Swift**
```
use_frameworks!

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
