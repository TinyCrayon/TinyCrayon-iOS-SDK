//
//  improc.hpp
//  TinyCrayon
//
//  Created by Xin Zeng on 11/23/15.
//  Copyright © 2015 Xin Zeng. All rights reserved.
//

#ifndef improc_hpp
#define improc_hpp

#import <opencv2/opencv.hpp>

#include <stdio.h>

using namespace cv;


void arrcpy(uchar *dst, const uchar *src, int count);
void arrcpy(ushort *dst, const uchar *src, int count);

void arrset(uchar *dst, uchar value, int count);

bool arrckall(const uchar *arr, uchar value, int count);

bool arrckany(const uchar *arr, uchar value, int count);

void arrresize(uchar *dst, const uchar *src, cv::Size dstSize, cv::Size srcSize);

//
//   NAME: improcImageWithAlpha
//
//   PARAMETERS:
//        img       (IN) - image to combine with alpha data, RGB format
//        alphaData (IN) - data of alpha, length is the same as # of img pixels
//        compact   (IN) - true if needs to crop image with 0 alpha
//        offset   (OUT) - offset (top, left) of result image compared with img,
//                         if compact is false, offset will always be (0, 0)
//        result   (OUT) - result image
//
//   DESCRIPTION:
//        Copy RGB channel from img to result, and copy alpha channel from
//        alphaData to result
//
//   RETURNS:
//        Nothing
//
//   NOTES:
//        None
//
bool improcImageWithAlpha(const Mat &img, const uchar *alphaData, bool compact, cv::Point &offset, Mat &result, bool argb = false);


//
//   NAME: improcMaskToImage
//
//   PARAMETERS:
//        maskData    (IN) - data of mask matrix
//        opacityData (IN) - data of alpha matrix
//        size        (IN) - size of mask/alpha matrix
//        rect        (IN) - the rect where to convert maskData to img
//        img        (OUT) - result image, the size is the same as rect size
//
//   DESCRIPTION:
//        Convert mask array to a img bitmap. If a pixel value of maks
//        converting to opacity is v, the corrosponding pixel value (RGBA) of
//        img will be (v, v, v, v).
//        If opacityData is null, v will only have 2 values: 0 for mask
//        background, 255 for mask forground.
//        If opacityData is not null, and such pixel of mask is marked with
//        GC_FLAG_SMOOTH, then v will be the value of opacityData.
//
//   RETURNS:
//        Nothing
//
//   NOTES:
//        None
//
void improcMaskToImage(const uchar *maskData, const uchar *opacityData, cv::Size size, cv::Rect rect, Mat &img);

//
//   NAME: improcPaintSelect
//
//   PARAMETERS:
//        imageData        (IN) - image data
//        size             (IN) - size of image
//        maskData     (IN/OUT) - data of mask
//        regionData       (IN) - data of region (user's drawing)
//        opacityData      (IN) - data of opacity
//        mode             (IN) - GC_MODE_FGD for select and GC_MODE_BGD for erase
//        rect             (IN) - rect where to execute paint select
//        edgeDetection    (IN) - whether to use edge detection
//        outRect         (OUT) - rect where value of maskData has been changed
//
//   DESCRIPTION:
//        Execute paint select algorithm, update maskData
//
//   RETURNS:
//        True if paint select is successfully performed
//        False otherwise
//
//   NOTES:
//
bool improcImageSelect(const uchar *imageData, cv::Size size, uchar *maskData, const uchar *regionData, const uchar *opacityData, int mode, bool edgeDetection, cv::Rect rect, cv::Rect &outRect);

//
//   NAME: improcMaskToAlpha
//
//   PARAMETERS:
//        mask     (IN) - data of mask
//        opacity  (IN) - data of opacity
//        alpha   (OUT) - data of alpha, it's size should be equal to rect size
//        size     (IN) - size of mask/opacity
//        rect     (IN) - rect of mask to convert to alpha
//
//   DESCRIPTION:
//        Convert mask to alpha
//
//   RETURNS:
//        Nothing
//
//   NOTES:
//        None
//
void improcMaskToAlpha(const uchar *mask, const uchar *opacity, uchar *alpha, cv::Size size, cv::Rect rect);

//
//   NAME: improcAlphaToImage
//
//   PARAMETERS:
//        alphaData  (IN) - mat of alpha
//        img       (OUT) - result image
//
//   DESCRIPTION:
//        Convert alpha data to image, if pixel value of alpha data is v,
//        corrosponding value (RGBA) of image will be (v, v, v, v)
//
//   RETURNS:
//        Nothing
//
//   NOTES:
//        None
//
void improcAlphaToImage(const uchar *alphaData, cv::Size size, cv::Rect rect, cv::Mat &img);

void improcAlphaToMask(const uchar *alpha, uchar *mask, cv::Size size, cv::Rect rect);

//
//   NAME: improcPushMaskLog
//
//   PARAMETERS:
//        mask      (IN) - mask data
//        log   (IN/OUT) - log data
//        count     (IN) - number of active log count
//        offset    (IN) - offset of current log
//
//   DESCRIPTION:
//        Push mask data to log
//
//   NOTES:
//
void improcPushMaskLog(const uchar *mask, unsigned short *log, int count, int offset);

//
//   NAME: improcPopMaskLog
//
//   PARAMETERS:
//        mask     (OUT) - mask data
//        log   (IN/OUT) - log data
//        count     (IN) - mask/log length
//        offset    (IN) - offset of current log
//
//   DESCRIPTION:
//        Pop mask data to log
//
//   RETURNS:
//        Nothing
//
//   NOTES:
//        None
//
void improcPopMaskLog(uchar *mask, const unsigned short *log, int count, int offset);

//
//   NAME: improcUpdateMask
//
//   PARAMETERS:
//        mask  (OUT) - data of mask
//        alpha  (IN) - data of alpha
//        region (IN) - region to apply update
//        count  (IN) - length of mask/alpha
//
//   DESCRIPTION:
//        Update the GC_FLAG_SMOOTH bit of mask
//
//   RETURNS:
//        Nothing
//
//   NOTES:
//        None
//
void improcUpdateMask(uchar *mask, const uchar *alpha, const uchar *region, int count);

//
//   NAME: improcImageMatting
//
//   PARAMETERS:
//        imageData        (IN) - image data
//        size             (IN) - size of original image
//        alpha           (OUT) - output alpha
//        region           (IN) - data of region (user's drawing)
//        rect             (IN) - rect where to execute image matting
//
//   DESCRIPTION:
//        Image matting
//
//   RETURNS:
//        Nothing
//
//   NOTES:
//        None
//
bool improcImageMatting(const uchar *imageData, cv::Size size, uchar *alpha, const uchar *region, cv::Rect rect);

//
//   NAME: improcImageFiltering
//
//   PARAMETERS:
//        imageData        (IN) - image data
//        size             (IN) - size of original image
//        alpha           (OUT) - output alpha
//        region           (IN) - data of region (user's drawing)
//        rect             (IN) - rect where to execute image matting
//        add              (IN) - add or subtract
//
//   DESCRIPTION:
//        image guided filtering
//
//   RETURNS:
//        true if image filter successfully executed, false otherwise
//
//   NOTES:
//        None
//
bool improcImageFiltering(const uchar *imageData, cv::Size size, uchar *alpha, const uchar *region, cv::Rect rect, bool add);

void improcInvertAlpha(uchar *alpha, int count);

void improcInvertMask(uchar *alpha, int count);

bool improcLogEncodeDiff(const uchar *from, const uchar *to, int count, uint *buf, int bufLen, int *processed, int *offset);

bool improcLogEncodeArray(const uchar *arr, int count, uint *buf, int bufLen, int *processed, int *offset);

void improcLogDecodeDiff(uchar *to, const uchar *from, const uint *diff, int count, int diffCount);

void improcLogDecodeArray(uchar *decoded, const uint *encoded, int decodedCount, int incodedCount);

bool improcDrawRadialGradient(uchar *alpha, cv::Size size, cv::Point center, int startV, int startR, int endV, int endR, cv::Rect &outRect, bool add);
#endif /* improc_hpp */
