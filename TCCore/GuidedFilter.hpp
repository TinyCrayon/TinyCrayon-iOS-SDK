//
//  GuidedFilter.hpp
//  GeodesicMatting
//
//  Created by Xin Zeng on 5/4/16.
//  Copyright © 2016 Xin Zeng. All rights reserved.
//

#ifndef GuidedFilter_hpp
#define GuidedFilter_hpp

#include <stdio.h>
#include <opencv2/opencv.hpp>

class GuidedFilterImpl;

class GuidedFilter
{
public:
    GuidedFilter(const cv::Mat &I, int r, double eps);
    ~GuidedFilter();
    
    cv::Mat filter(const cv::Mat &p, int depth = -1) const;
    
private:
    GuidedFilterImpl *impl_;
};

cv::Mat guidedFilter(const cv::Mat &I, const cv::Mat &p, int r, double eps, cv::Rect rect);

#endif /* GuidedFilter_hpp */
