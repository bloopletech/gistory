require 'rubygems'
require 'sinatra'
require 'erb'
require 'grit'
include Grit

class String
  def ucfirst
    out = self
    out[0] = out[0..0].upcase if length > 0
    out
  end
end

def supplied?(thing, thing_name)
  if thing.nil? or thing.gsub(/\s+/, '') == ''
    puts "No #{thing_name} supplied"
    exit
  end
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

supplied?(repo_dir, "repo")
supplied?(file_name, "file")
supplied?(branch, "branch")

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

puts "Loaded commits"

get '/' do
  @commits = commits

  erb :index
end

get '/commit/*' do
  @repo_dir = repo_dir
  @commits = commits
  @commit_index = params[:splat].first.to_i
  commit_diff = commits[@commit_index]
  @commit, @diff = commit_diff[:commit], commit_diff[:diff]
  puts @commit.sha  
  
  @diff_data = diff_to_html(@commit, @diff)
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
      { :type => 'rename', :message => diff.diff.ucfirst, :content => nil }
    elsif diff.diff =~ /^Binary/
      if diff.new_file
        { :type => 'new', :message => "Created binary file <a href='/show/#{commit.sha}/#{h diff.b_path}'>#{h diff.b_path}</a>", :content => nil }
      elsif diff.deleted_file
        { :type => 'delete', :message => "Deleted binary file #{h diff.a_path}", :content => nil }
      else
        { :type => 'change', :message => "Changed binary file <a href='/show/#{commit.sha}/#{h diff.a_path}'>#{h diff.a_path}</a>", :content => nil }
      end
    else
      puts diff.diff
      content_lines = diff.diff.split(/\n/)[2..-1]
      line_offset = 1
      changes = []
      content_lines.each do |l|
        puts "line_offset: #{line_offset}, l: #{l}"
        if l =~ /^(\@\@ \-(\d+),(\d+) \+(\d+),(\d+) \@\@)/
          line_offset = $2.to_i == 0 ? 1 : $2.to_i
        else
          if l =~ /^\+/
            changes << { :start => line_offset, :lines => "", :mode => :add } if changes.empty? or changes.last[:mode] != :add
            changes.last[:mode] = :add
            lt = h(l[1..-1]).gsub(' ', "&nbsp;")
            changes.last[:lines] << "<div>#{lt == '' ? "&nbsp;" : lt}</div>"
          elsif l =~ /^-/
            changes << { :start => line_offset, :times => 0, :mode => :remove } if changes.empty? or changes.last[:mode] != :remove
            changes.last[:times] += 1
            line_offset -= 1
          end
          line_offset += 1
        end
      end
      puts changes.inspect

      if diff.new_file
        { :type => 'new', :message => "Created file <a href='/show/#{commit.sha}/#{h diff.b_path}'>#{h diff.b_path}</a>", :content => changes }
      elsif diff.deleted_file
        { :type => 'delete', :message => "Deleted file #{diff.a_path}", :content => changes }
      else
        { :type => 'change', :message => "Changed file <a href='/show/#{commit.sha}/#{h diff.a_path}'>#{diff.a_path}</a>", :content => changes }
      end
    end
  end

  def j(str)
    str.to_s.gsub('\\', '\\\\\\\\').gsub(/[&"><]/) { |special| { '&' => '\u0026', '>' => '\u003E', '<' => '\u003C', '"' => '\"' }[special] }
  end
end

puts "Started"