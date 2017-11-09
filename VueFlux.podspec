Pod::Spec.new do |spec|
  spec.name = 'VueFlux'
  spec.version  = '0.1.0'
  spec.author = { 'ra1028' => 'r.fe51028.r@gmail.com' }
  spec.homepage = 'https://github.com/ra1028'
  spec.summary = 'Unidirectional Data Flow State Management for Swift - Inspired by Vuex and Flux'
  spec.source = { :git => 'https://github.com/ra1028/VueFlux.git', :tag => spec.version.to_s }
  spec.license = { :type => 'MIT', :file => 'LICENSE' }
  spec.source_files = 'Sources/**/*.swift'
  spec.requires_arc = true
  spec.osx.deployment_target = '10.9'
  spec.ios.deployment_target = '9.0'
  spec.watchos.deployment_target = '2.0'
  spec.tvos.deployment_target = "9.0"
end
