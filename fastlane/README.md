fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

## Choose your installation method:

<table width="100%" >
<tr>
<th width="33%"><a href="http://brew.sh">Homebrew</a></td>
<th width="33%">Installer Script</td>
<th width="33%">Rubygems</td>
</tr>
<tr>
<td width="33%" align="center">macOS</td>
<td width="33%" align="center">macOS</td>
<td width="33%" align="center">macOS or Linux with Ruby 2.0.0 or above</td>
</tr>
<tr>
<td width="33%"><code>brew cask install fastlane</code></td>
<td width="33%"><a href="https://download.fastlane.tools">Download the zip file</a>. Then double click on the <code>install</code> script (or run it in a terminal window).</td>
<td width="33%"><code>sudo gem install fastlane -NV</code></td>
</tr>
</table>

# Available Actions
## iOS
### ios increment_build
```
fastlane ios increment_build
```
Increments the build number for all targets
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
### ios test
```
fastlane ios test
```
Runs all the tests
### ios metadata
```
fastlane ios metadata
```
Uploads the application's metadata to iTunes Connect
### ios build
```
fastlane ios build
```


----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
