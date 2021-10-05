//
//  GrabCut.hpp
//  TinyCrayon
//
//  Created by Xin Zeng on 11/12/15.
//  Copyright © 2015 Xin Zeng. All rights reserved.
//

#ifndef PaintSelect_hpp
#define PaintSelect_hpp

#import <opencv2/opencv.hpp>

#include <stdio.h>
#include "OpenCVLibs0.h"

using namespace cv;

void paintSelect(const Mat &img, const Mat &mask, const Mat &region, Mat &result, int mode);

#endif /* PaintSelect_hpp */
