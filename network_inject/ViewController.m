//
//  ViewController.m
//  network_inject
//
//  Created by ios on 2020/11/26.
//

#import "ViewController.h"

@interface ViewController ()<NSURLSessionDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSURL *httpDnsURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://180.101.49.12"]];
    NSMutableURLRequest *mutableReq = [NSMutableURLRequest requestWithURL:httpDnsURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval: 10];
    //设置host为原始域名
    [mutableReq setValue:@"www.baidu.com" forHTTPHeaderField:@"host"];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *sessison = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue currentQueue]];
    
    NSURLSessionTask *task = [sessison dataTaskWithRequest:mutableReq completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!error) {
            NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"_________response: %@", string);
        }else{
            NSLog(@"_________error: %@", error);
        }
    }];
    
    [task resume];
}

/**
 支持ip直连
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * __nullable credential))completionHandler {
    if (!challenge) {
        return;
    }

    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    NSURLCredential *credential = nil;

    //获取原始域名信息
    NSString *host = @"www.baidu.com";//[[self.kdl_dataTask.currentRequest allHTTPHeaderFields] objectForKey:@"host"];
    if (!host) {
        host = task.currentRequest.URL.host;
    }
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        if ([self evaluateServerTrust:challenge.protectionSpace.serverTrust forDomain:host]) {
            disposition = NSURLSessionAuthChallengeUseCredential;
            credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        } else {
            disposition = NSURLSessionAuthChallengePerformDefaultHandling;
        }
    } else {
        disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    }
    completionHandler(disposition,credential);
}

- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust forDomain:(NSString *)domain {
    NSMutableArray *policies = [NSMutableArray array];
    if (domain) {
        [policies addObject:(__bridge_transfer id)SecPolicyCreateSSL(true, (__bridge CFStringRef)domain)];
    } else {
        [policies addObject:(__bridge_transfer id)SecPolicyCreateBasicX509()];
    }
    SecTrustSetPolicies(serverTrust, (__bridge CFArrayRef)policies);
    SecTrustResultType result;
    SecTrustEvaluate(serverTrust, &result);
    return (result == kSecTrustResultUnspecified || result == kSecTrustResultProceed);
}

@end
