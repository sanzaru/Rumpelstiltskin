#
# Be sure to run `pod lib lint Rumpelstiltskin.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Rumpelstiltskin'
  s.version          = '0.1.4'
  s.summary          = 'Converting Localizable.strings file int a Swift struct'

  s.description      = <<-DESC
This pod is used to replace the Laurene localization generator which does not work with Swift 5 anymore.
We only support a smal feature set of the original generator but it should be enough for the most common cases.
                       DESC

  s.homepage         = 'https://github.com/kurzdigital/Rumpelstiltskin'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Christian Braun' => 'christian.braun@kurzdigital.com' }
  s.source           = { :git => 'https://github.com/kurzdigital/Rumpelstiltskin.git', :tag => s.version.to_s }

  s.swift_version = "5.0"
  s.source_files = "main.swift"
  s.ios.deployment_target = '9.0'
end
