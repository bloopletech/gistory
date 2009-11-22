require 'spec/rake/spectask'

Spec::Rake::SpecTask.new do |spec|
  spec.libs << 'lib' << 'spec' << '-c'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end
