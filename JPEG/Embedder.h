//
//  Embeder.h
//  JPEG
//
//  Created by MacLaptop on 2019/1/25.
//  Copyright © 2019 MCUCSIE. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Embedder : NSObject

- (instancetype)init;
- (void)embeddingMessage:(NSString *)messagePath withCover:(NSString *)coverPath;

@end

NS_ASSUME_NONNULL_END
