//
//  QuickGraphCut.cpp
//  TinyCrayon
//
//  Created by Xin Zeng on 11/14/15.
//  Copyright © 2015 Xin Zeng. All rights reserved.
//

#include "QuickGraphCut.hpp"
#include "TCCoreLibs0.h"
#include <limits>
#include <ctime>
#include <math.h>

/*
 Calculate beta - parameter of GrabCut algorithm.
 beta = 1/(2*avg(sqr(||color[i] - color[j]||)))
 */
static double calcBeta( const Mat& img )
{
    double beta = 0;
    for( int y = 0; y < img.rows; y++ )
    {
        for( int x = 0; x < img.cols; x++ )
        {
            Vec3d color = RGB_VAL(img, y, x);
            if( x>0 ) // left
            {
                Vec3d diff = color - (Vec3d)RGB_VAL(img, y, x-1);
                beta += diff.dot(diff);
            }
            if( y>0 && x>0 ) // upleft
            {
                Vec3d diff = color - (Vec3d)RGB_VAL(img, y-1, x-1);
                beta += diff.dot(diff);
            }
            if( y>0 ) // up
            {
                Vec3d diff = color - (Vec3d)RGB_VAL(img, y-1, x);
                beta += diff.dot(diff);
            }
            if( y>0 && x<img.cols-1) // upright
            {
                Vec3d diff = color - (Vec3d)RGB_VAL(img, y-1, x+1);
                beta += diff.dot(diff);
            }
        }
    }
    if( beta <= std::numeric_limits<double>::epsilon() )
        beta = 0;
    else
        beta = 1.f / (2 * beta/(4*img.cols*img.rows - 3*img.cols - 3*img.rows + 2) );
    
    return beta;
}

/*
 Calculate weights of noterminal vertices of graph.
 beta and gamma - parameters of GrabCut algorithm.
 */
static void calcNWeights(const Mat& img, double *leftW, double *upleftW, double *upW, double *uprightW, double beta, double gamma, int *indexes, int numOfNodes)
{
    const double gammaDivSqrt2 = gamma / std::sqrt(2.0f);
    
    for (int i=0; i < numOfNodes; i++) {
        int y = indexes[i] / img.cols;
        int x = indexes[i] % img.cols;
        Vec3d color = RGB_VAL(img, y, x);
        if( x-1>=0 ) // left
        {
            Vec3d diff = color - (Vec3d)RGB_VAL(img, y, x-1);
            leftW[i] = gamma * exp(-beta*diff.dot(diff));
        }
        else
            leftW[i] = 0;
        if( x-1>=0 && y-1>=0 ) // upleft
        {
            Vec3d diff = color - (Vec3d)RGB_VAL(img, y-1, x-1);
            upleftW[i] = gammaDivSqrt2 * exp(-beta*diff.dot(diff));
        }
        else
            upleftW[i] = 0;
        if( y-1>=0 ) // up
        {
            Vec3d diff = color - (Vec3d)RGB_VAL(img, y-1, x);
            upW[i] = gamma * exp(-beta*diff.dot(diff));
        }
        else
            upW[i] = 0;
        if( x+1<img.cols && y-1>=0 ) // upright
        {
            Vec3d diff = color - (Vec3d)RGB_VAL(img, y-1, x+1);
            uprightW[i] = gammaDivSqrt2 * exp(-beta*diff.dot(diff));
        }
        else
            uprightW[i] = 0;
    }
}

/*
 Check size, type and element values of mask matrix.
 */
static void checkMask( const Mat& img, const Mat& mask )
{
    if( mask.empty() )
        CV_Error( CV_StsBadArg, "mask is empty" );
    if( mask.type() != CV_8UC1 )
        CV_Error( CV_StsBadArg, "mask must have CV_8UC1 type" );
    if( mask.cols != img.cols || mask.rows != img.rows )
        CV_Error( CV_StsBadArg, "mask must have as many rows and cols as img" );
    for( int y = 0; y < mask.rows; y++ )
    {
        for( int x = 0; x < mask.cols; x++ )
        {
            uchar val = mask.at<uchar>(y,x);
            if (bit(val, 0xF0))
            {
                printf("val:%d x:%d y:%d\n", val, x, y);
                CV_Error( CV_StsBadArg, "mask element value must be equel"
                         "GC_MASK_BGD or GC_MASK_FGD or GC_MASK_PR_BGD or GC_MASK_PR_FGD or GC_PASS_THROUGH" );
            }
        }
    }
}

/*
 Initialize GMM background and foreground models using kmeans algorithm.
 */
static int initGMMs( const Mat& img, const Mat& mask, FGMM& bgdGMM, FGMM& fgdGMM )
{
    const int kMeansItCount = 10;
    const int kMeansType = KMEANS_PP_CENTERS;
    
    Mat bgdLabels, fgdLabels;
    std::vector<Vec3f> bgdSamples, fgdSamples;
    Point p;
    for( p.y = 0; p.y < img.rows; p.y++ )
    {
        for( p.x = 0; p.x < img.cols; p.x++ )
        {
            if( mask.at<uchar>(p) == GC_MASK_BGD || mask.at<uchar>(p) == GC_MASK_PR_BGD )
                bgdSamples.push_back( (Vec3f)RGB_VALP(img, p) );
            else if (mask.at<uchar>(p) == GC_MASK_FGD || mask.at<uchar>(p) == GC_MASK_PR_FGD )
                fgdSamples.push_back( (Vec3f)RGB_VALP(img, p) );
            else
                assert(GC_IS_PASS_THROUGH(mask.at<uchar>(p)));
        }
    }
    if (bgdSamples.size() < FGMM::componentsCount || fgdSamples.size() < FGMM::componentsCount)
        return 0;
        
    Mat _bgdSamples( (int)bgdSamples.size(), 3, CV_32FC1, &bgdSamples[0][0] );
    kmeans( _bgdSamples, FGMM::componentsCount, bgdLabels,
           TermCriteria( CV_TERMCRIT_ITER, kMeansItCount, 0.0), 0, kMeansType );
    Mat _fgdSamples( (int)fgdSamples.size(), 3, CV_32FC1, &fgdSamples[0][0] );
    kmeans( _fgdSamples, FGMM::componentsCount, fgdLabels,
           TermCriteria( CV_TERMCRIT_ITER, kMeansItCount, 0.0), 0, kMeansType );
    
    bgdGMM.initLearning();
    for( int i = 0; i < (int)bgdSamples.size(); i++ )
        bgdGMM.addSample( bgdLabels.at<int>(i,0), bgdSamples[i] );
    bgdGMM.endLearning();
    
    fgdGMM.initLearning();
    for( int i = 0; i < (int)fgdSamples.size(); i++ )
        fgdGMM.addSample( fgdLabels.at<int>(i,0), fgdSamples[i] );
    fgdGMM.endLearning();
    
    return (int)bgdSamples.size() + (int)fgdSamples.size();
}

/*
 Assign GMMs components for each pixel.
 */
static void assignGMMsComponents( const Mat& img, const Mat& mask, const FGMM& bgdGMM, const FGMM& fgdGMM, int *indexes, int *compIdxs, int numOfNodes)
{
    Point p;
    for (int i=0; i < numOfNodes; i++) {
        p.x = indexes[i] % img.cols;
        p.y = indexes[i] / img.cols;
        
        Vec3d color = RGB_VALP(img, p);
        compIdxs[i] = mask.at<uchar>(p) == GC_MASK_BGD || mask.at<uchar>(p) == GC_MASK_PR_BGD ?
        bgdGMM.whichComponent(color) : fgdGMM.whichComponent(color);
    }
}

/*
 Learn GMMs parameters.
 */
static void learnGMMs( const Mat& img, const Mat& mask, int *compIdxs, FGMM& bgdGMM, FGMM& fgdGMM, int *indexes, int numOfNodes)
{
    bgdGMM.initLearning();
    fgdGMM.initLearning();
    Point p;
    for( int ci = 0; ci < FGMM::componentsCount; ci++ )
    {
        for (int i=0; i < numOfNodes; i++) {
            p.x = indexes[i] % img.cols;
            p.y = indexes[i] / img.cols;
            
            if( compIdxs[i] == ci )
            {
                if( mask.at<uchar>(p) == GC_MASK_BGD || mask.at<uchar>(p) == GC_MASK_PR_BGD )
                    bgdGMM.addSample( ci, RGB_VALP(img, p) );
                else if( mask.at<uchar>(p) == GC_MASK_FGD || mask.at<uchar>(p) == GC_MASK_PR_FGD )
                    fgdGMM.addSample( ci, RGB_VALP(img, p) );
            }
        }
    }
    bgdGMM.endLearning();
    fgdGMM.endLearning();
}

/*
 Construct GCGraph
 */
static void constructGCGraph( const Mat& img, const Mat& mask, const FGMM& bgdGMM, const FGMM& fgdGMM, double lambda, double *leftW, double *upleftW, double *upW, double *uprightW, FGCGraph<double>& graph, int *indexes, int numOfNodes)
{
    int sideLength = sqrt(numOfNodes) + 1;
    int edgeCount = 2*(4 * sideLength * sideLength - 3 * 2 * sideLength + 2);
    graph.create(numOfNodes, edgeCount);
    Point p;
    
    Mat vtxMap = Mat(img.rows, img.cols, CV_32SC1);
    
    vtxMap.setTo(-1);
    
    for (int i=0; i < numOfNodes; i++) {
        p.x = indexes[i] % img.cols;
        p.y = indexes[i] / img.cols;
        
        // add node
        int vtxIdx = graph.addVtx();
        Vec3b color = RGB_VALP(img, p);
        
        vtxMap.at<int>(p) = vtxIdx;
        
        // set t-weights
        double fromSource = 0;
        double toSink = 0;
        if( mask.at<uchar>(p) == GC_MASK_PR_BGD || mask.at<uchar>(p) == GC_MASK_PR_FGD )
        {
            fromSource = -log( bgdGMM(color) );
            toSink = -log( fgdGMM(color) );
        }
        else if( mask.at<uchar>(p) == GC_MASK_BGD )
        {
            toSink = lambda;
        }
        else if( mask.at<uchar>(p) == GC_MASK_FGD )
        {
            fromSource = lambda;
        }
        graph.addTermWeights( vtxIdx, fromSource, toSink);
        
        // set n-weights
        if (p.x>0 && vtxMap.at<int>(Point(p.x - 1, p.y)) >= 0)
        {
            double w = leftW[i];
            graph.addEdges( vtxIdx, vtxMap.at<int>(Point(p.x - 1, p.y)), w, w );
        }
        if (p.x>0 && p.y>0 && vtxMap.at<int>(Point(p.x - 1, p.y - 1)) >= 0)
        {
            double w = upleftW[i];
            graph.addEdges( vtxIdx, vtxMap.at<int>(Point(p.x - 1, p.y - 1)), w, w );
        }
        if (p.y>0 && vtxMap.at<int>(Point(p.x, p.y - 1)) >= 0)
        {
            double w = upW[i];
            graph.addEdges( vtxIdx, vtxMap.at<int>(Point(p.x, p.y - 1)), w, w );
        }
        if (p.x<img.cols-1 && p.y>0 && vtxMap.at<int>(Point(p.x + 1, p.y - 1)) >= 0)
        {
            double w = uprightW[i];
            graph.addEdges( vtxIdx, vtxMap.at<int>(Point(p.x + 1, p.y - 1)), w, w );
        }
    }
}

/*
 Estimate segmentation using MaxFlow algorithm
 */
static void estimateSegmentation( FGCGraph<double>& graph, Mat& mask, int *indexes, int numOfNodes)
{
    graph.maxFlow();
    Point p;
    
    for (int i=0; i < numOfNodes; i++) {
        p.x = indexes[i] % mask.cols;
        p.y = indexes[i] / mask.cols;

        if (mask.at<uchar>(p) == GC_MASK_PR_BGD || mask.at<uchar>(p) == GC_MASK_PR_FGD)
        {
            if( graph.inSourceSegment(i /*vertex index*/))
                mask.at<uchar>(p) = GC_MASK_PR_FGD;
            else
                mask.at<uchar>(p) = GC_MASK_PR_BGD;
        }
    }
}

static void buildNodeIndex(const Mat &mask, int *index, int numOfNodes) {
    for (int i = 0, j = 0; i < mask.rows * mask.cols; i++) {
        if (!GC_IS_PASS_THROUGH(mask.data[i])) {
            index[j++] = i;
        }
    }
}

cv::Mat bgModel,fgModel; // the models (internally used)
bool quickGraphCut(const Mat &img, Mat &mask, int iterCount)
{
    if( img.empty() )
        CV_Error( CV_StsBadArg, "image is empty" );
    if( img.type() != CV_8UC4 )
        CV_Error( CV_StsBadArg, "image must have CV_8UC4 type" );
    
    FGMM bgdGMM( bgModel ), fgdGMM( fgModel );
    
    checkMask( img, mask );
    
    int numOfNodes = initGMMs( img, mask, bgdGMM, fgdGMM);
    
    if (numOfNodes == 0)
        return false;
    
    if( iterCount <= 0)
        return false;
    
    const double gamma = 50;
    const double lambda = 9*gamma;
    const double beta = calcBeta( img );
    
    int *indexes = new int[numOfNodes];
    buildNodeIndex(mask, indexes, numOfNodes);

    double *leftW    = new double[numOfNodes];
    double *upleftW  = new double[numOfNodes];
    double *upW      = new double[numOfNodes];
    double *uprightW = new double[numOfNodes];
    
    calcNWeights( img, leftW, upleftW, upW, uprightW, beta, gamma, indexes, numOfNodes);
    
    int *compIdxs = new int[numOfNodes];
    
    for( int i = 0; i < iterCount; i++ )
    {
        FGCGraph<double> graph;
        assignGMMsComponents( img, mask, bgdGMM, fgdGMM, indexes, compIdxs, numOfNodes);
        learnGMMs( img, mask, compIdxs, bgdGMM, fgdGMM, indexes, numOfNodes);
        constructGCGraph(img, mask, bgdGMM, fgdGMM, lambda, leftW, upleftW, upW, uprightW, graph, indexes, numOfNodes);
        estimateSegmentation( graph, mask, indexes, numOfNodes);
    }
    
    delete [] indexes;
    delete [] leftW;
    delete [] upleftW;
    delete [] upW;
    delete [] uprightW;
    delete [] compIdxs;
    
    return true;
}
