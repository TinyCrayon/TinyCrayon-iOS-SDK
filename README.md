# TinyCrayon SDK for iOS
> A smart and easy-to-use image masking and cutout SDK for mobile apps.

[![Website](https://img.shields.io/website/http/tinycrayon.com/.svg)](http://www.tinycrayon.com/)
[![platform](https://img.shields.io/cocoapods/p/TinyCrayon.svg)](https://cocoapods.org/pods/TinyCrayon)
[![Compatible](https://img.shields.io/badge/compatible-Swift%20%2F%20Objective--C%20-yellow.svg)](https://cocoapods.org/pods/TinyCrayon)
[![CocoaPods](https://img.shields.io/cocoapods/v/TinyCrayon.svg)](https://cocoapods.org/pods/TinyCrayon)
[![Documentation](https://img.shields.io/badge/docs-latest-green.svg)](https://www.tinycrayon.com/docs-iOS/index.html)
[![App Store](https://img.shields.io/badge/app%20store-sample%20apps-orange.svg)](https://itunes.apple.com/developer/yongyun-zeng/id1071044410)
[![license](https://img.shields.io/cocoapods/l/TinyCrayon.svg)](https://github.com/TinyCrayon/TinyCrayon-iOS-SDK/blob/master/LICENSE)

TinyCrayon SDK provides tools for adding image cutout and layer mask capabilities to your mobile applications.

![Quick Select Tool](https://cloud.githubusercontent.com/assets/4088232/23604872/7248944e-0295-11e7-83dc-002b267789d1.gif) | ![Hair Brush Tool](https://cloud.githubusercontent.com/assets/4088232/23604871/6f0c390c-0295-11e7-979d-f4824d839931.gif)
------------ | -------------
Quick Select Tool | Hair Brush Tool

Try our sample apps [Image Eraser](https://itunes.apple.com/app/id1072712460), [Color Effect](https://itunes.apple.com/app/id1222383759), [Focus Effect](https://itunes.apple.com/app/id1064333794).

## Table of Contents

* [Overview](#overview)
* [Features](#features)
* [Installation](#installation)
   * [Prerequisites](#prerequisites)
   * [Streamlined, using CocoaPods](#streamlined-using-cocoapods)
   * [Manually, using the SDK download](#manually-using-the-sdk-download)
      * [Download the SDK](#download-the-sdk)
      * [Add the framework](#add-the-framework)
   * [Settings for Objective-C](#settings-for-objective-c)
* [Usage](#usage)
   * [Add a TCMaskView](#add-a-tcmaskview)
   * [TCMask class](#tcmask-class)
* [Further reading](#further-reading)
* [License](#license)
* [Terms of use](#terms-of-use)

## Overview
TinyCrayon SDK provides tools for adding image cutout and layer mask capabilities to your mobile applications.

Image layer mask is a fundamental technique in image manipulations. It allows you to selectively modify the opacity (transparency) of the layer they belong to. This flexibility to define the opacity of different areas of a layer is the basis for more interesting image manipulation techniques such as selective coloring and luminosity masking.

The current version of TinyCrayon SDK provides the following three tools:
* Quick Select: Smart and easy to use, users just need to select part of the object and the edge detection algorithm will find the boundary.
* Hair Brush: Smooth and natual looking, paint on the hair/fur of an object and the algorithm will select the hair/fur for you in high quality.
* Regular Brush: A regular brush tool with the capability to adjust its size, hardness and opacity.

## Features
* Free: TinyCrayon SDK is provided under MIT license, you can use it in your commercial applications for free!
* iPad support: TinyCrayon SDK uses auto layout for its views and adapts to each screen size - iPhone or iPad.
* Highly customizable: Style the UI, view modes and localized languages as you wish.
* Swift: Keeping up with time, we chose Swift as the main development language of the TinyCrayon SDK, leading to leaner easier code.
* Objective-C support: All of our public API is Objective-C compatible.

![create as many effects as you can think of](https://cloud.githubusercontent.com/assets/4088232/24956166/ffc4285c-1fb8-11e7-9743-209de801e31a.jpg)

## Installation

### Prerequisites
* Xcode 8.0 or later.
* A physical iOS device.
* Recommended: [installation of CocoaPods](http://guides.cocoapods.org/using/getting-started) to simplify dependency management.

### Streamlined, using CocoaPods
TinyCrayon SDK is available via CocoaPods. If you're new to CocoaPods, this [Getting Started Guide](https://guides.cocoapods.org/using/getting-started.html) will help you. CocoaPods is the preferred and simplest way to use the TinyCrayon SDK.

**Important:** Please make sure that you have a CocoaPods version >= 0.39.0 installed. You can check your version of CocoaPods with `pod --version`.

Here's what you have to add to your `Podfile` (if you do not have `Podfile`, create one in your project root directory):

```
target 'MyApp' do
  pod 'TinyCrayon'
end
```

Then run `pod install` in your project root directory (same directory as your `Podfile`).

Open MyApp.xcworkspace and build.

### Manually, using the SDK download
If you don't want to use Cocoapods you can still take advantage of the TinyCrayon SDK by importing the frameworks directly.

#### Download the SDK

1. Download the [TinyCrayon SDK zip](https://www.tinycrayon.com/sdk/iOS/TinyCrayon.zip) (this is a ~20MB file and may take some time).
2. Unzip the TinyCrayon.zip

#### Add the framework

1. Drag `TCCore.framework` into the `Linked Frameworks and Libraries` section of your target.
2. Drag `TCMask.framework` into the `Embedded Binaries` section of your target.

![Add the framework](https://cloud.githubusercontent.com/assets/4088232/23100618/eef29a52-f6c0-11e6-85ec-a0ea86979cbf.png)

### Settings for Objective-C

If your project is using Objective-C, set `Always Embed Swift Standard Libraries` to be YES in your Build Settings.

## Usage

### Add a TCMaskView

The `TCMaskView` class is responsible to create a `UIViewController` for the user to mask the image.
To present a `TCMaskView`:

*Swift*
```
let maskView = TCMaskView(image: image)
maskView.delegate = self
maskView.presentFrom(rootViewController: self, animated: true)
```
*Objective-C*
```
TCMaskView *maskView = [[TCMaskView alloc] initWithImage:image];
maskView.delegate = self;
[maskView presentFromRootViewController:self animated:true];
```

The delegate of the `TCMaskView` can be used to be notified when the user cancels or completes the edit. In last case the function `tcMaskViewDidComplete(mask:image:)` is called. 

### TCMask class

`TCMask` is provided by `TCMaskViewDelegate` functions as the first parameter when the user cancels or completes the edit. For example, when the user completes the edit with `TCMaskView`:

*swift*
```
func tcMaskViewDidComplete(mask: TCMask, image: UIImage) {}
```
*Objective-C*
```
- (void)tcMaskViewDidCompleteWithMask:(TCMask *)mask image:(UIImage *)image {}
```

`TCMask` is an encapsulation of image masking result from `TCMaskView`, it has the following properties:

* data: An array of 8-bits unsigned char, its length is equal to the number of pixels of the image in `TCMaskView`. Each element in data represents the mask value.
* size: The size of mask, which is equal to the size of the image in `TCMaskView`.

`TCMask` also provides some simple and easy to use functions to process layer mask with image. For example, to cutout an object:

*Swift*
```
let outputImage = mask.cutout(image: image, resize: false)
```
*Objective-C*
```
UIImage *outputImage = [mask cutoutWithImage:image resize:false];
```

To try these examples, and find out about more options please take a look at the [Examples](https://github.com/TinyCrayon/TinyCrayon-iOS-SDK/releases).

## Further reading
* Try our sample apps [Image Eraser](https://itunes.apple.com/app/id1072712460), [Color Effect](https://itunes.apple.com/app/id1222383759), [Focus Effect](https://itunes.apple.com/app/id1064333794).
* Check out TinyCrayon [guides](http://tinycrayon.com/guides-iOS/get-started.html) and [API reference](http://tinycrayon.com/docs-iOS/index.html) for more details.

## License
The MIT license
