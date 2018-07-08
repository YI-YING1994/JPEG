//
//  NSImage+C__.m
//  JPEG
//
//  Created by MCUCSIE on 5/10/18.
//  Copyright © 2018 MCUCSIE. All rights reserved.
//

#import "NSImage+cplusplus.h"

@implementation NSImage (cplusplus)

+ (instancetype)imageWithData:(Byte*)data row:(int)row andColumn:(int)col {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, data, row * col * 3, NULL);

    CGImageRef imageRef = CGImageCreate(col,                                            // Width
                                        row,                                            // Height
                                        8,                                              // Bits per component
                                        8 * 3,                                              // Bits per pixel
                                        col * 3,                                            // Bytes per row
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
