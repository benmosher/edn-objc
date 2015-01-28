# coding: utf-8

Pod::Spec.new do |s|

  s.name         = "edn-objc"
  s.version      = "0.5.2"
  s.summary      = "An edn implementation for Objective-C platforms (i.e. iOS, OSX)."

  s.homepage     = "https://github.com/benmosher/edn-objc"

  s.requires_arc = true

  s.license      = "EPL v1"
  s.author       = { "Ben Mosher" => "me@benmosher.com"}
  s.source       = { :git => "https://github.com/benmosher/edn-objc.git", :tag => "v0.5.2" }
  s.source_files  = "edn-objc"
end
