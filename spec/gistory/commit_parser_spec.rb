require 'spec/spec_helper'

describe Gistory::CommitParser do
  describe '.parse' do
    before :each do
      @git  = stub('git',  :log => File.read('spec/log_example.log'))
      @repo = stub('repo', :git => @git)
    end
    
    it "should return an array of hashes with keys diff and commit" do
      results = Gistory::CommitParser.parse(@repo, 'file.rb', 'master')
      results.length.should == 7
      results.each do |result|
        result.should be_an_instance_of(Hash)
      end
      results.first[:diff].should be_an_instance_of(Grit::Diff)
      results.first[:commit].should be_an_instance_of(Grit::Commit)
    end
  end
  
  describe '.split_commit' do
    before :each do
      @commits = Gistory::CommitParser.split_commits(
        File.read('spec/log_example.log')
      )
    end
    
    it "should split log output by commits" do
      @commits.length.should == 7
    end
    
    it "should include the commit marker for each item" do
      @commits.each do |commit|
        commit.should match(/^commit /)
      end
    end
  end
  
  describe '.info_and_diff' do
    before :each do
      commit = File.read('spec/commit_example.log')
      @info, @diff = Gistory::CommitParser.info_and_diff commit
    end
    
    it "should return the commit information as the first result" do
      @info.should match(/^commit /)
    end
    
    it "should return the diff as the second result" do
      @diff.should match(/^diff /)
    end
  end
end
