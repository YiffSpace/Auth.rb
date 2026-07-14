# frozen_string_literal: true

require_relative("lib/yiffspace/auth/version")

Gem::Specification.new do |spec|
  spec.name                  = "yiffspace-auth"
  spec.version               = YiffSpace::Auth::VERSION
  spec.authors               = ["Donovan_DMC"]
  spec.email                 = ["hewwo@yiff.rocks"]
  spec.homepage              = "https://yiff.space"
  spec.summary               = "Logto-based auth engine for https://yiff.space and related projects"
  spec.description           = spec.summary
  spec.license               = "MIT"
  spec.required_ruby_version = ">= 3.4.1"

  spec.metadata["allowed_push_host"]     = "https://rubygems.org"
  spec.metadata["homepage_uri"]          = spec.homepage
  spec.metadata["source_code_uri"]       = "https://github.com/YiffSpace/Auth.rb"
  spec.metadata["changelog_uri"]         = "https://github.com/YiffSpace/Auth.rb/blob/master/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,lib}/**/*", "LICENSE", "Rakefile", "README.md", "CHANGELOG.md"]
  end

  spec.add_dependency("httparty", ">= 0.24")
  spec.add_dependency("logto", ">= 0.2.0")
  spec.add_dependency("rails", ">= 7.1")
  spec.add_dependency("yiffspace", ">= 0.1.0")
  spec.add_dependency("zeitwerk", ">= 2.6")
end
