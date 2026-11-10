require_relative "lib/fog/upcloud/version"

Gem::Specification.new do |spec|
  spec.name = "fog-upcloud"
  spec.version = Fog::UpCloud::VERSION
  spec.authors = [ "Lewis Buckley" ]
  spec.email = [ "lewis@37signals.com" ]

  spec.summary = "UpCloud's API (1.3) for fog"
  spec.description = "A fog provider for UpCloud: servers, plans, zones, storages, templates and server firewall rules, through UpCloud's 1.3 API."
  spec.homepage = "https://github.com/lewispb/fog-upcloud"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*.rb", "README.md", "LICENSE"]
  spec.require_paths = [ "lib" ]

  spec.add_dependency "fog-core", "~> 2.6"
  spec.add_dependency "fog-json", "~> 1.2"
end
