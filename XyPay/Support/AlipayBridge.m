//
//  AlipayBridge.m
//  XyPay
//

#import "AlipayBridge.h"

// SDK 是必需依赖，不提供模拟支付分支。
#import <AlipaySDK/AlipaySDK.h>

@implementation AlipayBridge

+ (void)payWithOrderString:(NSString *)orderString
                    scheme:(NSString *)scheme
                completion:(XYAlipayResultHandler)completion {
    if (orderString.length == 0) {
        if (completion) {
            completion(@{ @"resultStatus": @"-1", @"memo": @"orderStr 为空" });
        }
        return;
    }

    // 回调线程不确定，统一在主线程抛给上层。
    [[AlipaySDK defaultService] payOrder:orderString
                              fromScheme:scheme
                                callback:^(NSDictionary *resultDic) {
        if (!completion) { return; }
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(resultDic);
        });
    }];
}

+ (void)handleOpenURL:(NSURL *)url completion:(XYAlipayResultHandler)completion {
    if (!url) {
        if (completion) { completion(nil); }
        return;
    }

    // 支付宝 App 支付完成后回跳，必须把 URL 交回 SDK 才能拿到真实结果
    [[AlipaySDK defaultService] processOrderWithPaymentResult:url
                                               standbyCallback:^(NSDictionary *resultDic) {
        if (!completion) { return; }
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(resultDic);
        });
    }];
}

@end
