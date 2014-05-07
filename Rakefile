require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'rspec/core/rake_task'


Rake::TestTask.new do |t|
  t.test_files = FileList['tests/**/*.rb']
end

RSpec::Core::RakeTask.new do |spec|
  spec.pattern = 'spec/erector/*_spec.rb'
  spec.rspec_opts = [Dir["lib"].to_a.join(':')]
end
