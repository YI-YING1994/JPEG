//
//  Extracter.h
//  JPEG
//
//  Created by MacLaptop on 2019/1/25.
//  Copyright © 2019 MCUCSIE. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Extractor : NSObject

- (instancetype)init;
- (void)extracttingMessageFrom:(NSString *)stegoPath;

@end

NS_ASSUME_NONNULL_END
