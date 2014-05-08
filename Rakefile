require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'rspec/core/rake_task'
require 'rdoc/task'

Rake::TestTask.new do |t|
  t.libs << "code/lib"
  t.test_files = FileList['test/**/*.rb']
end

RSpec::Core::RakeTask.new do |spec|
  spec.pattern = 'spec/erector/*_spec.rb'
  spec.rspec_opts = [Dir["lib"].to_a.join(':')]
end

Rake::RDocTask.new do |rdoc|
  files =['README.md', 'LICENSE', 'code/**/*.rb']
  rdoc.rdoc_files.add(files)
  rdoc.main = "README.md" # page to start on
  rdoc.title = "RedSide Docs"
  rdoc.rdoc_dir = 'doc/rdoc' # rdoc output folder
  rdoc.options << '--line-numbers'
end
