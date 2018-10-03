//
//  NSImage+C__.h
//  JPEG
//
//  Created by MCUCSIE on 5/10/18.
//  Copyright © 2018 MCUCSIE. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSInteger, ColorSpace) {
    ColorSpaceGray = 1,
    ColorSpaceRGB = 3
};
@interface NSImage (cplusplus)
+ (instancetype)imageWithData:(Byte*)data row:(int)row andColumn:(int)col colorspace:(ColorSpace)space;
@end
