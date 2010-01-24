class Gistory::CommitParser
  def self.parse(repo, file, branch = 'master')
    log_data = repo.git.log({ :pretty => 'raw' }, '--follow', '--topo-order', '-p', '-U1', branch, "--", file)

    split_commits(log_data).map do |commit|
      info, diff = info_and_diff commit
      { :commit => Grit::Commit.list_from_string(repo, info).first, :diff => Grit::Diff.list_from_string(repo, diff).first }
    end.reverse
  end

  def self.split_commits(log)
    log.split(/\ncommit /).map { |commit| commit[/^commit /] ? commit : "commit #{commit}" }
  end
  
  def self.info_and_diff(commit)
    commit.match(/(^commit .+)(?:\n)(diff .+)/m)[1..2]
  end

  def self.index_and_generate!(commits)
    change_index = 0
    commits.each_with_index do |cd, i|
      cd[:index] = i
      cd[:diff_html] = Gistory::DiffToHtml.diff_to_html(cd[:diff])

      cd[:diff_html][:content].each_with_index do |change, i|
        change[:global_index] = change_index
        change[:index] = i
        change_index += 1
      end

      cd[:commit_metadata] = metadata_for_commit(cd)
    end

    commits
  end

  def self.metadata_for_commit(commit_diff)
    commit = commit_diff[:commit]
    { 'message' => h(commit.message), 'index' => commit_diff[:index],
     'author_details' => h(commit.committer.name_email << (commit.committer != commit.author ? " for #{commit.author.name_email}": "")),
      'date_time' => commit.date.strftime("%A %d/%m/%Y %I:%M %p"), 'diff_message' => h(commit_diff[:diff_html][:message]) }
  end
end
