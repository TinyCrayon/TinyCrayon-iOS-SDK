//
//  QuickGraphCut.hpp
//  TinyCrayon
//
//  Created by Xin Zeng on 11/14/15.
//  Copyright © 2015 Xin Zeng. All rights reserved.
//

#ifndef QuickGraphCut_hpp
#define QuickGraphCut_hpp

#import <opencv2/opencv.hpp>
#import <opencv2/imgproc/imgproc_c.h>
#include <stdio.h>

#include "FGMM.hpp"
#include "FGCGraph.hpp"

using namespace cv;

bool quickGraphCut(const Mat &img, Mat &mask, int iterCount);

#endif /* QuickGraphCut_hpp */
