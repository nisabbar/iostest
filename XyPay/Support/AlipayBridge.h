//
//  AlipayBridge.h
//  XyPay
//
//  对支付宝 iOS SDK（AlipaySDK.framework）的最小封装。
//  Swift 侧通过本文件调用 SDK；构建前必须安装 Podfile 中的支付宝依赖。
//
//  对接关系：
//    Android  com.alipay.sdk.app.PayTask#payV2(orderStr, true)
//    iOS      [[AlipaySDK defaultService] payOrder:fromScheme:callback:]
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 支付结果回调，字典结构与支付宝 SDK 保持一致：
/// @{ @"resultStatus": @"9000", @"result": @"...", @"memo": @"..." }
typedef void (^XYAlipayResultHandler)(NSDictionary<NSString *, id> * _Nullable result);

@interface AlipayBridge : NSObject

/// 发起支付。必须在主线程调用。
/// @param orderString 服务端签好名的 orderStr（与 Android 的 orderInfo 完全相同）
/// @param scheme      用于支付完成后回跳本 App 的 URL Scheme，需与 Info.plist 中一致
/// @param completion  结果回调（主线程）
+ (void)payWithOrderString:(NSString *)orderString
                    scheme:(NSString *)scheme
                completion:(XYAlipayResultHandler)completion
    NS_SWIFT_NAME(pay(orderString:scheme:completion:));

/// 处理支付宝回跳的 URL（支付完成后由支付宝 App 拉起本 App 时调用）
+ (void)handleOpenURL:(NSURL *)url completion:(XYAlipayResultHandler)completion
    NS_SWIFT_NAME(handleOpenURL(_:completion:));

@end

NS_ASSUME_NONNULL_END
