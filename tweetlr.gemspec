Gem::Specification.new do |s|
  s.name        = "tweetlr"
  s.version     = "0.1.30"
  s.author      = "Sven Kraeuter"
  s.email       = "sven.kraeuter@gmail.com"
  s.homepage    = "http://tweetlr.5v3n.com"
  s.summary     = "tweetlr crawls twitter for a given term, extracts photos out of the collected tweets' short urls and posts the images to tumblr."
  s.description = s.summary

  s.rubyforge_project = s.name
  s.extra_rdoc_files = %w(README.md LICENSE)

  s.add_dependency "daemons"
  s.add_dependency "eventmachine"
  s.add_dependency "curb"
  s.add_dependency "json", ">= 1.7.7"
  s.add_dependency "nokogiri"
  s.add_dependency "oauth"
  s.add_dependency "twitter"

  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rdoc"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "coveralls"
  s.add_development_dependency "fakeweb", ["~> 1.3"]

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
