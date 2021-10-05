//
//  GlobalMatting.hpp
//  BokehEffect
//
//  Created by Xin Zeng on 12/4/15.
//  Copyright © 2015 Xin Zeng. All rights reserved.
//

#ifndef GlobalMatting_hpp
#define GlobalMatting_hpp

#import <opencv2/opencv.hpp>
#include <stdio.h>

void expansionOfKnownRegions(cv::InputArray img, cv::InputOutputArray trimap, int niter = 9);

void globalMatting(const cv::Mat &image, const cv::Mat &trimap, cv::Mat &alpha, cv::Rect rect);

#endif /* GlobalMatting_hpp */
