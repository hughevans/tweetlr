Gem::Specification.new do |s|
  s.name        = "tweetlr"
  s.version     = "0.1.4pre4"
  s.author      = "Sven Kraeuter"
  s.email       = "mail@svenkraeuter.com"
  s.homepage    = "http://github.com/5v3n/#{s.name}"
  s.summary     = "tweetlr crawls twitter for a given term, extracts photos out of the collected tweets' short urls and posts the images to tumblr."
  s.description = s.summary

  s.rubyforge_project = s.name
  s.extra_rdoc_files = %w(README.md LICENSE)

  s.add_dependency "daemons"
  s.add_dependency "eventmachine"
  s.add_dependency "curb"
  s.add_dependency "json"

  s.add_development_dependency "rake",            "~> 0.8.7"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rdoc"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
