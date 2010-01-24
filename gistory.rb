abort %(Usage:
  ruby gistory.rb repo_path file_path [branch_other_than_master]
) unless ARGV.size.between?(2, 3)

repo_path = File.expand_path(ARGV.first)
abort "Error: #{repo_path} does not exist" unless File.exist?(repo_path)

require 'grit'

Grit::Git.git_timeout = 60

class Grit::Actor
  def name_email
    "#{name} <#{email}>"
  end
  
  def ==(other)
    name_email == other.name_email
  end
end

repo = begin
  Grit::Repo.new(repo_path)
rescue Grit::InvalidGitRepositoryError
  abort "Error: #{repo_path} is not a git repo"
end

$stderr.puts "Loading commits ..."

file = ARGV[1]
branch = ARGV[2] || 'master'

require 'lib/gistory'

commits = Gistory::CommitParser.parse(repo, file, branch)
Gistory::CommitParser.index_and_generate!(commits)

abort %(Error: Couldn't find any commits.
Are you sure this is a git repo and the file exists?) if commits.empty?

$stderr.puts "Loaded commits"

require 'sinatra'
require 'json'
require 'erb'

set :logging, false
set :host, 'localhost'
set :port, 6568

get '/' do
  @delay = 1
  @lps_change = 5
  @lps_scroll = 20
  @commits = commits
  erb :index
end

get '/commits' do
  @commits = commits

  content_type 'text/javascript'
  erb :commits, :layout => false
end

get /^\/commit\/(\d+)$/ do
  @commit_index = params['captures'][0].to_i
  @commits = commits

  @commit_diff = commits[@commit_index]

  content_type 'text/javascript'
  erb :commit, :layout => false
end

#Given a commit number, returns the blob as of that commit
get '/blob/*' do
  @commit_index = params[:splat].first.to_i
  diff = commits[@commit_index][:diff]
  
#  puts diff.inspect

  blob = diff.deleted_file ? diff.a_blob : diff.b_blob
puts blob.data
  body blob.data
end

helpers do
  def j(str)
    str.to_s.gsub('\\', '\\\\\\\\').gsub(/[&"><\n\r]/) { |special| { '&' => '\u0026', '>' => '\u003E', '<' => '\u003C', '"' => '\"', "\n" => "\\n", "\r" => "\\r" }[special] }
  end
end

$stderr.puts "Waiting to launch gistory..."

Thread.new do
  sleep(1)

  #if RUBY_PLATFORM =~ /(win|w)32$/
  #  `start http://localhost:6568/`
  if RUBY_PLATFORM =~ /darwin/
    `open http://localhost:6568/`
    $stderr.puts "Launched gistory"
  else
    puts "Please open your web browser and visit http://localhost:6568/"
  end
end
