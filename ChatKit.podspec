Pod::Spec.new do |s|
  s.name         = "ChatKit"
  s.version      = "0.7.19"
  s.summary      = "An IM App Framework, support sending text, pictures, audio, video, location messaging, managing address book, more interesting features."
  s.homepage     = "https://github.com/LeanCloud/ChatKit-OC"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.authors      = { "LeanCloud" => "support@leancloud.cn" }
  s.platform     = :ios, '7.0'
  s.frameworks   = 'Foundation', 'CoreGraphics', 'UIKit', 'MobileCoreServices', 'AVFoundation', 'CoreLocation', 'MediaPlayer', 'CoreMedia', 'CoreText', 'AudioToolbox','MapKit','ImageIO','SystemConfiguration','CFNetwork','QuartzCore','Security','CoreTelephony'
  s.source       = { :git => "https://github.com/LeanCloud/ChatKit-OC.git", :tag => s.version.to_s }
  s.source_files  = 'ChatKit', 'ChatKit/**/*.{h,m}'
  s.vendored_frameworks = 'ChatKit/Class/Tool/Vendor/VoiceLib/lame.framework'
  s.resources    = 'ChatKit/Class/Resources/*', 'ChatKit/**/*.xib'

  s.requires_arc = true
  s.dependency "AVOSCloud" , "~> 3.5.1"
  s.dependency "AVOSCloudIM", "~> 3.5.1"
  s.dependency "MJRefresh" , "~> 3.1.9"
  s.dependency "Masonry" , "~> 1.0.1"
  s.dependency "SDWebImage" , "~> 3.8.0"
  s.dependency "FMDB" , "~> 2.6.2"
  s.dependency "pop", "~> 1.0.9"
  s.dependency "UITableView+FDTemplateLayoutCell" , "~> 1.5.beta"
  s.dependency "FDStackView" , "~> 1.0"
  s.dependency "DACircularProgress" , "~> 2.3.1"
  s.dependency "MLLabel" , "~> 1.9.2"
  s.dependency "MWPhotoBrowser", "~> 2.1.2"

end
