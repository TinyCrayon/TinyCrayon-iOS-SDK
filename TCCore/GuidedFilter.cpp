//
//  GuidedFilter.cpp
//  GeodesicMatting
//
//  Created by Xin Zeng on 5/4/16.
//  Copyright © 2016 Xin Zeng. All rights reserved.
//

#include "OpenCVLibs0.h"
#include "GuidedFilter.hpp"

static cv::Mat boxfilter(const cv::Mat &I, int r)
{
    cv::Mat result;
    cv::blur(I, result, cv::Size(r, r));
    return result;
}

static cv::Mat convertTo(const cv::Mat &mat, int depth)
{
    if (mat.depth() == depth)
        return mat;
    
    cv::Mat result;
    mat.convertTo(result, depth);
    return result;
}

class GuidedFilterImpl
{
public:
    virtual ~GuidedFilterImpl() {}
    
    cv::Mat filter(const cv::Mat &p, int depth);
    
protected:
    int Idepth;
    
private:
    virtual cv::Mat filterSingleChannel(const cv::Mat &p) const = 0;
};

class GuidedFilterMono : public GuidedFilterImpl
{
public:
    GuidedFilterMono(const cv::Mat &I, int r, double eps);
    
private:
    virtual cv::Mat filterSingleChannel(const cv::Mat &p) const;
    
private:
    int r;
    double eps;
    cv::Mat I, mean_I, var_I;
};

class GuidedFilterColor : public GuidedFilterImpl
{
public:
    GuidedFilterColor(const cv::Mat &I, int r, double eps);
    
private:
    virtual cv::Mat filterSingleChannel(const cv::Mat &p) const;
    
private:
    std::vector<cv::Mat> Ichannels;
    cv::Mat rchannel;
    cv::Mat gchannel;
    cv::Mat bchannel;
    int r;
    double eps;
    cv::Mat mean_I_r, mean_I_g, mean_I_b;
    cv::Mat invrr, invrg, invrb, invgg, invgb, invbb;
};


cv::Mat GuidedFilterImpl::filter(const cv::Mat &p, int depth)
{
    cv::Mat p2 = convertTo(p, Idepth);
    
    cv::Mat result;
    if (p.channels() == 1)
    {
        result = filterSingleChannel(p2);
    }
    else
    {
        std::vector<cv::Mat> pc;
        cv::split(p2, pc);
        
        for (std::size_t i = 0; i < pc.size(); ++i)
            pc[i] = filterSingleChannel(pc[i]);
        
        cv::merge(pc, result);
    }
    
    return convertTo(result, depth == -1 ? p.depth() : depth);
}

GuidedFilterMono::GuidedFilterMono(const cv::Mat &origI, int r, double eps) : r(r), eps(eps)
{
    if (origI.depth() == CV_32F || origI.depth() == CV_64F)
        I = origI.clone();
    else
        I = convertTo(origI, CV_32F);
    
    Idepth = I.depth();
    
    mean_I = boxfilter(I, r);
    cv::Mat mean_II = boxfilter(I.mul(I), r);
    var_I = mean_II - mean_I.mul(mean_I);
}

cv::Mat GuidedFilterMono::filterSingleChannel(const cv::Mat &p) const
{
    cv::Mat mean_p = boxfilter(p, r);
    cv::Mat mean_Ip = boxfilter(I.mul(p), r);
    cv::Mat cov_Ip = mean_Ip - mean_I.mul(mean_p); // this is the covariance of (I, p) in each local patch.
    
    cv::Mat a = cov_Ip / (var_I + eps); // Eqn. (5) in the paper;
    cv::Mat b = mean_p - a.mul(mean_I); // Eqn. (6) in the paper;
    
    cv::Mat mean_a = boxfilter(a, r);
    cv::Mat mean_b = boxfilter(b, r);
    
    return mean_a.mul(I) + mean_b;
}

GuidedFilterColor::GuidedFilterColor(const cv::Mat &origI, int r, double eps) : r(r), eps(eps)
{
    cv::Mat I;
    if (origI.depth() == CV_32F || origI.depth() == CV_64F)
        I = origI.clone();
    else
        I = convertTo(origI, CV_32F);
    
    Idepth = I.depth();
    
    cv::split(I, Ichannels);
    
    if (DEVICE_COLOR_SPACE == TC_RGBA) {
        rchannel = Ichannels[0];
        gchannel = Ichannels[1];
        bchannel = Ichannels[2];
    }
    else {
        rchannel = Ichannels[1];
        gchannel = Ichannels[2];
        bchannel = Ichannels[3];
    }
    
    mean_I_r = boxfilter(rchannel, r);
    mean_I_g = boxfilter(gchannel, r);
    mean_I_b = boxfilter(bchannel, r);
    
    // variance of I in each local patch: the matrix Sigma in Eqn (14).
    // Note the variance in each local patch is a 3x3 symmetric matrix:
    //           rr, rg, rb
    //   Sigma = rg, gg, gb
    //           rb, gb, bb
    cv::Mat var_I_rr = boxfilter(rchannel.mul(rchannel), r) - mean_I_r.mul(mean_I_r) + eps;
    cv::Mat var_I_rg = boxfilter(rchannel.mul(gchannel), r) - mean_I_r.mul(mean_I_g);
    cv::Mat var_I_rb = boxfilter(rchannel.mul(bchannel), r) - mean_I_r.mul(mean_I_b);
    cv::Mat var_I_gg = boxfilter(gchannel.mul(gchannel), r) - mean_I_g.mul(mean_I_g) + eps;
    cv::Mat var_I_gb = boxfilter(gchannel.mul(bchannel), r) - mean_I_g.mul(mean_I_b);
    cv::Mat var_I_bb = boxfilter(bchannel.mul(bchannel), r) - mean_I_b.mul(mean_I_b) + eps;
    
    // Inverse of Sigma + eps * I
    invrr = var_I_gg.mul(var_I_bb) - var_I_gb.mul(var_I_gb);
    invrg = var_I_gb.mul(var_I_rb) - var_I_rg.mul(var_I_bb);
    invrb = var_I_rg.mul(var_I_gb) - var_I_gg.mul(var_I_rb);
    invgg = var_I_rr.mul(var_I_bb) - var_I_rb.mul(var_I_rb);
    invgb = var_I_rb.mul(var_I_rg) - var_I_rr.mul(var_I_gb);
    invbb = var_I_rr.mul(var_I_gg) - var_I_rg.mul(var_I_rg);
    
    cv::Mat covDet = invrr.mul(var_I_rr) + invrg.mul(var_I_rg) + invrb.mul(var_I_rb);
    
    invrr /= covDet;
    invrg /= covDet;
    invrb /= covDet;
    invgg /= covDet;
    invgb /= covDet;
    invbb /= covDet;
}

cv::Mat GuidedFilterColor::filterSingleChannel(const cv::Mat &p) const
{
    cv::Mat mean_p = boxfilter(p, r);
    
    cv::Mat mean_Ip_r = boxfilter(rchannel.mul(p), r);
    cv::Mat mean_Ip_g = boxfilter(gchannel.mul(p), r);
    cv::Mat mean_Ip_b = boxfilter(bchannel.mul(p), r);
    
    // covariance of (I, p) in each local patch.
    cv::Mat cov_Ip_r = mean_Ip_r - mean_I_r.mul(mean_p);
    cv::Mat cov_Ip_g = mean_Ip_g - mean_I_g.mul(mean_p);
    cv::Mat cov_Ip_b = mean_Ip_b - mean_I_b.mul(mean_p);
    
    cv::Mat a_r = invrr.mul(cov_Ip_r) + invrg.mul(cov_Ip_g) + invrb.mul(cov_Ip_b);
    cv::Mat a_g = invrg.mul(cov_Ip_r) + invgg.mul(cov_Ip_g) + invgb.mul(cov_Ip_b);
    cv::Mat a_b = invrb.mul(cov_Ip_r) + invgb.mul(cov_Ip_g) + invbb.mul(cov_Ip_b);
    
    cv::Mat b = mean_p - a_r.mul(mean_I_r) - a_g.mul(mean_I_g) - a_b.mul(mean_I_b); // Eqn. (15) in the paper;
    
    return (boxfilter(a_r, r).mul(rchannel)
            + boxfilter(a_g, r).mul(gchannel)
            + boxfilter(a_b, r).mul(bchannel)
            + boxfilter(b, r));  // Eqn. (16) in the paper;
}


GuidedFilter::GuidedFilter(const cv::Mat &I, int r, double eps)
{
    CV_Assert(I.channels() == 1 || I.channels() == 4);
    
    if (I.channels() == 1)
        impl_ = new GuidedFilterMono(I, 2 * r + 1, eps);
    else
        impl_ = new GuidedFilterColor(I, 2 * r + 1, eps);
}

GuidedFilter::~GuidedFilter()
{
    delete impl_;
}

cv::Mat GuidedFilter::filter(const cv::Mat &p, int depth) const
{
    return impl_->filter(p, depth);
}

void guidedFilterFillRect(cv::Mat &dst, const cv::Mat &src, cv::Rect rect, cv::Point offset)
{
    cv::Point p;
    for (p.y = rect.y; p.y < rect.y + rect.height; p.y++) {
        for (p.x = rect.x; p.x < rect.x + rect.width; p.x++) {
            cv::Point q = cv::Point(p.x - rect.x + offset.x, p.y - rect.y + offset.y);
            dst.at<uchar>(p) = src.at<uchar>(q);
        }
    }
}

void guidedFilterHelper(const cv::Mat &I, const cv::Mat &p, cv::Mat &result, int r, double eps, cv::Rect rect, cv::Point resultOffset, int depth)
{
    int top = MIN(MAX(0, rect.y - r), I.rows);
    int left = MIN(MAX(0, rect.x - r), I.cols);
    int bottom = MAX(0, MIN(I.rows, rect.y + rect.height + r));
    int right = MAX(0, MIN(I.cols, rect.x + rect.width + r));
    cv::Rect tmpRect = cv::Rect(left, top, right - left, bottom - top);

    cv::Mat output = GuidedFilter(I(tmpRect), r, eps).filter(p(tmpRect), depth);
    guidedFilterFillRect(result, output, cv::Rect(rect.x - resultOffset.x, rect.y - resultOffset.y, rect.width, rect.height), cv::Point(rect.x - tmpRect.x, rect.y - tmpRect.y));
}

void guidedFilterHelperRec(const cv::Mat &I, const cv::Mat &p, cv::Mat &result, int r, double eps, cv::Rect rect, cv::Point resultOffset)
{
    cv::Rect subrect;
    if (rect.width > 512) {
        subrect = cv::Rect(rect.x, rect.y, rect.width/2, rect.height);
        guidedFilterHelperRec(I, p, result, r, eps, subrect, resultOffset);
        
        subrect = cv::Rect(subrect.x + subrect.width, subrect.y, rect.width - subrect.width, rect.height);
        guidedFilterHelperRec(I, p, result, r, eps, subrect, resultOffset);
    }
    else if (rect.height > 512) {
        subrect = cv::Rect(rect.x, rect.y, rect.width, rect.height/2);
        guidedFilterHelperRec(I, p, result, r, eps, subrect, resultOffset);
        
        subrect = cv::Rect(subrect.x, subrect.y + subrect.height, rect.width, rect.height - subrect.height);
        guidedFilterHelperRec(I, p, result, r, eps, subrect, resultOffset);
    }
    else {
        guidedFilterHelper(I, p, result, r, eps, rect, resultOffset, -1);
    }
}

cv::Mat guidedFilter(const cv::Mat &I, const cv::Mat &p, int r, double eps, cv::Rect rect)
{
    cv::Mat result;
    if (rect.width <= 512 && rect.height <= 512) {
        result = GuidedFilter(I(rect), r, eps).filter(p(rect), -1);
    }
    else {
        result.create(rect.size(), CV_8UC1);
        guidedFilterHelperRec(I, p, result, r, eps, rect, cv::Point(rect.x, rect.y));
    }
    return result;
}
