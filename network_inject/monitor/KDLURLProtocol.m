//
//  KDLURLProtocol.m
//  network_inject
//
//  Created by ios on 2020/11/26.
//

#import "KDLURLProtocol.h"
#import "KDLURLSessionConfiguration.h"

static NSString *const KeyHTTP = @"KeyHTTP"; //避免canInitWithRequest和canonicalRequestForRequest的死循环

@interface KDLURLProtocol()<NSURLConnectionDataDelegate,NSURLSessionDelegate>

@property (nonatomic, strong) NSURLSessionTask *dataTask;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSData *responseData;

@end

@implementation KDLURLProtocol

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
    
    NSURLRequest *request = [[self class] canonicalRequestForRequest:self.request];
    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
    
//    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
//    NSURLSession *sessison = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue currentQueue]];
//    self.dataTask = [sessison dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
//        self.data = data;
//    }];
//    [self.dataTask resume];
}
- (void)stopLoading {
    
     [self.connection cancel];
    //获取请求地址
    NSString *requestUrl = self.connection.currentRequest.URL.absoluteString;
    NSLog(@"URL：%@\n",requestUrl);
    //获取请求方法
    NSString *requestMethod = self.connection.currentRequest.HTTPMethod;
    NSLog(@"Method：%@\n",requestMethod);
    
    //获取请求头
    NSDictionary *headers = self.connection.currentRequest.allHTTPHeaderFields;
    NSLog(@"Header：");
    for (NSString *key in headers.allKeys) {
        NSLog(@"%@ : %@",key,headers[key]);
    }
    //获取请求结果
    NSString *string = [self responseJSONFromData:self.responseData];
    NSLog(@"Result：%@",string);
}

#pragma mark - NSURLConnectionDelegate
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    [self.client URLProtocol:self didFailWithError:error];
}

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection{
    return YES;
}

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge{
    [self.client URLProtocol:self didReceiveAuthenticationChallenge:challenge];
}

#pragma mark - NSURLConnectionDataDelegate
-(NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response{
    if (response != nil) {
        [self.client URLProtocol:self wasRedirectedToRequest:request redirectResponse:response];
    }
    return request;
}

- (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)response {
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.client URLProtocol:self didLoadData:data];
    self.responseData = data;
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return cachedResponse;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [[self client] URLProtocolDidFinishLoading:self];
}

//转换json
-(id)responseJSONFromData:(NSData *)data {
    if(data == nil) return nil;
    NSError *error = nil;
    NSString *jsonDict = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];;
    if(error) {
        NSLog(@"JSON Parsing Error: %@", error);
        return nil;
    }
    return jsonDict;
}
@end
