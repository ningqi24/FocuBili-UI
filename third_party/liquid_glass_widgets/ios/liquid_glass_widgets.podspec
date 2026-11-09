#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint liquid_glass_widgets.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'liquid_glass_widgets'
  s.version          = '0.0.1'
  s.summary          = 'Reads the geometry UIKit reserves for system elements.'
  s.description      = <<-DESC
Reads the regions UIKit reserves for system elements, such as iPhone Duo's
status cluster, for the liquid_glass_widgets package.
                       DESC
  s.homepage         = 'https://github.com/sdegenaar/liquid_glass_widgets'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Sebastian Degenaar' => 'https://github.com/sdegenaar' }
  s.source           = { :path => '.' }
  s.source_files = 'liquid_glass_widgets/Sources/liquid_glass_widgets/**/*'
  s.dependency 'Flutter'
  # 上游默认 15.0；本仓库保留 iOS 13/14 支持。原生代码仅使用带可用性检查的
  # UIKit API，旧系统会在 Dart 侧自动降级，因此这里下调部署目标。
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
