//
//  improc.cpp
//  TinyCrayon
//
//  Created by Xin Zeng on 11/23/15.
//  Copyright © 2015 Xin Zeng. All rights reserved.
//

#include <stdio.h>
#include <ctime>
#include "improc.hpp"
#include "OpenCVLibs0.h"
#include "PaintSelect.hpp"
#include "GlobalMatting.hpp"
#include "GuidedFilter.hpp"

#define SMOOTH_RADIUS    3
#define SMOOTH_SOFTNESS 27

static void improcSmoothAlpha(cv::Mat &alpha) {
    int r = SMOOTH_RADIUS;
    int softness = SMOOTH_SOFTNESS;
    
    cv::GaussianBlur(alpha, alpha, cv::Size(2*r+1, 2*r+1), 0, 0);
    
    uchar high = 128 + softness;
    uchar low = 127 - softness;
    
    cv::Point p;
    for (p.y = 0; p.y < alpha.rows; p.y++) {
        for (p.x = 0; p.x < alpha.cols; p.x++) {
            int val = alpha.at<uchar>(p);
            double scale = (double)(val - low) / (double)(high - low);
            scale = MIN(1, MAX(0, scale));
            alpha.at<uchar>(p) = scale * 255;
        }
    }
}

void arrcpy(uchar *dst, const uchar *src, int count) {
    memcpy(dst, src, count);
}

void arrcpy(ushort *dst, const uchar *src, int count) {
    for (int i = 0; i < count; i++)
        dst[i] = src[i];
}

void arrset(uchar *dst, uchar value, int count) {
    memset(dst, value, count);
}

bool arrckall(const uchar *arr, uchar value, int count) {
    for (int i = 0; i < count; i++)
        if (arr[i] != value)
            return false;
    return true;
}

bool arrckany(const uchar *arr, uchar value, int count) {
    for (int i = 0; i < count; i++)
        if (arr[i] == value)
            return true;
    return false;
}

void arrresize(uchar *dst, const uchar *src, cv::Size dstSize, cv::Size srcSize) {
    cv::Mat dstMat(dstSize, CV_8UC1, dst);
    cv::Mat srcMat(srcSize, CV_8UC1, (uchar *)src);
    cv::resize(srcMat, dstMat, dstSize, 0, 0, INTER_CUBIC);
}

bool improcImageWithAlpha(const Mat &img, const uchar *alphaData, bool compact, Point &offset, Mat &result, bool argb) {
    Point p;
    cv::Mat alpha = cv::Mat(img.rows, img.cols, CV_8UC1, (char *)alphaData);
    int top = alpha.rows - 1;
    int bottom = 0;
    int left = alpha.cols - 1;
    int right = 0;
    
    if (compact) {
        for (p.y = 0; p.y < alpha.rows; p.y++) {
            for (p.x = 0; p.x < alpha.cols; p.x++) {
                if (alpha.at<uchar>(p) == 0) {
                    continue;
                }
                top = MIN(top, p.y);
                bottom = MAX(bottom, p.y);
                left = MIN(left, p.x);
                right = MAX(right, p.x);
            }
        }
        
        if (top > bottom || left > right) {
            return false;
        }
    }
    else {
        top = 0;
        left = 0;
        right = img.cols - 1;
        bottom = img.rows - 1;
    }
    
    result.create(bottom - top + 1, right - left + 1, CV_8UC4);
    if (argb) {
        for (p.y = top; p.y <= bottom; p.y++) {
            for (p.x = left; p.x <= right; p.x++) {
                cv::Point q = cv::Point(p.x - left, p.y - top);
                cv::Vec4b color = img.at<Vec4b>(p);
                result.at<Vec4b>(q) = Vec4b(alpha.at<uchar>(p), color[1], color[2], color[3]);
            }
        }
    }
    else {
        for (p.y = top; p.y <= bottom; p.y++) {
            for (p.x = left; p.x <= right; p.x++) {
                cv::Point q = cv::Point(p.x - left, p.y - top);
                cv::Vec4b color = img.at<Vec4b>(p);
                result.at<Vec4b>(q) = Vec4b(color[0], color[1], color[2], alpha.at<uchar>(p));
            }
        }
    }

    
    offset.x = left;
    offset.y = top;
    
    return true;
}

void improcMaskToImage(const uchar *maskData, const uchar *opacityData, cv::Size size, cv::Rect rect, Mat &img) {
    Mat mask = Mat(size.height, size.width, CV_8UC1, (uchar *) maskData);
    Mat opacity = Mat(mask.size(), CV_8UC1, (uchar *) opacityData);
    Mat alpha = Mat(rect.size(), CV_8UC1);
    Point p;
    improcMaskToAlpha(maskData, opacityData, alpha.data, size, rect);
    improcAlphaToImage(alpha.data, alpha.size(), cv::Rect(0, 0, rect.width, rect.height), img);
}

bool improcImageSelect(const uchar *imageData, cv::Size size, uchar *maskData, const uchar *regionData, const uchar *opacityData, int mode, bool edgeDetection, cv::Rect rect, cv::Rect &outRect) {
    
    assert(size.width > 0 && size.height > 0);
    assert(rect.x >= 0 && rect.y >= 0);
    assert(rect.x + rect.width <= size.width && rect.y + rect.height <= size.height);
    
    cv::Mat img(size, CV_8UC4, (uchar *)imageData);
    Mat mask = Mat(size, CV_8UC1, maskData);
    Mat region = Mat(size, CV_8UC1, (uchar *)regionData);
    Mat opacity = Mat(size, CV_8UC1, (uchar *)opacityData);
    cv::Point p;
    cv::Mat maskVal = cv::Mat(rect.size(), CV_8UC1);
    cv::Mat result = cv::Mat(rect.height, rect.width, CV_8UC1);
    
    int top = mask.rows - 1;
    int bottom = 0;
    int left = mask.cols - 1;
    int right = 0;
    
    for (p.y = 0; p.y < maskVal.rows; p.y++) {
        for (p.x = 0; p.x < maskVal.cols; p.x++) {
            maskVal.at<uchar>(p) = GC_VAL((mask.at<uchar>(cv::Point(p.x+rect.x, p.y + rect.y))));
        }
    }
    
    if (edgeDetection) {
        paintSelect(img(rect), maskVal, region(rect), result, mode);
    }
    else {
        for (p.y = 0; p.y < rect.height; p.y++) {
            for (p.x = 0; p.x < rect.width; p.x++) {
                cv::Point q = cv::Point(p.x + rect.x, p.y + rect.y);
                if (region.at<uchar>(q) != GC_UNINIT)
                    result.at<uchar>(p) = mode == GC_MODE_FGD? GC_MASK_FGD : GC_MASK_BGD;
                else
                    result.at<uchar>(p) = maskVal.at<uchar>(p);
            }
        }
    }

    bool maskHasAlpha;
    for (p.y = 0; p.y < rect.height; p.y++) {
        for (p.x = 0; p.x < rect.width; p.x++) {
            cv::Point q = cv::Point(p.x + rect.x, p.y + rect.y);
            
            maskHasAlpha = bit(mask.at<uchar>(q), GC_FLAG_ALPHA);
            
            if ((GC_LABEL_CHANGED(maskVal.at<uchar>(p), result.at<uchar>(p))) ||
                (maskHasAlpha && region.at<uchar>(q) != GC_UNINIT) ||
                (maskHasAlpha && maskVal.at<uchar>(p) != result.at<uchar>(p)))
            {
                bic(mask.at<uchar>(q), GC_FLAG_ALPHA);
            }
            
            bic(mask.at<uchar>(q), GC_MASK);
            mask.at<uchar>(q) |= result.at<uchar>(p) & GC_MASK;
            
            uchar previousAlpha = maskHasAlpha ? opacity.at<uchar>(q) : GC_IS_BGD(maskVal.at<uchar>(p)) ?  0 : 255;
            uchar currentAlpha = bit(mask.at<uchar>(q), GC_FLAG_ALPHA) ? opacity.at<uchar>(q) : GC_IS_BGD(mask.at<uchar>(q)) ?  0 : 255;
            if (previousAlpha != currentAlpha) {
                top = MIN(top, q.y);
                bottom = MAX(bottom, q.y);
                left = MIN(left, q.x);
                right = MAX(right, q.x);
            }
        }
    }

    if (top > bottom || left > right) {
        for (p.y = 0; p.y < rect.height; p.y++) {
            for (p.x = 0; p.x < rect.width; p.x++) {
                cv::Point q = cv::Point(p.x + rect.x, p.y + rect.y);
                if (region.at<uchar>(q) != GC_UNINIT) {
                    top = MIN(top, q.y);
                    bottom = MAX(bottom, q.y);
                    left = MIN(left, q.x);
                    right = MAX(right, q.x);
                }
            }
        }
    }
    
    if (top > bottom || left > right) {
        outRect = cv::Rect(0, 0, 0, 0);
        return false;
    }
    
    int r = SMOOTH_RADIUS;
    top = MAX(0, top - r);
    left = MAX(0, left - r);
    bottom = MIN(img.rows, bottom + 1 + r);
    right = MIN(img.cols, right + 1 + r);

    outRect = cv::Rect(left, top, right - left, bottom - top);
    return true;
}

void improcAlphaToImage(const uchar *alphaData, cv::Size size, cv::Rect rect, cv::Mat &img) {
    cv::Mat alpha(size, CV_8UC1, (uchar *)alphaData);
    img.create(rect.size(), CV_8UC4);
    cv::Point p;
    
    for (p.y = 0; p.y < img.rows; p.y++) {
        for (p.x = 0; p.x < img.cols; p.x++) {
            cv::Point q(p.x + rect.x, p.y + rect.y);
            uchar value = alpha.at<uchar>(q);
            img.at<Vec4b>(p) = Vec4b(value, value, value, value);
        }
    }
}

void improcAlphaToMask(const uchar *alphaData, uchar *maskData, cv::Size size, cv::Rect rect) {
    cv::Mat alpha(size, CV_8UC1, (uchar *)alphaData);
    cv::Mat mask(size, CV_8UC1, maskData);
    cv::Point p;
    
    mask.setTo(0);
    for (p.y = rect.y; p.y < rect.y + rect.height; p.y++) {
        for (p.x = rect.x; p.x < rect.x + rect.width; p.x++) {
            if (alpha.at<uchar>(p) <= 127)
                mask.at<uchar>(p) = GC_MASK_PR_BGD;
            else
                mask.at<uchar>(p) = GC_MASK_PR_FGD;
            
            bis(mask.at<uchar>(p), GC_FLAG_ALPHA);
        }
    }
}

void improcPushMaskLog(const uchar *mask, unsigned short *log, int count, int offset) {
    if (offset == 0) {
        for (int i = 0; i < count; i++)
            log[i] = (log[i] << 4) | mask[i];
            }
    else {
        for (int i = 0; i < count; i++)
            log[i] = (((log[i] >> (offset * 4 - 4)) & 0xFFF0) | mask[i]);
            }
}

void improcPopMaskLog(uchar *mask, const unsigned short *log, int count, int offset) {
    for (int i = 0; i < count; i++) {
        mask[i] = (log[i] >> offset * 4) & GC_LOG_MASK;
    }
}

void improcMaskToAlpha(const uchar *mask, const uchar *opacity, uchar *alpha, cv::Size size, cv::Rect rect) {
    cv::Mat maskMat(size, CV_8UC1, (uchar *)mask);
    cv::Mat opacityMat(size, CV_8UC1, (uchar *)opacity);
    cv::Mat alphaMat(rect.size(), CV_8UC1, alpha);
    cv::Point p;

    int r = SMOOTH_RADIUS;
    int top = MAX(0, rect.y - r);
    int left = MAX(0, rect.x - r);
    int bottom = MIN(size.height, rect.y + rect.height + r);
    int right = MIN(size.width, rect.x + rect.width + r);
    
    cv::Rect outerRect(left, top, right - left, bottom - top);
    cv::Mat smoothed(outerRect.size(), CV_8UC1);
    
    for (p.y = 0; p.y < smoothed.rows; p.y++) {
        for (p.x = 0; p.x < smoothed.cols; p.x++) {
            cv::Point q(p.x + outerRect.x, p.y + outerRect.y);
            if (GC_IS_FGD(maskMat.at<uchar>(q))) {
                smoothed.at<uchar>(p) = 255;
            }
            else {
                smoothed.at<uchar>(p) = 0;
            }
        }
    }
    
    improcSmoothAlpha(smoothed);
    
    for (p.y = 0; p.y < alphaMat.rows; p.y++) {
        for (p.x = 0; p.x < alphaMat.cols; p.x++) {
            cv::Point q(p.x + rect.x - outerRect.x, p.y + rect.y - outerRect.y);
            cv::Point r(p.x + rect.x, p.y + rect.y);
            cv::Point left(MAX(0, r.x - SMOOTH_RADIUS), r.y);
            cv::Point top(r.x, MAX(0, r.y - SMOOTH_RADIUS));
            cv::Point right(MIN(size.width - 1, r.x + SMOOTH_RADIUS), r.y);
            cv::Point bottom(r.x, MIN(size.height - 1, r.y + SMOOTH_RADIUS));
            
            if (!bit(maskMat.at<uchar>(r), GC_FLAG_ALPHA) ||
                !bit(maskMat.at<uchar>(top), GC_FLAG_ALPHA) ||
                !bit(maskMat.at<uchar>(left), GC_FLAG_ALPHA) ||
                !bit(maskMat.at<uchar>(bottom), GC_FLAG_ALPHA) ||
                !bit(maskMat.at<uchar>(right), GC_FLAG_ALPHA))
            {
                alphaMat.at<uchar>(p) = smoothed.at<uchar>(q);
            }
            else
            {
                alphaMat.at<uchar>(p) = opacityMat.at<uchar>(r);
            }
        }
    }
}

void improcUpdateMask(uchar *mask, const uchar *alpha, const uchar *region, int count) {
    for (int i=0; i < count; i++) {
        if (region[i] != GM_UNKNOWN)
            continue;
        
        if ((GC_IS_FGD(mask[i]) && alpha[i] != 255) ||
            (GC_IS_BGD(mask[i]) && alpha[i] != 0)) {
            bis(mask[i], GC_FLAG_ALPHA);
        }
    }
}

bool improcImageMatting(const uchar *imageData, cv::Size size, uchar *alpha, const uchar *region, cv::Rect rect) {
    cv::Mat img = cv::Mat(size, CV_8UC4, (uchar *)imageData);
    cv::Mat regionMat = cv::Mat(size, CV_8UC1, (uchar *)region);
    cv::Mat alphaMat = cv::Mat(size, CV_8UC1, alpha);
    cv::Mat output = cv::Mat(rect.size(), CV_8UC1);
    cv::Mat trimap = cv::Mat(size, CV_8UC1);
    cv::Point p;
    
    if (rect.width == 0 || rect.height == 0)
        return false;
    
    for (p.y = 0; p.y < rect.height; p.y++) {
        for (p.x = 0; p.x < rect.width; p.x++) {
            cv::Point q = cv::Point(p.x + rect.x, p.y + rect.y);
            
            output.at<uchar>(p) = alphaMat.at<uchar>(q);
            
            if (regionMat.at<uchar>(q) == GM_UNKNOWN) {
                trimap.at<uchar>(q) = GM_UNKNOWN;
            }
            else if (alphaMat.at<uchar>(q) == 0) {
                trimap.at<uchar>(q) = GM_BGD;
            }
            else if (alphaMat.at<uchar>(q) == 255) {
                trimap.at<uchar>(q) = GM_FGD;
            }
            else {
                trimap.at<uchar>(q) = GM_PASS_THROUGH;
            }
        }
    }
    
    globalMatting(img, trimap, output, rect);
    
    int r = MATTING_RADIUS; // try r=2, 4, or 8
    double eps = 1e-6;; // try eps=0.1^2, 0.2^2, 0.4^2
    
    eps *= 255 * 255;   // Because the intensity range of our images is [0, 255]
    output = guidedFilter(img(rect), output, r, eps, cv::Rect(0, 0, rect.width, rect.height));
    
    for (p.y = 0; p.y < rect.height; p.y++) {
        for (p.x = 0; p.x < rect.width; p.x++) {
            cv::Point q = cv::Point(p.x + rect.x, p.y + rect.y);
            if (regionMat.at<uchar>(q) != GM_UNINIT)
                alphaMat.at<uchar>(q) = output.at<uchar>(p);
        }
    }
    
    return true;
}

bool improcImageFiltering(const uchar *imageData, cv::Size size, uchar *alpha, const uchar *region, cv::Rect rect, bool add) {
    cv::Mat img = cv::Mat(size, CV_8UC4, (uchar *)imageData);
    cv::Mat regionMat = cv::Mat(size, CV_8UC1, (uchar *)region);
    cv::Mat alphaMat = cv::Mat(size, CV_8UC1, alpha);
    cv::Point p;
    
    if (rect.width <= 0 || rect.height <= 0)
        return false;
    
    for (p.y = 0; p.y < rect.height; p.y++) {
        for (p.x = 0; p.x < rect.width; p.x++) {
            cv::Point q = cv::Point(p.x + rect.x, p.y + rect.y);
            if (regionMat.at<uchar>(q) == GM_FGD && alphaMat.at<uchar>(q) < 255)
                alphaMat.at<uchar>(q)++;
            else if (regionMat.at<uchar>(q) == GM_BGD && alphaMat.at<uchar>(q) > 0)
                alphaMat.at<uchar>(q)--;
        }
    }
    
    int r = MATTING_RADIUS; // try r=2, 4, or 8
    double eps = 1e-6;; // try eps=0.1^2, 0.2^2, 0.4^2
    
    eps *= 255 * 255;   // Because the intensity range of our images is [0, 255]
    
    Mat output = guidedFilter(img, alphaMat, r, eps, rect);
    
    for (p.y = 0; p.y < rect.height; p.y++) {
        for (p.x = 0; p.x < rect.width; p.x++) {
            cv::Point q = cv::Point(p.x + rect.x, p.y + rect.y);
            
            if (regionMat.at<uchar>(q) == GM_UNINIT ||
                (add && output.at<uchar>(p) <= alphaMat.at<uchar>(q)) ||
                (!add && output.at<uchar>(p) >= alphaMat.at<uchar>(q))) {
                continue;
            }
            else {
                alphaMat.at<uchar>(q) = output.at<uchar>(p);
            }
        }
    }
    
    return true;
}

void improcInvertAlpha(uchar *alpha, int count) {
    for (int i = 0; i < count; i++)
        alpha[i] = 255 - alpha[i];
}

void improcInvertMask(uchar *mask, int count) {
    for (int i = 0; i < count; i++)
        mask[i] ^= GC_MASK;
}

bool improcLogEncodeArray(const uchar *arr, int count, uint *buf, int bufLen, int *processed, int *offset) {
    Mat zero(1, count, CV_8UC1);
    zero.setTo(0);
    return improcLogEncodeDiff(zero.data, arr, count, buf, bufLen, processed, offset);
}

bool improcLogEncodeDiff(const uchar *from, const uchar *to, int count, uint *buf, int bufLen, int *processed, int *offset) {
    
#define ENCODE_MAX_LEN  0x1000000
    
    assert(bufLen > 0);
    
    short diff = 0;
    short preDiff = 0;
    unsigned int length = 0;
    *processed = 0;
    
    for (int i = *offset; i < count; i++) {
        diff = to[i] ^ from[i];
        if (diff == preDiff) {
            length ++;
            if (length >= ENCODE_MAX_LEN) {
                buf[(*processed)++] = (ENCODE_MAX_LEN - 1) << 8 | preDiff;
                if (*processed >= bufLen) {
                    return false;
                }
                length = 1;
            }
        }
        else {
            if (length > 0) {
                buf[(*processed)++] = length << 8 | preDiff;
                if (*processed >= bufLen) {
                    return false;
                }
            }
            preDiff = diff;
            length = 1;
        }
        ++*offset;
    }

    assert(length > 0);
    buf[(*processed)++] = length << 8 | diff;
    
    assert(*offset == count);
    return true;
}

void improcLogDecodeArray(uchar *decoded, const uint *encoded, int decodedCount, int incodedCount) {
    Mat zero(1, decodedCount, CV_8UC1);
    zero.setTo(0);
    improcLogDecodeDiff(decoded, zero.data, encoded, decodedCount, incodedCount);
}

void improcLogDecodeDiff(uchar *to, const uchar *from, const uint *diff, int count, int diffCount) {
    
    memcpy(to, from, count);
    int idx = 0;
    for (int i = 0; i < diffCount; i++) {
        uint value = diff[i];
        uchar diff = value & 0xFF;
        int length = value >> 8;
        
        for (int j = 0; j < length; j++) {
            to[idx] = from[idx] ^ diff;
            idx++;
        }
    }
    assert(idx == count);
}

bool improcDrawRadialGradient(uchar *alpha, cv::Size size, cv::Point center, int startV, int startR, int endV, int endR, cv::Rect &outRect, bool add)
{
    assert(startR >=0);
    assert(startR <= endR);
    assert(startV >=0 && startV <= 255);
    assert(endV >=0 && endV <=255);
    
    cv::Mat alphaMat = cv::Mat(size, CV_8UC1, alpha);
    cv::Point p;
    
    int top = MAX(0, center.y - endR - 1);
    int left = MAX(0, center.x - endR - 1);
    int bottom = MIN(size.height, center.y + endR + 1);
    int right = MIN(size.width, center.x + endR + 1);

    if (top >= bottom || left >= right) {
        outRect = cv::Rect(0, 0, 0, 0);
        return false;
    }
    
    outRect = cv::Rect(left, top, right - left, bottom - top);
    
    for (p.y = top; p.y < bottom; p.y++) {
        for (p.x = left; p.x < right; p.x++) {
            double d = sqrt((p.x - center.x) * (p.x - center.x) + (p.y - center.y) * (p.y - center.y));

            if (d > endR)
                continue;
            
            int value;
            if (startR == endR || d < startR) {
                value = startV;
            }
            else {
                value = startV +  (endV - startV) * (d - startR) * (d - startR) / (endR - startR) / (endR - startR);
            }
            
            if (add)
                value = alphaMat.at<uchar>(p) + value;
            else
                value = alphaMat.at<uchar>(p) - value;
            
            value = MIN(255, MAX(0, value));
            alphaMat.at<uchar>(p) = (uchar)value;
        }
    }
    
    return true;
}
