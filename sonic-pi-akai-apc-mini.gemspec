Gem::Specification.new do |spec|
  spec.name = "sonic-pi-akai-apc-mini"
  spec.version = "0.3.0"
  spec.authors = ["Sergio Gil"]
  spec.email = ["sgilperez@gmail.com"]

  spec.summary = "Utility functions to use the Akai APC mini MIDI controller with Sonic Pi"
  spec.homepage = "https://github.com/porras/sonic-pi-akai-apc-mini"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.metadata["rubygems_mfa_required"] = "true"
  spec.post_install_message = "Remember to run sonic-pi-akai-apc-mini to get instructions on how to load the new version into Sonic Pi"
end
