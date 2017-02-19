//
//  The MIT License
//
//  Copyright (C) 2016 TinyCrayon.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.
//

#import "ViewController.h"
@import TCMask;

@interface ViewController ()
@end

@interface UIImage (grayScaleImage)
- (UIImage *)convertToGrayScaleNoAlpha;
@end

@implementation ViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (imageView.image == nil) {
        [self preSentTCMaskView];
    }
}

- (IBAction)editButtonTapped:(id)sender {
    [self preSentTCMaskView];
}

- (void)preSentTCMaskView {
    UIImage *image = [UIImage imageNamed:@"Balloon.JPEG"];
    TCMaskView *maskView = [[TCMaskView alloc] initWithImage:image];
    maskView.delegate = self;
    
    // Change status bar style
    maskView.statusBarStyle = UIStatusBarStyleDefault;
    
    // Change UI components style
    UIColor *tintColor = [[UIColor alloc] initWithRed:0 green:122.0/255.0 blue:1 alpha:1];
    maskView.topBar.backgroundColor = [[UIColor alloc] initWithWhite:247.0/255.0 alpha:1];
    maskView.topBar.tintColor = tintColor;
    
    maskView.imageView.backgroundColor = [[UIColor alloc] initWithWhite:231.0/255.0 alpha:1];
    maskView.imageView.tintColor = tintColor;
    
    maskView.toolPanel.backgroundColor = [UIColor whiteColor];
    maskView.toolPanel.tintColor = tintColor;
    maskView.toolPanel.highlightedColor = [[UIColor alloc] initWithWhite:231.0/255.0 alpha:1];
    maskView.toolPanel.textColor = tintColor;
    
    maskView.bottomBar.backgroundColor = [[UIColor alloc] initWithWhite:247.0/255.0 alpha:1];
    maskView.bottomBar.tintColor = tintColor;
    maskView.bottomBar.textColor = tintColor;
    maskView.bottomBar.highlightedColor = [UIColor whiteColor];
    
    maskView.settingView.backgroundColor = [UIColor whiteColor];
    maskView.settingView.tintColor = tintColor;
    maskView.settingView.textColor = [UIColor blackColor];
    
    maskView.settingViewTopBar.backgroundColor = [[UIColor alloc] initWithWhite:247.0/255.0 alpha:1];
    maskView.settingViewTopBar.tintColor = tintColor;
    maskView.settingViewTopBar.textColor = [UIColor blackColor];
    
    // Create a customized view mode with gray scale image
    UIImage *grayScaleImage = [image convertToGrayScaleNoAlpha];
    TCMaskViewMode *viewMode = [[TCMaskViewMode alloc] initWithForegroundImage:grayScaleImage backgroundImage:nil isInverted:true];
    
    // set customized viewMode to be the only view mode in TCMaskView
    maskView.viewModes = @[viewMode];
    
    [maskView presentFromRootViewController:self animated:true];
}

- (void)tcMaskViewDidCompleteWithMask:(TCMask *)mask image:(UIImage *)image {
    imageView.image = [mask cutoutWithImage:image resize:true];
}

@end

@implementation UIImage (grayScaleImage)

- (UIImage *)convertToGrayScaleNoAlpha {
    CGContextRef context = CGBitmapContextCreate(nil, self.size.width, self.size.height, 8, 0, CGColorSpaceCreateDeviceGray(), kCGImageAlphaNone);
    CGContextDrawImage(context, CGRectMake(0, 0, self.size.width, self.size.height), self.CGImage);
    return [[UIImage alloc] initWithCGImage:CGBitmapContextCreateImage(context)];
}

@end
