//
//  NSImage+C__.h
//  JPEG
//
//  Created by MCUCSIE on 5/10/18.
//  Copyright © 2018 MCUCSIE. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSImage (cplusplus)
+ (instancetype)imageWithData:(Byte*)data row:(int)row andColumn:(int)col;
@end
