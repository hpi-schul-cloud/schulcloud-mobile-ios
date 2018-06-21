#
# Be sure to run `pod lib lint SyncEngine.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SyncEngine'
  s.version          = '0.1.0'
  s.summary          = 'A short description of SyncEngine. It\'s a sync engine.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  #  s.homepage         = 'https://github.com/Einh06/SyncEngine'
  s.homepage         = 'http://EXAMPLE.EXAMPLE/SyncEngine'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Max Bothe' => 'max.bothe@hpi.de' }
  #  s.source           = { :git => 'https://github.com/Einh06/SyncEngine.git', :tag => s.version.to_s }
  s.source           = { :http => 'http://EXAMPLE.EXAMPLE/SyncEngine'}
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'

  s.source_files = 'Sources/**/*'

  # s.resource_bundles = {
  #   'SyncEngine' => ['SyncEngine/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'CoreData'
  s.dependency 'BrightFutures', '~> 6.0'
  s.dependency 'Marshal', '~> 1.2'
end
