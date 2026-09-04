#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint xmpp_plugin.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'xmpp_plugin'
  s.version          = '2.2.13'
  s.summary          = 'Xmpp plugin which helps to connect with xmpp via native channels and native libs like smack android and ios via xmppframework'
  s.description      = <<-DESC
A new Flutter project.
                       DESC
  s.homepage         = 'https://github.com/vavadiyahiren/xmpp_plugin'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'hiren@xrstudio.in' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'XMPPFramework/Swift'
  # XMPPFramework declares an iOS 8.0 floor and an unversioned dependency on
  # CocoaLumberjack, so it silently resolves to whatever CocoaLumberjack is
  # newest. CocoaLumberjack >= 3.9 raised its own floor to iOS 12.0, which is
  # higher than XMPPFramework's own compiled target, so Xcode rejects the
  # build ("Compiling for iOS 9.0, but module 'CocoaLumberjack' has a minimum
  # deployment target of iOS 12.0") in every app that depends on this plugin.
  # Pinning to the 3.7.x line (iOS 9.0 floor) keeps the whole XMPPFramework
  # dependency tree internally consistent without requiring a Podfile
  # post_install workaround in every consuming project.
  s.dependency 'CocoaLumberjack', '~> 3.7.0'
  s.platform = :ios, '12.0'
  s.ios.deployment_target = '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
