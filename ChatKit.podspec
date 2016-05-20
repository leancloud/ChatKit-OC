Pod::Spec.new do |s|
  s.name         = "ChatKit"
  s.version      = "0.0.4"
  s.summary      = "An IM App Framework, support sending text, pictures, audio, video, location messaging, managing address book, more interesting features."
  s.homepage     = "https://github.com/LeanCloud/ChatKit-OC"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.authors      = { "LeanCloud" => "support@leancloud.cn" }
  s.platform     = :ios, '7.0'
  s.frameworks   = 'Foundation', 'CoreGraphics', 'UIKit', 'MobileCoreServices', 'AVFoundation', 'CoreLocation', 'MediaPlayer', 'CoreMedia', 'CoreText', 'AudioToolbox','MapKit','ImageIO','SystemConfiguration','CFNetwork','QuartzCore','Security','CoreTelephony'
  s.source       = { :git => "https://github.com/LeanCloud/ChatKit-OC.git", :tag => s.version.to_s }
  s.source_files  = 'ChatKit', 'ChatKit/**/*.{h,m}'
  s.vendored_frameworks = 'ChatKit/Class/Tool/Vendor/VoiceLib/lame.framework'
  s.resources    = 'ChatKit/Class/Resources/*'
  s.requires_arc = true
  s.dependency 'AVOSCloud'
  s.dependency 'AVOSCloudIM'
  s.dependency 'MJRefresh'
  s.dependency 'Masonry'
  s.dependency 'SDWebImage'
  s.dependency 'FMDB'
  s.dependency 'UITableView+FDTemplateLayoutCell'

end
