require 'rubygems'
require 'rake/gempackagetask'

spec = Gem::Specification.new do |s|
        s.name = 'racket'
        s.version = '0.1.4'
        s.platform = Gem::Platform::RUBY
        s.summary = "Racket is a way to easily pack and unpack packets"

        s.author = "Di Cioccio Lucas"
        s.email = "lucas.dicioccio<@nospam@>frihd.net"
        s.rubyforge_project = 'racket'
        s.homepage = 'http://rubyforge.org/projects/racket/'

        s.files = ['README.txt', 'LICENSE.txt', 'gpl-3.0.txt', 'Rakefile', 'TODO', 'lib/racket.rb', 'lib/field.rb', 'lib/errors.rb', 'lib/stream_parser.rb']

        s.require_path = 'lib'

        s.has_rdoc = false
end

Rake::GemPackageTask.new(spec) do |pkg|
        pkg.need_tar = true
end

task :gem => "pkg/#{spec.name}-#{spec.version}.gem" do
        puts "generated #{spec.version}"
end

