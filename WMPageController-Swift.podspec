Pod::Spec.new do |s|
   s.name         = "WMPageController-Swift"
   s.version      = "1.2.2"
   s.summary      = "An easy solution to page controllers like NetEase News.(Swift Implementation)"
   s.homepage     = "https://github.com/wangmchn/WMPageController-Swift"
   s.license      = 'MIT (LICENSE)'
   s.author       = { "wangmchn" => "wangmchn@163.com" }
   s.source       = { :git => "https://github.com/wangmchn/WMPageController-Swift.git", :tag => "1.2.2" }
   s.platform     = :ios, '8.0'

   s.source_files = 'PageController', 'PageController/**/*.{swift}'
   s.exclude_files = 'Example'

   s.frameworks = 'Foundation', 'CoreGraphics', 'UIKit'
   s.requires_arc = true
 end