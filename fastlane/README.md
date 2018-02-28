fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew cask install fastlane`

# Available Actions
## iOS
### ios increment_version_patch
```
fastlane ios increment_version_patch
```
Increments the version number for a new patch version
### ios increment_version_minor
```
fastlane ios increment_version_minor
```
Increments the version number for a new minor version
### ios increment_version_major
```
fastlane ios increment_version_major
```
Increments the version number for a new major version
### ios determine_commit
```
fastlane ios determine_commit
```
Determines the commit for a given build number

- pass build number via 'build_number:xxx'
### ios makescreenshots
```
fastlane ios makescreenshots
```
Create screenshots
### ios upload_screenshots
```
fastlane ios upload_screenshots
```
Upload only screenshots to iTunesConnect

No upload of screenshots or IPA
### ios upload_metadata
```
fastlane ios upload_metadata
```
Upload only metadata to iTunesConnect

No upload of screenshots or IPA
### ios release
```
fastlane ios release
```
Build and upload only IPA and metadata to iTunesConnect

No upload of screenshots
### ios beta
```
fastlane ios beta
```
Build and upload only IPA (beta) to iTunesConnect

No upload of screenshots or metadata
### ios tag_release
```
fastlane ios tag_release
```

### ios refresh_dsyms
```
fastlane ios refresh_dsyms
```
Download dSYMS files from iTunesConnect and upload them to Firebase
### ios changelog
```
fastlane ios changelog
```


----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
