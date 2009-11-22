require 'sinatra'
require 'erb'
require 'grit'
include Grit

Git.git_timeout = 60

set :logging, false
set :host, 'localhost'
set :port, 6568

class String
  def ucfirst
    out = self
    out[0] = out[0..0].upcase if length > 0
    out
  end
end

def supplied?(thing, thing_name)
  while thing.nil? or thing.gsub(/\s+/, '') == ''
    print "No #{thing_name} supplied; please enter #{thing_name}, or nothing to exit: "
    thing = gets.chomp
    exit if thing == ''
  end
  thing
end

def get_commits(repo, file_name, branch)
  log_data = repo.git.log({ :pretty => 'raw' }, "--follow", '--topo-order', '-p', branch, "--", file_name)
  commit_diff_data = []
  log_data.split("\n").each do |c|
    if c =~ /^commit /
      commit_diff_data << [c]
    else
      commit_diff_data.last << c
    end
  end

  commit_diff_data.map do |c|
    commit = []
    0.upto(c.length) do |i|
      if c[i] !~ /^diff/
        commit << c[i]
      else
        break
      end
    end
    diff = c[(commit.length)..-1]

    { :commit => Commit.list_from_string(repo, commit.join("\n"))[0], :diff => Grit::Diff.list_from_string(repo, diff.join("\n"))[0] }
  end.reverse
end

repo_dir, file_name, branch = ARGV[0..3]

repo_dir = supplied?(repo_dir, "repo")
file_name = supplied?(file_name, "file")
branch = supplied?(branch, "branch")

unless File.exists?(File.expand_path(repo_dir))
  puts "The repo you spplied doesn't exist; please check the data you supplied and try again."
  exit
end

repo = Repo.new(File.expand_path(repo_dir))

puts "Loading commits..."

class Actor
  def name_email
    "#{name} <#{email}>"
  end
  
  def ==(other)
    name_email == other.name_email
  end
end

class Time
  def nice
    strftime("%A %d/%m/%Y %I:%M %p")
  end
end

commits = get_commits(repo, file_name, branch)

if commits.empty?
  puts "No commits found for supplied data; pleast check the data you supplied and try again."
  exit
end

puts "Loaded commits"

get '/' do
  @commits = commits

  erb :index
end

get '/commit/*' do
  @delay = 1
  @lps_change = 100
  @lps_scroll = 20
  @max_time = 10
  @repo_dir = repo_dir
  @commits = commits
  @commit_index = params[:splat].first.to_i
  commit_diff = commits[@commit_index]
  @commit, @diff = commit_diff[:commit], commit_diff[:diff] 
  
  @diff_data = diff_to_html(@commit, @diff)
#  puts @diff_data.inspect
#  puts @diff_data[:content].inspect

  content_type 'text/javascript'
  erb :commit, :layout => false
end

get '/show/:commit/*' do
  blob = (repo.commit(params[:commit]).tree / params[:splat].first)
  blob.data
end

helpers do
  include Rack::Utils
  alias_method :h, :escape_html
  
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

puts "Waiting to launch gistory..."

Thread.new do
  sleep(1)

  #if RUBY_PLATFORM =~ /(win|w)32$/
  #  `start http://localhost:6568/`
  if RUBY_PLATFORM =~ /darwin/
    `open http://localhost:6568/`
    puts "Launched gistory"
  else
    puts "Please open your web browser and visit http://localhost:6568/"
  end
end