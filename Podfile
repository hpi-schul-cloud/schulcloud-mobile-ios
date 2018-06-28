use_frameworks!
inhibit_all_warnings!

platform :ios, '10.0'

pod 'SwiftLint', '~> 0.25'

def common_pods
  pod 'Alamofire', '4.4.0'
  pod 'BrightFutures', '~> 6.0'
  pod 'Firebase/Auth'
  pod 'Firebase/Core'
  pod 'Firebase/Messaging'
  pod 'JWTDecode', '2.0.0'
  pod 'Locksmith', '3.0.0'
  pod 'SwiftyBeaver', :git => 'https://github.com/SwiftyBeaver/SwiftyBeaver.git', :commit => 'e4563d1'
  pod 'SyncEngine', :path => './Frameworks/SyncEngine'
end

target 'Common' do
  common_pods
end

target 'schulcloud' do
  pod 'CalendarKit', '0.2.0'
  pod 'SimpleRoundedButton'
end

post_install do |installer|
  sharedLibrary = installer.aggregate_targets.find { |aggregate_target| aggregate_target.name == 'Pods-Common' }
  installer.aggregate_targets.each do |aggregate_target|
    if aggregate_target.name == 'Pods-schulcloud'
      aggregate_target.xcconfigs.each do |config_name, config_file|
        sharedLibraryPodTargets = sharedLibrary.pod_targets
        aggregate_target.pod_targets.select { |pod_target| sharedLibraryPodTargets.include?(pod_target) }.each do |pod_target|
          pod_target.specs.each do |spec|
            frameworkPaths = unless spec.attributes_hash['ios'].nil? then spec.attributes_hash['ios']['vendored_frameworks'] else spec.attributes_hash['vendored_frameworks'] end || Set.new
            frameworkNames = Array(frameworkPaths).map(&:to_s).map do |filename|
              extension = File.extname filename
              File.basename filename, extension
            end
            frameworkNames.each do |name|
              puts "Removing #{name} from OTHER_LDFLAGS"
              config_file.frameworks.delete(name)
            end
          end
        end
        xcconfig_path = aggregate_target.xcconfig_path(config_name)
        config_file.save_as(xcconfig_path)
      end
    end
  end
end
