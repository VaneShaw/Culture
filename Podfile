
platform :ios, '12.0'
use_modular_headers! 
 target 'YiTongProject' do
 pod 'JSONModel'
 pod 'SDWebImage'
 pod 'Singleton'
 pod 'MBProgressHUD'
 pod 'Masonry'
 
 pod 'AFNetworking', '~> 4.0'
 pod 'MJExtension'
 pod 'MJRefresh'
 pod 'FLAnimatedImage'
 pod 'JGProgressHUD'
 
 pod 'JXPagingView'


 pod 'FBSDKCoreKit', '~> 18'
 pod 'Firebase/Analytics', '~> 11.15.0'
 pod 'AppsFlyerFramework', '~> 6.17.6'

 pod 'UMCommon'
 pod 'UMDevice'
 pod 'UMAPM' 

end

# Xcode 15+ / 新 SDK：`netinet6/in6.h` 在 Darwin 模块中视为私有头，配合 `use_modular_headers!` 编译 AFNetworking 会报错。
# Apple 平台上 IPv6 的 `sockaddr_in6` 等已由 `<netinet/in.h>` 提供，去掉多余 import 即可。
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    end
  end

  %w[AFNetworkReachabilityManager.m AFHTTPSessionManager.m].each do |name|
    path = installer.sandbox.root.join('AFNetworking/AFNetworking', name)
    next unless File.file?(path)

    contents = File.read(path)
    next unless contents.include?('netinet6/in6.h')

    File.write(path, contents.gsub(/^#import <netinet6\/in6.h>\s*\n/, ''))
  end
end

