
Pod::Spec.new do |spec|
  spec.name         = "BotFramework"
  spec.version      = "0.0.1"
  spec.summary      = "Bot."

  spec.description  = "this will work like bot"

  spec.homepage     = "http://EXAMPLE/BotFramework"
    spec.license      = "MIT"
       spec.platform     = :ios, "13.5"

  spec.author             = { "Priyanka.Golhar" => "priyanka.golhar@ril.com" }
  spec.source       = { :git => "https://github.com/priyankagolhar/BotFramework.git", :tag => "1.0.0" }
  spec.source_files  = "BotFramework"
  spec.swift_version = "5"

end
