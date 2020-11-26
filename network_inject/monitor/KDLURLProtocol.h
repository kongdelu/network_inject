//
//  KDLURLProtocol.h
//  network_inject
//
//  Created by ios on 2020/11/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KDLURLProtocol : NSURLProtocol

+ (void)start;
+ (void)end;

@end

NS_ASSUME_NONNULL_END
