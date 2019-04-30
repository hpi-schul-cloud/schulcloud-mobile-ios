use_frameworks!
inhibit_all_warnings!

platform :ios, '10.0'

pod 'SwiftLint', '~> 0.25'
pod 'R.swift'

target 'Common' do
  pod 'BrightFutures', '~> 8.0'
  pod 'Firebase/Auth'
  pod 'Firebase/Core'
  pod 'Firebase/Messaging'
  pod 'JWTDecode', '~> 2.0'
  pod 'SyncEngine', :path => './Frameworks/SyncEngine'
  pod 'HTMLStyler', :path => './Frameworks/HTMLStyler'

  target 'Common-Tests' do
    inherit! :search_paths
  end

  target 'iOS-fileprovider' do
    inherit! :search_paths
  end
end

target 'iOS' do
  pod 'CalendarKit', '~> 0.2'
end


post_install do |installer|
  Pod::UI.info "Remove duplicate pods (across multiple targets)"
  target_names = ['Pods-iOS', 'Pod-iOS-fileprovider'] 
  sharedLibrary = installer.aggregate_targets.find { |aggregate_target| aggregate_target.name == 'Pods-Common' }
  installer.aggregate_targets.each do |aggregate_target|
    if target_names.include? aggregate_target.name
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
              Pod::UI.message "Removing #{name} from OTHER_LDFLAGS"
              config_file.frameworks.delete(name)
            end
          end
        end
        xcconfig_path = aggregate_target.xcconfig_path(config_name)
        config_file.save_as(xcconfig_path)
      end
    end
  end


  Pod::UI.info "Fix provisioning profile specifiers"
  installer.pods_project.build_configurations.each do |config|
    config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = ''
  end

  # This is highly inspired by cocoapods-acknowledgements (https://github.com/CocoaPods/cocoapods-acknowledgements)
  # but creates only one pod license file for iOS instead of one license file for each target
  # Additonally, it provides more customization possibilities.
  Pod::UI.info "Adding Pod Licenses"
  excluded = ['SwiftLint', 'SyncEngine']
  sandbox = installer.sandbox
  common_target = installer.aggregate_targets.select { |target| target.label.include? 'Common' }.first
  ios_target = installer.aggregate_targets.select { |target| target.label.include? 'iOS' }.first
  all_specs = common_target.specs.map(&:root) + ios_target.specs.map(&:root)
  ios_specs = all_specs.uniq.sort_by { |spec| spec.name }.reject { |spec| excluded.include?(spec.name) }

  pod_licenses = []
  ios_specs.each do |spec|
    pod_root = sandbox.pod_dir(spec.name)
    platform = Pod::Platform.new(ios_target.platform.name)
    file_accessor = file_accessor(spec, platform, sandbox)
    license_text = get_license_text(spec, file_accessor)
    license_text = license_text.gsub(/(.)\n(.)/, '\1 \2') if license_text # remove in text line breaks

    pod_license = {
      "Title" => spec.name,
      "Type" => "PSGroupSpecifier",
      "FooterText" => license_text,
    }
    pod_licenses << pod_license
  end

  metadata = {
    "PreferenceSpecifiers" => pod_licenses,
  }

  project = Xcodeproj::Project.open(ios_target.user_project_path)
  settings_bundle = settings_bundle_in_project(project)

  if settings_bundle == nil
    Pod::UI.warn "Could not find a Settings.bundle to add the Pod Settings Plist to."
  else
    settings_plist_path = settings_bundle + "/PodLicenses.plist"
    Xcodeproj::Plist.write_to_path(metadata, settings_plist_path)
    Pod::UI.info "Added Pod licenses to Settings.bundle for iOS"
  end
end


##########
# Helper methods for plist operations
##########

def file_accessor(spec, platform, sandbox)
  pod_root = sandbox.pod_dir(spec.name)
  if pod_root.exist?
      path_list = Pod::Sandbox::PathList.new(pod_root)
      Pod::Sandbox::FileAccessor.new(path_list, spec.consumer(platform))
  end
end

# Returns the text of the license for the given spec.
#
# @param  [Specification] spec
#         the specification for which license is needed.
#
# @return [String] The text of the license.
# @return [Nil] If not license text could be found.
#
def get_license_text(spec, file_accessor)
  return nil unless spec.license
  text = spec.license[:text]
  unless text
      if file_accessor
          if license_file = file_accessor.license
              if license_file.exist?
              text = IO.read(license_file)
              else
              Pod::UI.warn "Unable to read the license file `#{license_file }` " \
                  "for the spec `#{spec}`"
              end
          end
      end
  end
  text
end

def settings_bundle_in_project(project)
  file = project.files.find { |f| f.path =~ /Settings\.bundle$/ }
  file.real_path.to_path unless file.nil?
end
