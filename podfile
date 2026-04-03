
platform :ios, '12.0'
use_modular_headers! 
 target 'YiTongProject' do
 pod 'JSONModel'
 pod 'SDWebImage'
 pod 'Singleton'
 pod 'MBProgressHUD'
 pod 'Masonry'
 
 pod 'AFNetworking', '3.2.1'
 pod 'MJExtension'
 pod 'MJRefresh'
 pod 'FLAnimatedImage'
 pod 'JGProgressHUD'
 

 pod 'FBSDKCoreKit', '~> 18'
 pod 'Firebase/Analytics', '~> 11.15.0'
 pod 'AppsFlyerFramework', '~> 6.17.6'

 pod 'UMCommon'
 pod 'UMDevice'
 pod 'UMAPM' 

end

# AFNetworking 3.2.1：Xcode 较新版本下 #import <netinet6/in6.h> 会报
# "Use of private header from outside its module"；Darwin 上 IPv6 类型已由 <netinet/in.h> 提供。
post_install do |installer|
  %w[AFHTTPSessionManager.m AFNetworkReachabilityManager.m].each do |name|
    path = installer.sandbox.root.join('AFNetworking/AFNetworking', name)
    next unless File.file?(path)

    contents = File.read(path)
    patched = contents.gsub(%r{^\s*#import\s+<netinet6/in6\.h>\s*\n}, '')
    File.write(path, patched) if patched != contents
  end
end

