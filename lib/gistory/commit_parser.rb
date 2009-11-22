class Gistory::CommitParser
  def self.parse(repo, file, branch = 'master')
    log_data = repo.git.log(
      { :pretty => 'raw'},
      '--follow',   '--topo-order',
      '-p', branch, "--", file
    )

    split_commits(log_data).map { |commit|
      info, diff = info_and_diff commit

      {
        :commit => Grit::Commit.list_from_string(repo, info).first,
        :diff   => Grit::Diff.list_from_string(repo, diff).first
      }
    }.reverse
  end
  
  def self.split_commits(log)
    commits = log.split(/\ncommit /)
    commits.collect { |commit|
      commit[/^commit /] ? commit : "commit #{commit}"
    }
  end
  
  def self.info_and_diff(commit)
    commit.match(/(^commit .+)(\ndiff .+)/m)[1..2]
  end
end
