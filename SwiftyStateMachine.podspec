Pod::Spec.new do |s|

    s.name          = File.basename(__FILE__).chomp(".podspec")
    s.version       = "1.0.0"
    s.license       = s.name
    s.summary       = s.name
    s.description   = "Adjusted StateMachine from https://github.com/narfdotpl/SwiftyStateMachine"
    s.homepage      = "https://github.com/ScientificDimension/SwiftyStateMachine"
    s.author        = "Oleg K."
    s.platform      = :ios, "10.0"
    s.swift_version = '4'
    s.source        = { :git => 'https://github.com/ScientificDimension/SwiftyStateMachine', :branch => 'develop', :tag => s.version.to_s}
    s.source_files  = ["StateMachine/**/*.{swift, h}", "StateMachine/**/*.xib"]
    s.resource      = ['StateMachine/**/*.{xcassets}']
    s.xcconfig      = {"HEADER_SEARCH_PATHS" => '$(PODS_ROOT)/StateMachine'}

end
