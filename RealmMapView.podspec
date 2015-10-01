Pod::Spec.new do |s|
  s.name         = "RealmMapView"
  s.version      = "1.2.1"
  s.summary      = "Drop-in clustering map interface for Realm Swift objects"
  s.description  = <<-DESC
The RealmMapView class creates an interface object that inherits MKMapView and manages fetching and displaying annotations for a Realm Swift object class that contains coordinate data. 
                   DESC
  s.homepage     = "https://github.com/bigfish24/ABFRealmMapView"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Adam Fish" => "af@realm.io" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/bigfish24/ABFRealmMapView.git", :tag => "v#{s.version}" }
  s.source_files  = "RealmMapView/*.{h,swift}", "ABFRealmMapView/*.{h,m}"
  s.requires_arc = true
  s.dependency "RBQFetchedResultsController", ">= 2.0"
  s.dependency "RealmSwift", ">= 0.95.1"

end