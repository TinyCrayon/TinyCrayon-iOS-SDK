# TinyCrayon SDK for iOS

## Overview
TinyCrayon SDK provides tools for adding image layer mask capabilities to your mobile applications.

Image layer mask is a fundamental technique in image manipulations. It allows you to selectively modify the opacity (transparency) of the layer they belong to. This differs from the use of the layer Opacity slider as a mask has the ability to selectively modify the opacity of different areas across a single layer.

The current version of TinyCrayon SDK provides the following three tools:
* Quick Select: Smart and easy to use, you just need to select part of the object and the edge detection algorithm will find the boundary for you.
* Hair Brush: Smooth and natual, paint on the hair or fur of an object and the algorithm will select the hair or bur for you in high quality.
* Regular Brush: A regular brush with the capability to adjust its size, hardness and opacity.

## Features
* Free: TinyCrayon SDK is provided under MIT license, you can use it in your commercial applications for free!
* iPad support: TinyCrayon SDK uses auto layout for its views and adapts to each screen size - iPhone or iPad.
* Highly customizable: Style the UI and view modes as you wish.
* Swift: Keeping up with time, we chose Swift as the main development language of the TinyCrayon SDK, leading to leaner easier code.
* Objective-C support: All of our public API is Objective-C compatible.

## Installation
### Streamlined, using CocoaPods
TinyCrayon SDK is available via CocoaPods. If you're new to CocoaPods, [this Getting Started Guide will help you](https://guides.cocoapods.org/using/getting-started.html). CocoaPods is the preferred and simplest way to use the TinyCrayon SDK.

**Important:** Please make sure that you have a CocoaPods version >= 0.39.0 installed. You can check your version of CocoaPods with `pod --version`.

Here's what you have to add to your `Podfile`:

```
use_frameworks!

pod 'TinyCrayon'
```

Then run `pod install`.

### Manually, using the SDK download
If you don't want to use Cocoapods you can still take advantage of the TinyCrayon SDK by importing the frameworks directly.

#### Download the SDK

1. Download the [TinyCrayon SDK zip](https://github.com/TinyCrayon/TinyCrayon-iOS-SDK/releases/download/v1.0.0/TinyCrayon.zip) (this is a ~20MB file and may take some time).
2. Unzip the TinyCrayon.zip
3. Add the [`ObjC` linker flag](https://developer.apple.com/library/content/qa/qa1490/_index.html) in your `Other Linker Settings` in your target's build settings.

#### Add the framework

1. Drag `TCCore.framework` into the `Linked Frameworks and Libraries` section of your target.
2. Drag `TCMask.framework` into the `Embedded Binaries` section of your target.

![Add the framework](https://cloud.githubusercontent.com/assets/4088232/23100618/eef29a52-f6c0-11e6-85ec-a0ea86979cbf.png)

## Usage

## Further reading
* Try our example app [Image Eraser](https://itunes.apple.com/app/id1072712460).
* Check out TinyCrayon [guides](http://tinycrayon.com/guides-iOS/get-started.html) and [API reference](http://tinycrayon.com/docs-iOS/index.html) for more details.

## License
The MIT license
