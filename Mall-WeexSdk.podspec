# coding: utf-8
Pod::Spec.new do |s|

  s.name         = "Mall-WeexSdk"

  s.version      = "0.19.0.01"

  s.summary      = "Mall WeexSDK Source ."

  s.description  = <<-DESC
                   A framework for building Mobile cross-platform UI
                   DESC

  s.homepage     = "https://github.com/brahmapaytm/incubator-weex"
  s.license = {
    :type => 'Copyright',
    :text => <<-LICENSE
           Alibaba-INC copyright
    LICENSE
  }
  s.authors      = { "brahmapaytm"      => "brammanand.soni@paytmmall.com"
                   }
  s.platform     = :ios
  s.ios.deployment_target = '8.0'
  s.source =  { :git => 'https://github.com/brahmapaytm/incubator-weex.git', :tag => '0.19.0.01' }
  s.source_files = 'ios/sdk/WeexSDK/Sources/**/*.{h,m,mm,c,cpp}'
  s.resources = 'pre-build/*.js','ios/sdk/WeexSDK/Resources/wx_load_error@3x.png'

  s.user_target_xcconfig  = { 'FRAMEWORK_SEARCH_PATHS' => "'$(PODS_ROOT)/Mall-WeexSdk'" }
  s.requires_arc = true
  s.prefix_header_file = 'ios/sdk/WeexSDK/Sources/Supporting Files/WeexSDK-Prefix.pch'

#  s.xcconfig = { "GCC_PREPROCESSOR_DEFINITIONS" => '$(inherited) DEBUG=1' }

  s.private_header_files = 'ios/sdk/WeexSDK/Sources/Component/RecycleList/WXJSASTParser.h',
                           'ios/sdk/WeexSDK/Sources/Layout/WXScrollerComponent+Layout.h'

  s.xcconfig = { "OTHER_LINK_FLAG" => '$(inherited) -ObjC'}

  s.frameworks = 'CoreMedia','MediaPlayer','AVFoundation','AVKit','JavaScriptCore', 'GLKit', 'OpenGLES', 'CoreText', 'QuartzCore', 'CoreGraphics'
  s.libraries = "stdc++"

end
