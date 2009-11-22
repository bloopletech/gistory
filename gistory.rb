$: << "lib"

abort %(Usage:
  ruby gistory.rb repo_path file_path [branch_other_than_maste]
) unless ARGV.size.between?(2,3)

repo_path = File.expand_path(ARGV.first)
abort "Error: #{repo_path} does not exist" unless File.exist?(repo_path)

require 'grit'

Grit::Git.git_timeout = 60

Grit::Actor.class_eval do
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
require 'lib/gistory'

file = ARGV[1]
branch = ARGV[2] || 'master'

commits = Gistory::CommitParser.parse(repo, file, branch)
abort %(Error: Couldn't find any commits.
Are you sure this is a git repo and the file exists?) if commits.empty?

$stderr.puts "Loaded commits"

require 'sinatra'
require 'erb'

set :logging, false
set :host, 'localhost'
set :port, 6568

get '/commits' do
  commits.to_json
end

get '/' do
  @commits = commits

  erb :index
end

get '/commit/*' do
  @delay = 1
  @lps_change = 100
  @lps_scroll = 20
  @max_time = 10
  @repo_dir = repo_path
  @commits = commits
  @commit_index = params[:splat].first.to_i
  commit_diff = commits[@commit_index]
  @commit, @diff = commit_diff[:commit], commit_diff[:diff] 
  
  @diff_data = diff_to_html(@commit, @diff)
#  puts @diff_data.inspect
#  puts @diff_data[:content].inspect

  @diff_content = @diff_data[:content] || []

  @textual_add_remove_changes = @diff_content.select do |change|
    change[:mode] == :add || change[:mode] == :remove
  end.reject do |change|
    change[:type] == "change" # is binary
  end

  content_type 'text/javascript'
  erb :commit, :layout => false
end

get '/show/:commit/*' do
  blob = (repo.commit(params[:commit]).tree / params[:splat].first)
  blob.data
end

helpers do
  def h(content)
    Rack::Utils.escape_html(content)
  end
  
  def diff_to_html(commit, diff)
    if diff.diff =~ /^rename/
      { :type => 'rename', :message => diff.diff.ucfirst.gsub("\n", " => "), :content => nil }
    elsif diff.diff =~ /^Binary/
      if diff.new_file
        { :type => 'new', :message => "Created binary file #{h diff.b_path}", :content => nil }
      elsif diff.deleted_file
        { :type => 'delete', :message => "Deleted binary file #{h diff.a_path}", :content => nil }
      else
        { :type => 'change', :message => "Changed binary file #{h diff.a_path}", :content => nil }
      end
    else
      #puts diff.diff
      content_lines = diff.diff.split(/\n/)[2..-1]
      line_offset = 1
      changes = []
      should_change = false
      content_lines.each do |l|
        #puts "line_offset: #{line_offset}, l: #{l}"
        if l =~ /^(\@\@ \-(\d+),(\d+) \+(\d+),(\d+) \@\@)/
          line_offset = $4.to_i == 0 ? 1 : $4.to_i
        else
          if l == '\ No newline at end of file' && changes.length >= 2 && changes.last[:mode] == :add && changes[-2][:mode] == :remove &&            changes.last[:times] == 1 && changes[-2][:times] == 1
            changes.pop
            changes.pop
          elsif l =~ /^\+/
            changes << { :start => line_offset, :lines => "", :times => 0, :mode => :add } if should_change or changes.empty? or changes.last[:mode] != :add
            should_change = false
            changes.last[:times] += 1
            lt = h(l[1..-1]).gsub(/  /, " &nbsp;")
            changes.last[:lines] << "<div>#{lt == '' ? "&nbsp;" : lt}</div>"
          elsif l =~ /^-/
            changes << { :start => line_offset, :times => 0, :mode => :remove } if should_change or changes.empty? or changes.last[:mode] != :remove
            should_change = false
            changes.last[:times] += 1
            line_offset -= 1
          else
            should_change = true
          end
          line_offset += 1
        end
      end
      #puts changes.inspect

      if diff.new_file
        { :type => 'new', :message => "Created file #{h diff.b_path}", :content => changes }
      elsif diff.deleted_file
        { :type => 'delete', :message => "Deleted file #{diff.a_path}", :content => changes }
      else
        { :type => 'change', :message => "Changed file #{diff.a_path}", :content => changes }
      end
    end
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