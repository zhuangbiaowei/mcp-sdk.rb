Gem::Specification.new do |spec|
  spec.name = "mcp-sdk"
  spec.version = "0.1.0"
  spec.authors = ["Zhuang Biaowei"]
  spec.email = ["zbw@kaiyuanshe.org"]

  spec.summary = "MCP SDK for Ruby"
  spec.description = "A Ruby SDK for the MCP (Multi-Channel Protocol) implementation"
  spec.homepage = "https://github.com/zhuangbiaowei/mcp-sdk.rb"
  spec.license = "MIT"

  spec.required_ruby_version = ">= 3.0.0"

  spec.files = Dir["{lib}/**/*.rb", "LICENSE", "README.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "json", ">= 2.7.1"
  spec.add_dependency "faraday", ">= 2.0.0"

  spec.add_development_dependency "bundler", ">= 2.0"
  spec.add_development_dependency "rake", ">= 13.0"
  spec.add_development_dependency "rspec", ">= 3.0"
  spec.add_development_dependency "rubocop", ">= 1.0"
end
