Pod::Spec.new do |s|
  s.name             = "CtrlZ"
  s.version          = "1.0.0"
  s.summary          = "Edit any string in your application after it has already shipped."
  s.description      = <<-DESC

                       Need to localize to a new language after your app has already shipped? Typo in your production app? Users saying they wish you added more superlatives??

                       Simply replace NSLocalizedString with CRZLocalizedString and the power to do all of this will be yours.

                       You set up an endpoint with a json file full of strings and your app will treat it like an extended .strings file.

                       * Markdown format.
                       * Don't worry about the indent, we strip it!
                       DESC
  s.homepage         = "https://github.com/Raizlabs/CtrlZ"
  s.license          = 'MIT'
  s.author           = { "Spencer Poff" => "spencer@raizlabs.com" }
  s.source           = { :git => "https://github.com/Raizlabs/CtrlZ.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/*.{h,m}', 'Pod/Classes/Private/**/*.{h,m}'
  s.public_header_files = 'Pod/Classes/*.h'
  s.private_header_files = 'Pod/Classes/Private/**/*.h'
end
