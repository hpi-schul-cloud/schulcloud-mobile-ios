# Schul-cloud for iOS
native iOS application for https://schul-cloud.org/

### Issues
The [issues for this project](https://ticketsystem.schul-cloud.org/projects/IOS/issues) are managed in the global ticket system for Schul-Cloud.

### Development toolchain
- Xcode 9.2
- bundler: `gem install bundler`

The following tools will be installed via bundler:
- [CocoaPods](https://cocoapods.org/)
- [fastlane](https://fastlane.tools/)

### How to get started
- clone this repository
- run `bundle install`
- run `bundle exec pod repo update` and `bundle exec pod install`
- open `schulcloud.xcworkspace` in Xcode

#### Setup fastlane
- make your own Appfile via `cp fastlane/Appfile.dummy fastlane/Appfile`
- set the following values
  - `apple_id`
  - `itunes_connect_id` (if required)
- for all available fastlane commands have a look at the [fastlane Readme](https://github.com/schul-cloud/schulcloud-mobile-ios/tree/master/fastlane/)

#### Setup testing
- copy the credentials plist dummy file `cp iOSUITests/Credentials.plist.dummy iOSUITests/Credentials.plist`
- enter your login credentials for testing

### How to release to apps
- Install git-crypt via `brew install git-crypt`
- Retrieve the `schulcloud-mobile-ios.key` from the Schul-cloud team and run `git-crypt unlock /path/to/schulcloud-mobile-ios.key`
- Use the standard Xcode workflow to upload the app to iTunesConnect (You have to possess the iOS Distribution Certificate)

