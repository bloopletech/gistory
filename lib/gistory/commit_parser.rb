class Gistory::CommitParser
  def self.parse(repo, file, branch = 'master')
    log_data = repo.git.log({ :pretty => 'raw' }, '--follow', '--topo-order', '-p', branch, "--", file)

    split_commits(log_data).map do |commit|
      info, diff = info_and_diff commit
      { :commit => Grit::Commit.list_from_string(repo, info).first, :diff   => Grit::Diff.list_from_string(repo, diff).first }
    end.reverse
  end
  
  def self.split_commits(log)
#    log.split(/\ncommit /).join("\ncommit ")
#    puts log.scan(/\n(commit .*?)(?:\ncommit |\z)/m).inspect
#puts log.split(/^commit /).map { |commit| "commit #{commit}" }.inspect
#    log.split(/\ncommit /).map { |commit| "\ncommit #{commit}" }
    log.split(/\ncommit /).map { |commit| commit[/^commit /] ? commit : "commit #{commit}" }
  end
  
  def self.info_and_diff(commit)
    commit.match(/(^commit .+)(?:\n)(diff .+)/m)[1..2]
  end
end
