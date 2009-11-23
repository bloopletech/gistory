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

abort %(Error: Couldn't find any commits.
Are you sure this is a git repo and the file exists?) if commits.empty?

$stderr.puts "Loaded commits"

require 'sinatra'
require 'erb'

set :logging, false
set :host, 'localhost'
set :port, 6568

get '/' do
  @commits = commits
  erb :index
end

get '/commit/*' do
  @delay = 1
  @lps_change = 5
  @lps_scroll = 20
  @max_time = 10
  @repo_dir = repo_path
  @commits = commits
  @commit_index = params[:splat].first.to_i
  commit_diff = commits[@commit_index]
  @commit, @diff = commit_diff[:commit], commit_diff[:diff] 

  @diff_data = Gistory::DiffToHtml.diff_to_html(@diff)

  @diff_content = @diff_data[:content] || []

  @textual_add_remove_changes = @diff_content.select do |change|
    change[:mode] == :add || change[:mode] == :remove
  end.reject do |change|
    change[:type] == "change" # is binary
  end

  content_type 'text/javascript'
  erb :commit, :layout => false
end

helpers do
  #TODO Get rid of, or remove duplication
  def h(content)
    Rack::Utils.escape_html(content)
  end

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