require 'rubygems'
require 'rake'
require 'rake/rdoctask'
require 'spec/rake/spectask'
# <<<<<<< HEAD
require File.expand_path('../lib/happymapper/version', __FILE__)

Spec::Rake::SpecTask.new do |t|
  t.ruby_opts << '-rubygems'
  t.verbose = true
end
task :default => :spec

desc 'Builds the gem'
task :build do
  sh "gem build happymapper.gemspec"
end

desc 'Builds and installs the gem'
task :install => :build do
  sh "gem install happymapper-#{HappyMapper::Version}"
end

# =======
# require "lib/happymapper/version"
# 
# Echoe.new('nokogiri-happymapper', HappyMapper::Version) do |p|
#   p.description     = "object to xml mapping library, using nokogiri (fork from John Nunemaker's Happymapper)"
#   p.install_message = "May you have many happy mappings!"
#   p.url             = "http://github.com/dam5s/happymapper"
#   p.author          = "Damien Le Berrigaud, John Nunemaker, David Bolton, Roland Swingler"
#   p.email           = "damien@meliondesign.com"
#   p.extra_deps      = ['nokogiri >=1.4.0']
#   p.need_tar_gz     = false
# end
# >>>>>>> dam5s

desc 'Tags version, pushes to remote, and pushes gem'
task :release => :build do
  sh "git tag v#{HappyMapper::Version}"
  sh "git push origin master"
  sh "git push origin v#{HappyMapper::Version}"
  sh "gem push happymapper-#{HappyMapper::Version}.gem"
end

# <<<<<<< HEAD
desc 'Upload website files to rubyforge'
task :website do
  sh %{rsync -av website/ jnunemaker@rubyforge.org:/var/www/gforge-projects/happymapper}
end

Rake::RDocTask.new do |r|
  r.title    = 'HappyMapper Docs'
  r.main     = 'README.rdoc'
  r.rdoc_dir = 'doc'
  r.rdoc_files.include("README.rdoc", "lib/**/*.rb")
end
# =======
# Rake::Task[:default].prerequisites.clear
# task :default => :spec
# Spec::Rake::SpecTask.new do |t|
#   t.spec_files = FileList["spec/**/*_spec.rb"]
# end
# >>>>>>> dam5s
