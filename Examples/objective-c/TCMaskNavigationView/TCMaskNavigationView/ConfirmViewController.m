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

#import "ConfirmViewController.h"

@interface ConfirmViewController ()

@end

@implementation ConfirmViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    imageView.image = _image;
    CGFloat x, y, width, height;
    if (_image.size.width > _image.size.height) {
        width = self.view.frame.size.width;
        height = width * _image.size.height / _image.size.width;
        x = 0;
        y = (width - height) / 2;
    }
    else {
        height = self.view.frame.size.width;
        width = height * _image.size.width / _image.size.height;
        x = (height - width) / 2;
        y = 0;
    }
    imageView.frame = CGRectMake(x, y, width, height);
}

- (IBAction)doneButtonTapped:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:true];
}


@end
