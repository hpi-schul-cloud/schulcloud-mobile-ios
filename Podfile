use_frameworks!
inhibit_all_warnings!

platform :ios, '10.0'

pod 'SwiftLint', '~> 0.25'


target 'Common' do
  pod 'Alamofire', '4.4.0'
  pod 'BrightFutures', '~> 6.0'
  pod 'Firebase/Auth'
  pod 'Firebase/Core'
  pod 'Firebase/Messaging'
  pod 'JWTDecode'
  pod 'Locksmith'
  pod 'SwiftyBeaver', :git => 'https://github.com/SwiftyBeaver/SwiftyBeaver.git', :commit => 'e4563d1'
  pod 'SyncEngine', :path => './Frameworks/SyncEngine'
    target 'iOS' do
    inherit! :search_paths
      pod 'CalendarKit', '0.2.0'
      pod 'SimpleRoundedButton'
      target 'iOS-Tests' do
        inherit! :search_paths
        pod 'Firebase'
      end
    end
end
