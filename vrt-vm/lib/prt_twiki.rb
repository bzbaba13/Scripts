#
# == Synopsis
#
# This class file print text output for copying/pasting to twiki page based
# on data provided in a sorted array format:
#   [ "vrtname:vmanme", "vrtname:vmname", ... ]
#
# Source as hash array is not currently supported but will be added if there
# should be a need for it:
#   { "vrtname" => [ "vmname", "vmname", "vmanme", ... ] }
#
# == Author
# Friendly half-blind Systems Administrator with smiles

# $Id: prt_twiki.rb,v 1.14 2008/12/10 02:02:44 francis Exp $


require 'date'

class PrtTwiki
  @col1 = Array.new
  @col2 = Array.new
  @col3 = Array.new
  @col4 = Array.new
  @col5 = Array.new
  @vrtinfo = Array.new
  aLn = Array.new

  def self.vrtinfo=(vrtinfo)
    @vrtinfo = vrtinfo
  end

  def self.mycluster=(mycluster)
    @mycluster = mycluster
  end

  def self.mybizunit=(mybizunit)
    @mybizunit = mybizunit
  end

  def self.mydebug=(mydebug=false)
    @mydebug = mydebug
  end

  def self.prt_header
    now = DateTime.now
    puts
    puts "Business Unit: #{@mybizunit.upcase}\tCluster: #{@mycluster.upcase}  " +
         "(Generated on #{now.month}/#{now.day}/#{now.year})"
    puts
  end

  def self.prt_heading
    @col1[0] = '*' + @col1[0].upcase + '*' if (not @col1[0].nil?)
    @col2[0] = '*' + @col2[0].upcase + '*' if (not @col2[0].nil?)
    @col3[0] = '*' + @col3[0].upcase + '*' if (not @col3[0].nil?)
    @col4[0] = '*' + @col4[0].upcase + '*' if (not @col4[0].nil?)
    @col5[0] = '*' + @col5[0].upcase + '*' if (not @col5[0].nil?)
    printf("| %-23s | %-23s | %-23s | %-23s | %-23s |\n",
      @col1[0], @col2[0], @col3[0], @col4[0], @col5[0])
  end

  def self.prt_body
    # loop through and print all rows of all 5 columns
    a = [ @col1.length, @col2.length, @col3.length, @col4.length, @col5.length ]
    puts "The largest number of row for this section is: #{a.max}" if (@mydebug == true)
    for @i in 1..(a.max - 1)
      printf("| %-23s | %-23s | %-23s | %-23s | %-23s |\n",
        @col1[@i], @col2[@i], @col3[@i], @col4[@i], @col5[@i])
    end
    puts
    # reset counter and stuff
    @elm = 0
    @c = 1
    @col1.clear
    @col2.clear
    @col3.clear
    @col4.clear
    @col5.clear
  end

  def self.prop_cols
    aLn = @ln.split(':')
    # set header (vrtname) if vrtname is different than saved one
    if (not @tmpvrt == aLn[0]) then
      @tmpvrt = aLn[0]
      @c += 1
      if (@c == 6) then
        prt_heading
        prt_body
      end
      case @c
      when 1
        @col1[0] = @tmpvrt
        puts "#{@c}\t#{@col1[0]}" if (@mydebug == true)
      when 2
        @col2[0] = @tmpvrt
        puts "#{@c}\t#{@col2[0]}" if (@mydebug == true)
      when 3
        @col3[0] = @tmpvrt
        puts "#{@c}\t#{@col3[0]}" if (@mydebug == true)
      when 4
        @col4[0] = @tmpvrt
        puts "#{@c}\t#{@col4[0]}" if (@mydebug == true)
      when 5
        @col5[0] = @tmpvrt
        puts "#{@c}\t#{@col5[0]}" if (@mydebug == true)
      end
      @elm = 1
    end
    # propagate the remaining rows
    case @c
    when 1
      @col1[@elm] = aLn[1]
      puts "#{@c}\t#{@col1[@elm]}" if (@mydebug == true)
    when 2
      @col2[@elm] = aLn[1]
      puts "#{@c}\t#{@col2[@elm]}" if (@mydebug == true)
    when 3
      @col3[@elm] = aLn[1]
      puts "#{@c}\t#{@col3[@elm]}" if (@mydebug == true)
    when 4
      @col4[@elm] = aLn[1]
      puts "#{@c}\t#{@col4[@elm]}" if (@mydebug == true)
    when 5
      @col5[@elm] = aLn[1]
      puts "#{@c}\t#{@col5[@elm]}" if (@mydebug == true)
    end
    @elm += 1
  end

  def self.proc_data
    @tmpvrt = ''
    @c = 0
    @elm = 0
    @col1.clear
    @col2.clear
    @col3.clear
    @col4.clear
    @col5.clear
    prt_header
    @vrtinfo.each {|@ln|
      prop_cols
    }
    # print section processed but with less than 5 columns
    if (@c != 0) then
      prt_heading
      prt_body
    end
  end

end
