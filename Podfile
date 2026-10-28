# 支付宝 iOS SDK
#
# 说明：
#   支付宝 SDK 是必需依赖，没有模拟支付分支。
#   在 macOS 执行 pod install 后，用 XyPay.xcworkspace 打开工程。
#
# 用法：在 ios 目录下执行
#   sudo gem install cocoapods      # 如未安装
#   pod install
#   open XyPay.xcworkspace

platform :ios, '15.0'

source 'https://cdn.cocoapods.org/'
# 国内网络可改用清华镜像：
# source 'https://mirrors.tuna.tsinghua.edu.cn/git/CocoaPods/Specs.git'

target 'XyPay' do
  # 两端 SDK 的版本号独立；传入同样的服务端签名订单串。
  pod 'AlipaySDK-iOS', '15.8.30'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end
