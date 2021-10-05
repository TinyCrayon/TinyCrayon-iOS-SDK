//
//  OpenCVLibs.h
//  TinyCrayon
//
//  Created by Xin Zeng on 11/8/15.
//  Copyright © 2015 Xin Zeng. All rights reserved.
//

#ifndef OpenCVLibs_h
#define OpenCVLibs_h

#define GC_MASK_BGD            0
#define GC_MASK_PR_BGD         1
#define GC_MASK_PR_FGD         2
#define GC_MASK_FGD            3

#define GC_PASS_THROUGH_BGD    4
#define GC_PASS_THROUGH_PR_BGD 5
#define GC_PASS_THROUGH_PR_FGD 6
#define GC_PASS_THROUGH_FGD    7

#define GC_FLAG_PASS        0x04
#define GC_FLAG_ALPHA       0x08

#define GC_UNINIT            255

#define GC_MASK              0x3
#define GC_LOG_MASK         0x0F

#define GC_MODE_FGD            0
#define GC_MODE_BGD            1

#define GM_BGD                 0
#define GM_PASS_THROUGH       64
#define GM_UNKNOWN           128
#define GM_UNINIT            192
#define GM_FGD               255

#endif /* OpenCVLibs_h */
