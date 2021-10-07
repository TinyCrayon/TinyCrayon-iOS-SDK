//
//  TCCoreLibs0.h
//  TinyCrayon
//
//  Created by Xin Zeng on 1/2/17.
//
//

#ifndef TCCoreLibs0_h
#define TCCoreLibs0_h

#include "TCCoreLibs.h"
#include <opencv2/opencv.hpp>

#define TC_ASSERT(_exp, _msg, ...) do {                \
if (!(_exp)) { printf(_msg, ##__VA_ARGS__);            \
assert(false); }} while(false)

#define bit(_val, _flag) ((_val) & (_flag))
#define bis(_val, _flag) ((_val) |= (_flag))
#define bic(_val, _flag) ((_val) &= (~(_flag)))

#define IS_BOUNDARY(_mat, _p) (\
(((_p).x > 0) && ((_mat).at<uchar>(cv::Point((_p).x - 1, (_p).y)) != (_mat).at<uchar>((_p)))) ||                  \
(((_p).y > 0) && ((_mat).at<uchar>(cv::Point((_p).x, (_p).y - 1)) != (_mat).at<uchar>((_p)))) ||                  \
(((_p).x < (_mat).cols - 1) && ((_mat).at<uchar>(cv::Point((_p).x + 1, (_p).y)) != (_mat).at<uchar>((_p)))) ||    \
(((_p).y < (_mat).rows - 1) && ((_mat).at<uchar>(cv::Point((_p).x, (_p).y + 1)) != (_mat).at<uchar>((_p)))))

#define TC_RGBA                0
#define TC_ARGB                1

#ifdef DEVICE_OS_IOS
#define DEVICE_COLOR_SPACE     TC_RGBA
#define RGB_VAL(_img, _y, _x) (*(cv::Vec3b*)&_img.at<cv::Vec4b>((_y), (_x)))
#else
#define DEVICE_COLOR_SPACE     TC_ARGB
#define RGB_VAL(_img, _y, _x) (*(cv::Vec3b*)((uchar *)&_img.at<cv::Vec4b>((_y), (_x)) + 1))
#endif

#define RGB_VALP(_img, _p) RGB_VAL((_img), (_p).y, (_p).x)

#define TC_ARGB_TO_RGB(_dst, _src, _cnt)                                   \
do {                                                                       \
for (int _i = 0; _i < (_cnt); _i++)                                        \
*((cv::Vec3b *)(_dst) + _i) = (*(unsigned int *)((_src) + 4*_i)) >> 8;     \
} while(0)

#define GC_IS_FGD_INT(_val) ((_val) == GC_MASK_FGD || (_val) == GC_MASK_PR_FGD)
#define GC_IS_BGD_INT(_val) ((_val) == GC_MASK_BGD || (_val) == GC_MASK_PR_BGD)

#define GC_VAL(_val) ((_val) & GC_MASK)
#define GC_IS_FGD(_val) (GC_IS_FGD_INT(GC_VAL(_val)))
#define GC_IS_BGD(_val) (GC_IS_BGD_INT(GC_VAL(_val)))

#define GC_LABEL_CHANGED(_label1, _label2) \
((GC_IS_FGD(_label1) && GC_IS_BGD(_label2)) || (GC_IS_BGD(_label1) && GC_IS_FGD(_label2)))

#define PROB_VALUE(_val) ((_val) == GC_MASK_BGD ? GC_MASK_PR_BGD : (_val) == GC_MASK_FGD ? GC_MASK_PR_FGD : _val)

#define GC_DEFINITE_VALUE(_val) ((_val) ^ 0x01)

#define GC_IS_PASS_THROUGH(_val) (bit((_val), GC_FLAG_PASS))

#define GC_ASSERT(_val) TC_ASSERT((_val) < 4, "inv GC value: %d\n", (_val))

#define MATTING_RADIUS        8

#if CV_VERSION_MAJOR > 2
#define TC_StsBadArg (cv::Error::StsBadArg)
#else
#define TC_StsBadArg (CV_StsBadArg)
#endif

#endif /* TCCoreLibs0_h */
