#
# Be sure to run `pod lib lint KFSwiftImageLoader.podspec' to ensure this is a
# valid spec before submitting.
#

Pod::Spec.new do |s|
  s.name             = 'KFSwiftImageLoader'
  s.version          = '3.0.0'
  s.summary          = 'High-performance, lightweight, and energy-efficient pure Swift async web image loader with memory and disk caching for iOS and  Watch.'
  s.homepage         = 'https://github.com/kiavashfaisali/KFSwiftImageLoader'

  s.license          = { :type => 'MIT',
  						 :file => 'LICENSE' }
  s.author           = { 'Kiavash Faisali' => 'kiavashfaisali@outlook.com' }
  s.source           = { :git => 'https://github.com/kiavashfaisali/KFSwiftImageLoader.git',
  						 :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'

  s.source_files = 'KFSwiftImageLoader/Classes/**/*'
end
