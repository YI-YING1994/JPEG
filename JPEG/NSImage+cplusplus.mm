//
//  NSImage+C__.m
//  JPEG
//
//  Created by MCUCSIE on 5/10/18.
//  Copyright © 2018 MCUCSIE. All rights reserved.
//

#import "NSImage+cplusplus.h"

@implementation NSImage (cplusplus)

+ (instancetype)imageWithData:(void*)data row:(int)row andColumn:(int)col colorspace:(ColorSpace)space {
    CGColorSpaceRef colorSpace = (space == ColorSpaceGray) ? CGColorSpaceCreateDeviceGray() : CGColorSpaceCreateDeviceRGB();
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, data, row * col * space, NULL);

    CGImageRef imageRef = CGImageCreate(col,                                            // Width
                                        row,                                            // Height
                                        8,                                              // Bits per component
                                        8 * space,                                              // Bits per pixel
                                        col * space,                                            // Bytes per row
                                        colorSpace,                                     // Colorspace
                                        0,                                              // Bitmap info flags
                                        provider,                                       // CGDataProviderRef
                                        NULL,                                           // Decode
                                        false,                                          // Should interpolate
                                        kCGRenderingIntentDefault);                     // Intent


    NSImage *image = [[self alloc] initWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);

    return image;
}

@end
