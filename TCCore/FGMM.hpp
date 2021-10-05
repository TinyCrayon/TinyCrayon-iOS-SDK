//
//  FGMM.hpp
//  TinyCrayon
//
//  Created by Xin Zeng on 11/15/15.
//  Copyright © 2015 Xin Zeng. All rights reserved.
//

#ifndef FGMM_hpp
#define FGMM_hpp

#import <opencv2/opencv.hpp>
#include <stdio.h>

using namespace cv;

/*
 FGMM - Fast Gaussian Mixture Model
 */
class FGMM
{
public:
    static const int componentsCount = 5;
    
    FGMM( Mat& _model );
    double operator()( const Vec3d color ) const;
    double operator()( int ci, const Vec3d color ) const;
    int whichComponent( const Vec3d color ) const;
    
    void initLearning();
    void addSample( int ci, const Vec3d color );
    void endLearning();
    
private:
    void calcInverseCovAndDeterm( int ci );
    Mat model;
    double* coefs;
    double* mean;
    double* cov;
    
    double inverseCovs[componentsCount][3][3];
    double covDeterms[componentsCount];
    
    double sums[componentsCount][3];
    double prods[componentsCount][3][3];
    int sampleCounts[componentsCount];
    int totalSampleCount;
};

#endif /* FGMM_hpp */
