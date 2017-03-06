//
//  ViewController.m
//  TCMaskPopView
//
//  Created by Xin Zeng on 2/7/17.
//  Copyright © 2017 TinyCrayon. All rights reserved.
//

#import "ViewController.h"
@import TCMask;

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (_imageView.image == nil) {
        [self presentTCMaskView];
    }
}

- (IBAction)editButtonTapped:(id)sender {
    [self presentTCMaskView];
}

- (void)presentTCMaskView {
    UIImage *image = [UIImage imageNamed:@"Balloon.JPEG"];
    TCMaskView *maskView = [[TCMaskView alloc] initWithImage:image];
    maskView.delegate = self;
    [maskView presentFromRootViewController:self animated:true];
}

- (void)tcMaskViewDidCompleteWithMask:(TCMask *)mask image:(UIImage *)image {
    _imageView.image = [mask cutoutWithImage:image resize:true];
}

@end
