class Gistory::DiffToHtml
  #TODO: Call this from commit view
  def self.diff_to_html(commit, diff)
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
end