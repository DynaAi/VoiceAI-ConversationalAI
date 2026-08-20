Pod::Spec.new do |s|
  s.name             = 'DYNAVoiceRTCKit'
  s.version          = '1.0.1'
  s.summary          = 'Dyna Intelligent Voice RTC SDK, wrapping service auth and voice channel capabilities'
  s.homepage         = 'https://github.com/DynaAi/VoiceAI-ConversationalAI'
  s.license          = { :type => 'Proprietary' }
  s.author           = { 'VoiceAI Team' => 'voiceai@dyna.ai' }
  s.platform         = :ios, '13.0'
  # The binary is pulled from the demo repository Release page; the zip is produced by scripts/build_framework.sh.
  # The underlying RTC dependency is nested inside the xcframework, so third parties need not be aware of it.
  s.source           = {
    :http => 'https://github.com/DynaAi/VoiceAI-ConversationalAI/releases/download/v1.0.0/DYNA_AI_Voice_RTC_iOS_v1.0.1.zip'
  }
  s.vendored_frameworks = 'DYNAVoiceRTCKit.xcframework'

  s.frameworks = 'AVFoundation', 'CoreFoundation', 'SystemConfiguration', 'UIKit'
  s.libraries  = 'objc'
  s.requires_arc = true
end
