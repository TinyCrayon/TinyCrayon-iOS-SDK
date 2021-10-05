//
//  PaintSelect.cpp
//  TinyCrayon
//
//  Created by Xin Zeng on 11/12/15.
//  Copyright © 2015 Xin Zeng. All rights reserved.
//

#include "PaintSelect.hpp"
#include "QuickGraphCut.hpp"
#include "GlobalMatting.hpp"

void cleanupSelect(const Mat &mask, const Mat &region, Mat &result, int mode) {
    const int cols = result.cols;
    const int rows = result.rows;
    Mat visited(rows, cols, CV_8UC1);
    std::deque<cv::Point> queue;
    Point p;
    
    visited.setTo(0);
    
    for (p.y = 0; p.y < rows; p.y++) {
        for (p.x = 0; p.x < cols; p.x++) {
            if (region.at<uchar>(p) != GC_UNINIT) {
                // If region has initlized value, set it
                result.at<uchar>(p) = region.at<uchar>(p);
                
                if ((mode == GC_MODE_FGD && GC_IS_BGD(mask.at<uchar>(p))) ||
                    (mode == GC_MODE_BGD && GC_IS_FGD(mask.at<uchar>(p)))) {
                    queue.push_back(p);
                    visited.at<uchar>(p) = true;
                }
            }
        }
    }
    
    // Use BFS to traverse from seed ponts
    while (!queue.empty()) {
        p = queue.front();
        queue.pop_front();
        
        Point neighbours[] = {Point(p.x - 1, p.y), Point(p.x + 1, p.y), Point(p.x, p.y - 1), Point(p.x, p.y + 1)};
        
        for (Point &q : neighbours) {
            if (q.x < 0 || q.x >= cols || q.y < 0 || q.y >= rows)
                continue;
            
            if (visited.at<uchar>(q))
                continue;
            
            if (((mode == GC_MODE_FGD && GC_IS_FGD(result.at<uchar>(q))) ||
                 (mode == GC_MODE_BGD && GC_IS_BGD(result.at<uchar>(q)))) &&
                GC_LABEL_CHANGED(mask.at<uchar>(q), result.at<uchar>(q))) {
                visited.at<uchar>(q) = true;
                queue.push_back(q);
            }
        }
    }
    
    for (p.y = 0; p.y < rows; p.y++) {
        for (p.x = 0; p.x < cols; p.x++) {
            if (region.at<uchar>(p) != GC_UNINIT) {
                assert(result.at<uchar>(p) == region.at<uchar>(p));
                continue;
            }
            // region.at<uchar>(p) == GC_UNINIT
            else if (mask.at<uchar>(p) == GC_MASK_FGD || mask.at<uchar>(p) == GC_MASK_BGD) {
                // If mask is a definite foregound or background value, preserve it in result
                result.at<uchar>(p) = mask.at<uchar>(p);
                continue;
            }
            else if (result.at<uchar>(p) == GC_MASK_FGD && mask.at<uchar>(p) != GC_MASK_FGD) {
                // If result is definite foreground while mask is not, set it to probalbly foreground
                // (this may happen due to resize)
                result.at<uchar>(p) = GC_MASK_PR_FGD;
            }
            else if (result.at<uchar>(p) == GC_MASK_BGD && mask.at<uchar>(p) != GC_MASK_BGD) {
                // If result is definite background while mask is not, set it to probalbly background
                // (this may happen due to resize)
                result.at<uchar>(p) = GC_MASK_PR_BGD;
            }
            
            if (mode == GC_MODE_FGD &&
                GC_IS_BGD(result.at<uchar>(p)) &&
                GC_IS_FGD(mask.at<uchar>(p)))
            {
                // If we are in foreground selection mode, make sure we don't set any previous fourground pixel to background
                result.at<uchar>(p) = mask.at<uchar>(p);
            }
            else if (mode == GC_MODE_BGD &&
                     GC_IS_FGD(result.at<uchar>(p)) &&
                     GC_IS_BGD(mask.at<uchar>(p)))
            {
                // If we are in background selection mode, make sure we don't set any previous background pixel to foreground
                result.at<uchar>(p) = mask.at<uchar>(p);
            }
            else if (!visited.at<uchar>(p)) {
                // If pixel is not visited, preserve mask value
                result.at<uchar>(p) = mask.at<uchar>(p);
            }
            else if (GC_IS_PASS_THROUGH(result.at<uchar>(p))) {
                assert(false);
            }
        }
    }
}

bool graphCutSelect(const Mat &img, const Mat &mask, const Mat &region, Mat &result, int mode) {
    const int iterCount = 3;
    const int cols = img.cols;
    const int rows = img.rows;
    Point p;
    std::deque<cv::Point> queue;
    Mat visited(rows, cols, CV_8UC1);
    visited.setTo(0);
    
    result.create(img.size(), CV_8UC1);

    for (p.y = 0; p.y < rows; p.y++) {
        for (p.x = 0; p.x < cols; p.x++) {
            if (region.at<uchar>(p) != GC_UNINIT)
            {
                // If point at region is active, set it to region value
                result.at<uchar>(p) = GC_DEFINITE_VALUE(region.at<uchar>(p));
                
                if ((mode == GC_MODE_FGD && GC_IS_BGD(mask.at<uchar>(p))) ||
                    (mode == GC_MODE_BGD && GC_IS_FGD(mask.at<uchar>(p))))
                {
                    queue.push_back(p);
                    visited.at<uchar>(p) = true;
                }
            }
            else if (mode == GC_MODE_FGD && mask.at<uchar>(p) == GC_MASK_PR_FGD) {
                result.at<uchar>(p) = GC_PASS_THROUGH_PR_FGD;
            }
            else if (mode == GC_MODE_BGD && mask.at<uchar>(p) == GC_MASK_PR_BGD) {
                result.at<uchar>(p) = GC_PASS_THROUGH_PR_BGD;
            }
            else {
                result.at<uchar>(p) = mask.at<uchar>(p);
            }
        }
    }
    
    // Use BFS to traverse from seed ponts
    while (!queue.empty()) {
        p = queue.front();
        queue.pop_front();
        
        Point neighbours[] = {Point(p.x - 1, p.y), Point(p.x + 1, p.y), Point(p.x, p.y - 1), Point(p.x, p.y + 1)};
        
        for (Point &q : neighbours) {
            if (q.x < 0 || q.x >= cols || q.y < 0 || q.y >= rows)
                continue;
            
            if (visited.at<uchar>(q))
                continue;
            
            if (result.at<uchar>(q) == GC_MASK_PR_BGD || result.at<uchar>(q) == GC_MASK_PR_FGD) {
                queue.push_back(q);
            }
            
            visited.at<uchar>(q) = true;
        }
    }
    
    // Pass through pixels which has probal value and is not visited
    for (p.y = 0; p.y < rows; p.y++) {
        for (p.x = 0; p.x < cols; p.x++) {
            if (!visited.at<uchar>(p))
            {
                bis(result.at<uchar>(p), GC_FLAG_PASS);
            }
        }
    }
    
    // GrabCut segmentation
    if (!quickGraphCut(img,         // input image
                       result,      // segmentation result
                       iterCount))  // number of iterations
    {
        return false;
    }
    
    return true;
}

void paintSelectHelper(const Mat &img, const Mat &mask, const Mat &region, Mat &result, int mode, Mat &resizedMask, Mat &resizedResult) {
    const int iterCount = 3;
    Point p;
    std::vector<cv::Point> protectList;
    Mat boundary;
    
    boundary.create(resizedMask.size(), CV_8UC1);
    
    for (p.y = 0; p.y < resizedResult.rows; p.y++) {
        for (p.x = 0; p.x < resizedResult.cols; p.x++)
        {
            boundary.at<uchar>(p) = resizedResult.at<uchar>(p) | GC_FLAG_PASS;
            
            Point neighbours[] = {Point(p.x - 1, p.y), Point(p.x + 1, p.y), Point(p.x, p.y - 1), Point(p.x, p.y + 1)};
            for (Point &q : neighbours) {
                if (q.x < 0 || q.x >= resizedResult.cols || q.y < 0 || q.y >= resizedResult.rows)
                    continue;
                
                // If p is in boundary
                if (GC_LABEL_CHANGED(resizedResult.at<uchar>(p), resizedResult.at<uchar>(q))) {
                    
                    // If p, q is a previous boundary, add p to protect list
                    if (!GC_LABEL_CHANGED(resizedResult.at<uchar>(p), resizedMask.at<uchar>(p)) &&
                        !GC_LABEL_CHANGED(resizedResult.at<uchar>(q), resizedMask.at<uchar>(q)))
                    {
                        protectList.push_back(p);
                        continue;
                    }
                    // else if p, q is a new boundary, set boundary value
                    else if (GC_IS_FGD(resizedResult.at<uchar>(p)))
                        boundary.at<uchar>(p) = GC_MASK_PR_FGD;
                    else
                        boundary.at<uchar>(p) = GC_MASK_PR_BGD;
                    
                    break;
                }
            }
        }
    }
    
    for (int i = 0; i < protectList.size(); i++) {
        p = protectList[i];
        // protect bounday which does not change
        if (GC_IS_PASS_THROUGH(boundary.at<uchar>(p))) {
            resizedResult.at<uchar>(p) = mode == GC_MODE_FGD ? GC_MASK_PR_BGD : GC_MASK_PR_FGD;
        }
    }
    
    for (p.y = 0; p.y < resizedResult.rows; p.y++) {
        for (p.x = 0; p.x < resizedResult.cols; p.x++)
        {
            if (!GC_IS_PASS_THROUGH(boundary.at<uchar>(p)))
                continue;
            
            Point neighbours[] = {Point(p.x - 1, p.y), Point(p.x + 1, p.y), Point(p.x, p.y - 1), Point(p.x, p.y + 1)};
            for (Point &q : neighbours) {
                if (q.x < 0 || q.x >= boundary.cols || q.y < 0 || q.y >= boundary.rows)
                    continue;
                
                if (boundary.at<uchar>(q) == GC_MASK_PR_FGD) {
                    boundary.at<uchar>(p) = GC_MASK_FGD;
                }
                else if (boundary.at<uchar>(q) == GC_MASK_PR_BGD) {
                    boundary.at<uchar>(p) = GC_MASK_BGD;
                }
            }
        }
    }
    
    resize(boundary, boundary, result.size(), 0, 0, INTER_NEAREST);
    resize(resizedResult, result, result.size(), 0, 0, INTER_NEAREST);
    
    quickGraphCut(img,  // input image
                  boundary, // segmentation result
                  iterCount);  // number of iterations
    
    for (p.y = 0; p.y < boundary.rows; p.y++) {
        for (p.x = 0; p.x < boundary.cols; p.x++) {
            if (!GC_IS_PASS_THROUGH(boundary.at<uchar>(p)) &&
                boundary.at<uchar>(p) != GC_MASK_FGD &&
                boundary.at<uchar>(p) != GC_MASK_BGD)
            {
                result.at<uchar>(p) = boundary.at<uchar>(p);
            }
        }
    }
    
    cleanupSelect(mask, region, result, mode);
}

void paintSelect(const Mat &img, const Mat &mask, const Mat &region, Mat &result, int mode) {
    cv::Rect rectangle(0,0,0,0);
    const int sizeLimit1 = 160;
    const int sizeLimit2 = 640;
    
    Point p;
    Mat resizedImg;
    Mat resizedMask;
    Mat resizedRegion;
    Mat resizedResult;
    float factor;

    if (img.cols <= sizeLimit1 * 2 && img.rows <= sizeLimit1 * 2) {
        graphCutSelect(img, mask, region, result, mode);
        cleanupSelect(mask, region, result, mode);
        return;
    }
    
    factor = MAX(img.cols / sizeLimit1, img.rows / sizeLimit1);
    resize(img, resizedImg, cv::Size(), 1.0/factor, 1.0/factor);
    resize(mask, resizedMask, resizedImg.size(), 0, 0, INTER_NEAREST);
    resize(region, resizedRegion, resizedImg.size(), 0, 0, INTER_NEAREST);

    // If graphcut is not successful, just do a simple copy of mask and region to result
    if (!graphCutSelect(resizedImg, resizedMask, resizedRegion, resizedResult, mode))
    {
        for (p.y = 0; p.y < img.rows; p.y++) {
            for (p.x = 0; p.x < img.cols; p.x++) {
                if (region.at<uchar>(p) != GC_UNINIT)
                    result.at<uchar>(p) = region.at<uchar>(p);
                else
                    result.at<uchar>(p) = mask.at<uchar>(p);
            }
        }
        return;
    }
    cleanupSelect(resizedMask, resizedRegion, resizedResult, mode);
    
    if (img.cols > sizeLimit2 * 2 || img.rows > sizeLimit2 * 2) {
        Mat tmpMask = resizedMask.clone();
        Mat tmpResult = resizedResult.clone();
        
        factor = MAX(img.cols / sizeLimit2, img.rows / sizeLimit2);
        resize(img, resizedImg, cv::Size(), 1.0/factor, 1.0/factor);
        resize(mask, resizedMask, resizedImg.size(), 0, 0, INTER_NEAREST);
        resize(region, resizedRegion, resizedImg.size(), 0, 0, INTER_NEAREST);
        resizedResult.create(resizedImg.size(), CV_8UC1);
        
        paintSelectHelper(resizedImg, resizedMask, resizedRegion, resizedResult, mode, tmpMask, tmpResult);
    }

    paintSelectHelper(img, mask, region, result, mode, resizedMask, resizedResult);
}
