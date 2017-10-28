# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'juwelier'
Juwelier::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://guides.rubygems.org/specification-reference/ for more options
  gem.name = "funkygps"
  gem.homepage = "http://github.com/mmolhoek/funkygps"
  gem.license = "MIT"
  gem.summary = %Q{Load gps track files on your Raspberry PI PaPiRus Display}
  gem.description = %Q{This is not a tracker gem. It is a full blown GPS tool}
  gem.email = "mischamolhoek@gmail.com"
  gem.authors = ["Mischa Molhoek"]

  # dependencies defined in Gemfile
end
Juwelier::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

desc "Code coverage detail"
task :simplecov do
  ENV['COVERAGE'] = "true"
  Rake::Task['test'].execute
end

task :default => :test

require 'yard-doctest'
YARD::Doctest::RakeTask.new do |task|
    task.doctest_opts = %w[-v]
    task.pattern = 'lib/**/*.rb'
end

