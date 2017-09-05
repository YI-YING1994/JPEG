//
//  NSImage+OpenCV.h
//  JPEG
//
//  Created by MCUCSIE on 9/4/17.
//  Copyright © 2017 MCUCSIE. All rights reserved.
//
#pragma clang diagnostic ignored "-Wdocumentation"

#import "opencv2/opencv.hpp"
#import <Cocoa/Cocoa.h>

@interface NSImage (OpenCV)

+ (instancetype)imageWithCVMat:(const cv::Mat&)cvMat;

@property(nonatomic, readonly) cv::Mat CVMat;
@property(nonatomic, readonly) cv::Mat CVGrayscaleMat;

@end
