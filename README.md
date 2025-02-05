# lint connect

A modern iOS companion app for your [pocket lint](https://github.com/markuryy/pocket_lint) device. Because every charming little gadget deserves an equally charming app.

## What is this?

This is a SwiftUI-powered iOS app that connects to your pocket lint device over Bluetooth LE. Currently, it's focused on doing one thing ~~really well~~: transferring images to your device's display. Think of it as a streamlined, modern take on Adafruit's Bluefruit Connect app, but **worse**.

## Features

- **Clean Device Management**: Quickly find and connect to your pocket lint
- **Simple Image Transfer**: Select, preview, and send images to your device
- **Modern UI**: Built with SwiftUI for a native iOS feel
- **Future-Ready**: Structured to support more features as the pocket lint evolves

## Installation

Since this app isn't on the App Store, you'll need to build it yourself:

1. Clone this repository
2. Open `lint.xcodeproj` in Xcode
3. Select your development team (if you have one)
4. Build and run on your device

### Requirements

- iOS 18.0 or later
- Xcode 16.0 or later
- A physical iOS device (the iOS Simulator doesn't support Bluetooth)

## Usage

### Connecting to Your Device

1. Power on your pocket lint
2. Open the app
3. Pull down to start scanning
4. Select your device from the list

### Sending Images

1. Make sure you're connected to your device
2. Tap the "Image Transfer" card
3. Select an image from your photo library
4. Adjust settings if needed (resolution, rotation)
5. Tap "Send" and watch the magic happen

### Tips

- Keep your device within reasonable Bluetooth range (about 10 meters/33 feet)
- Larger images take longer to transfer
- If the transfer fails, try reducing the image resolution

## Development Notes

This app is built with SwiftUI and Core Bluetooth, ~~taking inspiration from~~ reskinning Adafruit's Bluefruit LE Connect v2 with fewer features. The codebase is organized into feature modules for clarity and future expansion.

### Technical Overview

- **UI**: SwiftUI with MVVM architecture
- **Bluetooth**: Core Bluetooth for device communication
- **Image Processing**: Native iOS frameworks for image handling
- **Navigation**: Tab-based with clear workflows

### License

MIT

### Credits

Special thanks to Adafruit for their [Bluefruit LE Connect v2](https://github.com/adafruit/Bluefruit_LE_Connect_v2) app, which is awesomely open source.

Even bigger thanks to **me** for making the icon.

![](lint/Assets.xcassets/AppIcon.appiconset/Icon-Dark-1024x1024.png)