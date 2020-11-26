//
//  KDLURLSessionConfiguration.h
//  network_inject
//
//  Created by ios on 2020/11/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KDLURLSessionConfiguration : NSObject

@property (nonatomic,assign) BOOL isSwizzle;

+ (KDLURLSessionConfiguration *)defaultConfiguration;

/**
 *  swizzle NSURLSessionConfiguration's protocolClasses method
 */
- (void)load;

/**
 *  make NSURLSessionConfiguration's protocolClasses method is normal
 */
- (void)unload;

@end

NS_ASSUME_NONNULL_END
