require_relative "lib/feed2gram/version"

Gem::Specification.new do |spec|
  spec.name = "feed2gram"
  spec.version = Feed2Gram::VERSION
  spec.authors = ["Justin Searls"]
  spec.email = ["searls@gmail.com"]

  spec.summary = "Reads an Atom feed and posts its entries to Instagram"
  spec.homepage = "https://github.com/searls/feed2gram"
  spec.license = "GPL-3.0-or-later"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "nokogiri", "~> 1.15"
end
