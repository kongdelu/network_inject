//
//  KDLURLProtocol.m
//  network_inject
//
//  Created by ios on 2020/11/26.
//

#import "KDLURLProtocol.h"
#import "KDLURLSessionConfiguration.h"

static NSString *const KeyHTTP = @"KeyHTTP"; //避免canInitWithRequest和canonicalRequestForRequest的死循环

@interface KDLURLProtocol()

@property (nonatomic, strong) NSMutableData *kdl_data;

@end

@implementation KDLURLProtocol

- (NSMutableData *)kdl_data {
    if (!_kdl_data) {
        _kdl_data = [[NSMutableData alloc] initWithCapacity:100];
    }
    return _kdl_data;
}

+ (void)start {
    KDLURLSessionConfiguration *sessionConfiguration = [KDLURLSessionConfiguration defaultConfiguration];
    [NSURLProtocol registerClass:[KDLURLProtocol class]];
    if (![sessionConfiguration isSwizzle]) {
        [sessionConfiguration load];
    }
}

+ (void)end {
    KDLURLSessionConfiguration *sessionConfiguration = [KDLURLSessionConfiguration defaultConfiguration];
    [NSURLProtocol unregisterClass:[KDLURLProtocol class]];
    if ([sessionConfiguration isSwizzle]) {
        [sessionConfiguration unload];
    }
}

/**
 需要控制的请求

 @param request 此次请求
 @return 是否需要监控
 */
+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    
    if (![request.URL.scheme isEqualToString:@"http"] &&
        ![request.URL.scheme isEqualToString:@"https"]) {
        return NO;
    }
    //如果是已经拦截过的  就放行
    if ([NSURLProtocol propertyForKey:KeyHTTP inRequest:request] ) {
        return NO;
    }
    return YES;
}

/**
 设置我们自己的自定义请求
 可以在这里统一加上头之类的
 
 @param request 应用的此次请求
 @return 我们自定义的请求
 */
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    NSMutableURLRequest *mutableReqeust = [request mutableCopy];
    [NSURLProtocol setProperty:@YES
                        forKey:KeyHTTP
                     inRequest:mutableReqeust];
    return [mutableReqeust copy];
}

- (void)startLoading {
    
    NSURLSession *session = [NSURLSession sharedSession];
    __block NSURLSessionTask *dataTask = [session dataTaskWithRequest:self.request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"%@",[self responseJSONFromData:data]);
        
        //获取请求地址
        NSString *requestUrl = dataTask.currentRequest.URL.absoluteString;
        NSLog(@"请求地址：%@\n",requestUrl);
        //获取请求方法
        NSString *requestMethod = dataTask.currentRequest.HTTPMethod;
        NSLog(@"请求方法：%@\n",requestMethod);
        //获取请求头
        NSDictionary *headers = dataTask.currentRequest.allHTTPHeaderFields;
        NSLog(@"请求头：\n");
        for (NSString *key in headers.allKeys) {
            NSLog(@"%@:%@",key,headers[key]);
        }

        //获取请求结果
        NSString *string = [self responseJSONFromData:data];
        NSLog(@"请求结果：%@",string);
    }];
    [dataTask resume];
}


- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection{
    return YES;
}


//转换json
-(id)responseJSONFromData:(NSData *)data {
    if(data == nil) return nil;
    NSError *error = nil;
    NSString *jsonDict = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];;
    if(error) {
        NSLog(@"JSON Parsing Error: %@", error);
        //https://github.com/coderyi/NetworkEye/issues/3
        return nil;
    }
    return jsonDict;
    
}
@end
