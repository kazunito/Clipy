<div align="center">
  <img src="./Resources/clipy_logo.png" width="400">
</div>

<br>

![CI](https://github.com/Clipy/Clipy/workflows/CI/badge.svg)
[![Release version](https://img.shields.io/github/release/Clipy/Clipy.svg)](https://github.com/Clipy/Clipy/releases/latest)
[![OpenCollective](https://opencollective.com/clipy/backers/badge.svg)](#backers)
[![OpenCollective](https://opencollective.com/clipy/sponsors/badge.svg)](#sponsors)

Clipy is a Clipboard extension app for macOS.

---

__Requirement__: macOS 13 Ventura or later

__Distribution Site__ : <https://clipy-app.com>

<img src="http://clipy-app.com/img/screenshot1.png" width="400">

### Development Environment
* macOS 26 Tahoe
* Xcode 26.5

### How to Build
macOS checks Accessibility permission by the app's code signature. If Clipy is built without a stable signing certificate, macOS may ask for Accessibility permission again for every build.

For this reason, the default signing settings use the Clipy signing certificate. This certificate is available only to the maintainer, so local builds require switching to ad-hoc signing before building.

#### Build for ad-hoc usage
1. Open `Clipy.xcodeproj` in Xcode.
2. Switch to ad-hoc build mode:
    1. Open `Configurations/CodeSigning.xcconfig`.
    2. Uncomment `#include "Configurations/CodeSigning-AdHoc.xcconfig"`.
3. Build the `Clipy` scheme.

If you want to use Firebase features, place your own `GoogleService-Info.plist` in `Clipy/GoogleService`. This file is not required for local builds without Firebase.

### Installing the prebuilt Apple Silicon build
The GitHub Releases of this fork are arm64 builds signed with a stable self-signed certificate (not notarized by Apple).

1. Open the `.dmg` and drag `Clipy.app` into `Applications` (replace any existing copy).
2. Launch Clipy. On macOS 15 Sequoia or later it is blocked on first launch: open
   **System Settings → Privacy & Security**, scroll to the bottom, and click **Open Anyway**
   for Clipy, then launch it again. (On older macOS, right-click the app and choose **Open**.)
3. Grant Accessibility: **System Settings → Privacy & Security → Accessibility**. If an entry
   from an earlier build already exists, remove it first, then add and enable `Clipy.app`.
   Because every release is signed with the same stable certificate, the Accessibility permission
   persists across updates and does not need to be re-granted. (If you build locally, sign with a
   stable self-signed certificate via `CODE_SIGN_IDENTITY` when running `scripts/package_dmg.sh`;
   a plain ad-hoc build would require re-granting after each rebuild.)

### Localization Contributors
Clipy is looking for localization contributors.  
If you can contribute, please see [CONTRIBUTING.md](https://github.com/Clipy/Clipy/blob/master/.github/CONTRIBUTING.md)

### Distribution
If you distribute derived work, especially in the Mac App Store, I ask you to follow two rules:

1. Don't use `Clipy` and `ClipMenu` as your product name.
2. Follow the MIT license terms.

Thank you for your cooperation.

### Privacy Policy
Please see [PRIVACY.md](./PRIVACY.md) for information about local data storage,
network communication, analytics, and crash reporting.

### Backers
Support us with a monthly donation and help us continue our activities. [[Become a backer](https://opencollective.com/clipy#backer)]

<a href="https://opencollective.com/clipy#backers"><img src="https://opencollective.com/clipy/backers.svg?avatarHeight=36&width=600" /></a>

### Sponsors
Become a sponsor and get your logo on our README on Github with a link to your site. [[Become a sponsor](https://opencollective.com/clipy#sponsor)]

<a href="https://opencollective.com/clipy#sponsors"><img src="https://opencollective.com/clipy/sponsors.svg?avatarHeight=36&width=600" /></a>

### Licence
Clipy is available under the MIT license. See the LICENSE file for more info.

Icons are copyrighted by their respective authors.

### Special Thanks
__Thank you for [@naotaka](https://github.com/naotaka) who have published [ClipMenu](https://github.com/naotaka/ClipMenu) as OSS.__
