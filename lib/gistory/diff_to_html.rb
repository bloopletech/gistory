class Gistory::DiffToHtml
  #FIXME LOLWUT
  def self.h(str)
    Rack::Utils.escape_html str
  end

  #TODO All the below needs to be tested
  def self.diff_to_html_rename(diff)
    { :type => 'rename', :message => diff.diff.ucfirst.gsub("\n", " => "), :content => [] }
  end

  def self.diff_to_html_binary(diff)
    if diff.new_file
      { :type => 'new', :message => "Created binary file #{h diff.b_path}", :content => [] }
    elsif diff.deleted_file
      { :type => 'delete', :message => "Deleted binary file #{h diff.a_path}", :content => [] }
    else
      { :type => 'change', :message => "Changed binary file #{h diff.a_path}", :content => [] }
    end
  end


  #TODO: REFACTOR THIS SHIT SOMETHING FURIOUS
  def self.lines_to_raw_changes(lines)
    changes = []

    line_offset = 1
    should_change = false
    lines.each do |l|
#      puts "line_offset: #{line_offset}, l: #{l}, changes: #{changes.inspect}"
      if l =~ /^\@\@ \-\d+(?:|,\d+) \+(\d+)(?:|,\d+) \@\@/
        line_offset = $1.to_i == 0 ? 1 : $1.to_i
      else
        if l == '\ No newline at end of file'
          changes.last[:nl_notice] = true if !changes.empty?
          line_offset -= 1
        elsif l =~ /^\+/
          changes << { :start => line_offset, :lines => [], :times => 0, :mode => :add, :nl_notice => false } if should_change or changes.empty? or changes.last[:mode] != :add
          should_change = false
          changes.last[:times] += 1
          changes.last[:lines] << l[1..-1]
        elsif l =~ /^-/
          changes << { :start => line_offset, :lines => [], :times => 0, :mode => :remove, :nl_notice => false } if should_change or changes.empty? or changes.last[:mode] != :remove
          should_change = false
          changes.last[:times] += 1
          changes.last[:lines] << l[1..-1]
          line_offset -= 1
        else
          should_change = true
        end
        line_offset += 1
      end
    end

    changes
  end

  def self.process_newline_warnings_on_changes(changes)
    return changes if changes.length <= 1 || !changes.detect { |change| change[:nl_notice] } #Remove edge cases

    if (changes[-2][:nl_notice] || changes[-1][:nl_notice]) && changes[-2][:lines].first == changes[-1][:lines].first && changes[-2][:lines].length == 1 && changes[-1][:lines].length == 1
      #Handles adding/removing a newline to the end of a file, i.e. a one line remove and a one line add
      changes.pop
      changes.pop
    elsif changes[-2][:mode] == :remove && changes[-1][:mode] == :add
      if changes[-1][:nl_notice] && changes[-2][:times] > 1 && changes[-1][:lines].length == 1 && changes[-2][:lines].first == changes[-1][:lines].first
        #Handles removing where there's no end nl both before and after
        changes[-2][:start] += 1
        changes.pop
      elsif changes[-2][:nl_notice] && changes[-2][:lines].length == 1 && changes[-1][:times] > 1 && changes[-2][:lines].first == changes[-1][:lines].first
        #Handles adding where there's no end nl both before and after
        changes.delete_at(-2)
        changes[-1][:lines].shift
        changes[-1][:start] += 1
      end
    end

    changes
  end
  


  def self.changes_to_html(changes)
    changes.select { |change| change.key?(:lines) }.each do |change|
      change[:lines] = change[:lines].map do |line|
        line_space_fixed = h(line).gsub(/  /, " &nbsp;")
        "<div>#{line_space_fixed == '' ? "&nbsp;" : line_space_fixed}</div>"
      end.join
    end

    changes
  end


  def self.diff_to_html_textual(diff)
#    puts "COMMIT ========================================================================================="
    content_lines = diff.diff.split(/\n/)[2..-1]
    
    changes = self.lines_to_raw_changes(content_lines)
    changes = self.process_newline_warnings_on_changes(changes)
    changes = self.changes_to_html(changes)
   
    if diff.new_file
      { :type => 'new', :message => "Created file #{h diff.b_path}", :content => changes }
    elsif diff.deleted_file
      { :type => 'delete', :message => "Deleted file #{diff.a_path}", :content => changes }
    else
      { :type => 'change', :message => "Changed file #{diff.a_path}", :content => changes }
    end
  end
    
  def self.diff_to_html(diff)
    if diff.diff =~ /^rename/
      diff_to_html_rename diff
    elsif diff.diff =~ /^Binary/
      diff_to_html_binary diff
    else
      diff_to_html_textual diff
    end
  end
end
