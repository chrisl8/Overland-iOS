# CLAUDE.md

Overland is a native iOS app (Objective-C, UIKit, storyboards, plus a Swift Live Activity extension) that logs GPS location, motion, steps and battery in the background and posts batches to a user-configured HTTP endpoint. This repo is the client only.

This is a fork of aaronpk/Overland-iOS. `origin` is chrisl8's fork, `upstream` is aaronpk's. The `custom` branch carries local changes on top of upstream `main`; keep it rebased on `upstream/main` and the diff small.

## Build

```
brew install cocoapods
pod install
cp template_setup.xcconfig developer_setup.xcconfig   # gitignored; set TEAM_ID and BUNDLE_ID
open Overland.xcworkspace
```

`Config/Overland-{Debug,Release}.xcconfig` wrap the Pods xcconfigs and default `BUNDLE_ID` to upstream's, so CI builds without `developer_setup.xcconfig`. The Live Activity target is `$(BUNDLE_ID).LiveActivity` and the iCloud container is `iCloud.$(BUNDLE_ID)` (entitlements and Info.plist), so a personal bundle ID gets its own container.

There is no test target. `.github/workflows/release.yml` builds an unsigned `.ipa` when a `v*` tag is pushed. It checks the tag against `CFBundleShortVersionString`.

## Local changes on top of upstream

- Signing and bundle ID via xcconfig (above), and the release workflow.
- Wifi zones accept an optional `min_time` (seconds), which replaces the global minimum time between points while on that zone's network, except during a trip. Wifi names compare case-insensitively. Both live in `GLManager.m` (`wifiZoneMatchingName:bssid:`, `processNewLocations:`) and `WifiZoneViewController.m`.

## Architecture

Almost all logic is in the `GLManager` singleton: CoreLocation/CoreMotion config, every setting (each backed by a `GL*DefaultsName` NSUserDefaults key, usually with a `*DuringTrip` twin), the unsent-point queue (`LOLDatabase` over FMDB), and sending batches. View controllers are thin and observe `GL*Notification`s. Read `README.md`'s API section before touching request building or server-response parsing, since that JSON is the contract with third-party backends.
