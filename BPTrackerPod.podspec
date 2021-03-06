#
# Be sure to run `pod lib lint BPTrackerPod.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'BPTrackerPod'
  s.version          = '1.0.7'
  s.summary          = 'This Pod will allow users to connect with MedCheck BLE Devices and read data from BLE.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = 'This Pod will allow users to connect with MedCheck BLE Devices and read data from BLE. This SDK will return data.'

  s.homepage         = 'https://github.com/LNAndroid/BPTrackerPod'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'LNAndroid' => 'pratik.patel@letsnurture.com' }
  s.source           = { :git => 'https://github.com/LNAndroid/BPTrackerPod.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'BPTrackerPod/Classes/**/*'
  
  # s.resource_bundles = {
  #   'BPTrackerPod' => ['BPTrackerPod/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
end
