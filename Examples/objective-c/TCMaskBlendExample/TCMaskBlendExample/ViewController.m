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
#import <CoreImage/CoreImage.h>

@interface ViewController ()
@end

@interface UIImage (SolidColorImage)
- (id)initWithUIColor:color size:(CGSize)size;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [buttonGroup setHidden:true];
    imagePicker = [[UIImagePickerController alloc] init];
}

- (IBAction)selectImageButtonTapped:(id)sender {
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePicker.delegate = self;
    [self presentViewController:imagePicker animated:true completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    image = info[UIImagePickerControllerOriginalImage];
    [imagePicker dismissViewControllerAnimated:false completion:nil];
    
    TCMaskView *maskView = [[TCMaskView alloc] initWithImage:image];
    maskView.delegate = self;
    [maskView presentFromRootViewController:self animated:true];
}

- (void)tcMaskViewDidCompleteWithMask:(TCMask *)tcmask image:(UIImage *)tcimage {
    self->mask = tcmask;
    [buttonGroup setHidden:false];
    
    // adjust the size of image view to make it fit the image size and put it in the center of screen
    CGFloat x, y, width, height;
    if (image.size.width > image.size.height) {
        width = containerView.frame.size.width;
        height = width * image.size.height / image.size.width;
        x = 0;
        y = (containerView.frame.size.height - height) / 2;
    }
    else {
        height = containerView.frame.size.height;
        width = height * image.size.width / image.size.height;
        x = (containerView.frame.size.width - width) / 2;
        y = 0;
    }
    imageView.frame = CGRectMake(x, y, width, height);
    
    imageView.image = [mask cutoutWithImage:image resize:false];
}

- (IBAction)whiteButtonTapped:(id)sender {
    UIImage *whiteImage = [[UIImage alloc] initWithUIColor:[UIColor whiteColor] size:image.size];
    imageView.image = [mask blendWithForegroundImage:image backgroundImage:whiteImage];
}

- (IBAction)blackButtonTapped:(id)sender {
    UIImage *blackImage = [[UIImage alloc] initWithUIColor:[UIColor blackColor] size:image.size];
    imageView.image = [mask blendWithForegroundImage:image backgroundImage:blackImage];
}

- (IBAction)clearButtonTapped:(id)sender {
    imageView.image = [mask cutoutWithImage:image resize:false];
}

- (IBAction)grayScaleButtonTapped:(id)sender {
    // Create a mask image from mask array
    CIImage *maskImage = [[CIImage alloc] initWithImage:[mask rgbaImage]];
    CIImage *ciImage = [[CIImage alloc] initWithImage:image];
    
    // Use color filter to create a gray scale image
    CIFilter *colorFilter = [CIFilter filterWithName:@"CIColorControls"];
    [colorFilter setValue:ciImage forKey:kCIInputImageKey];
    [colorFilter setValue:0 forKey:kCIInputSaturationKey];
    
    // Use blend filter to blend color image and gray scale image using mask
    CIFilter *blendFilter = [CIFilter filterWithName:@"CIBlendWithAlphaMask"];
    [blendFilter setValue:ciImage forKey:kCIInputImageKey];
    [blendFilter setValue:colorFilter.outputImage forKey:kCIInputBackgroundImageKey];
    [blendFilter setValue:maskImage forKey:kCIInputMaskImageKey];
    
    // Get the output result
    CIImage *result = blendFilter.outputImage;
    UIImage *outputImage = [[UIImage alloc] initWithCIImage:result];
    
    imageView.image = outputImage;
}
@end


@implementation UIImage (SolidColorImage)

// create a UIImage with solid color
- (id)initWithUIColor:(UIColor*)color size:(CGSize)size {
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    UIGraphicsBeginImageContextWithOptions(rect.size, false, 1.0);
    [color setFill];
    UIRectFill(rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    if (image.CGImage == nil) {
        return nil;
    }
    return [self initWithCGImage:image.CGImage];
}
@end
