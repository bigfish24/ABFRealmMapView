Pod::Spec.new do |s|
  s.name         = "ABFRealmMapView"
  s.version      = "1.6.4"
  s.summary      = "Drop-in clustering map interface for Realm objects"
  s.description  = <<-DESC
The ABFRealmMapView class creates an interface object that inherits MKMapView and manages fetching and displaying annotations for a Realm object class that contains coordinate data. 
                   DESC
  s.homepage     = "https://github.com/bigfish24/ABFRealmMapView"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Adam Fish" => "af@realm.io" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/bigfish24/ABFRealmMapView.git", :tag => "v#{s.version}" }
  s.source_files  = "ABFRealmMapView/*.{h,m}"
  s.requires_arc = true
  s.dependency "RBQFetchedResultsController", ">= 2.0"
  s.dependency "Realm", ">= 0.96"

end