# == Synopsis
#
# Query data based on one or more criteria listed below:
#   (1) name of VM
#   (2) name of VRT system
#   (3) cluster.businessunit combination
# The methods return array named @myresult.
#
# == Data
#
# A directory of files generated via `onall -o` is expected to have the VRT
# system name as the file name and the comma-delimited details of the VM as
# the contents of the file.  The fields of the data files are to match the
# definition of the VMRT class (vmname, memsize, os).
#
# Sample data file (obtained as described in VMinfo.sh)
# HOSTINFO, 2007MB, 33G, 11G
# /vrt/vm/chris1.sys.dev99.websys.tmcs/linux.vmx, chris1.sys.dev99.websys.tmcs, 256, redhat, 3, 
# /vrt/vm/taylor1.sys.dev99.websys.tmcs/taylor1.sys.dev99.websys.tmcs.vmx, taylor1.sys.dev99.websys.tmcs, 256, redhat, 3, 
# /vrt/vm/francis2.sys.dev99.websys.tmcs/francis2.sys.dev99.websys.tmcs.vmx, francis2.sys.dev99.websys.tmcs, 384, redhat, 3, 
#
# Future development is to have data collected into DBMS so instead of parsing
# through data files to obtain results, SQL statements will be issued to obtain
# results.
#
# == Author
# Friendly half-blind Systems Administrator with smiles

# $Id: vmrt_query.rb,v 1.22 2008/03/25 21:58:14 francis Exp $


class VMRT
  @myresult = Array.new
  @fname = Array.new
  @clus_bu = Array.new
  mytype = ''
  c_instance = ''

  def initialize(vmcfg, vmname, memsize, os, vhwversion, vcpunum, vrtname)
    @vmcfg = vmcfg
    @vmname = vmname
    @memsize = memsize 
    @os = os
    @vhwversion = vhwversion
    @vcpunum = vcpunum
    @vrtname = vrtname 
  end
  attr_reader :vmcfg, :vmname, :memsize, :os, :vhwversion, :vcpunum, :vrtname

  def self.mypath=(mypath)
    @mypath = File.expand_path(mypath)
  end

  def self.myvmname=(myvmname)
    @myvmname = myvmname
  end

  def self.myvrtname=(myvrtname)
    @myvrtname = myvrtname
  end

  def self.mytwiki=(mytwiki)
    @mytwiki = mytwiki
  end

  def self.mydebug=(mydebug=false)
    @mydebug = mydebug
  end

  def self.verify_path
    @curr_dir = Dir.getwd
    @myresult.clear
    # verify existence of path
    if File.exist?(@mypath) then
      mytype = File.ftype(@mypath) 
      case mytype
      # only do work if the entered path ends as a directory
      when 'directory'
        # change to directory if path is directory
        Dir.chdir(@mypath)
        puts Dir.getwd if (@mydebug == true) 
      else    
        @myresult.push "Sorry, #{@mypath} is not a directory but a #{mytype} \"file.\""
        Dir.chdir(@curr_dir)
      end     
    else    
      @myresult.push "Sorry, #{@mypath} does not exist."
      Dir.chdir(@curr_dir)
    end
  end
  
  def self.parse_file
    @pfvmcfg      = (! @aLn[0].nil?) && @aLn[0].strip || '-'
    @pfvmname     = (! @aLn[1].nil?) && @aLn[1].strip || '-'
    @pfmemsize    = (! @aLn[2].nil?) && @aLn[2].strip || '-'
    @pfos         = (! @aLn[3].nil?) && @aLn[3].strip || '-'
    @pfvhwversion = (! @aLn[4].nil?) && @aLn[4].strip || '-'
    @pfvcpunum    = (! @aLn[5].nil?) && @aLn[5].strip || '1'
  end

  def self.populate_instance
    @aVM = VMRT.new(@pfvmcfg, @pfvmname, @pfmemsize, @pfos, @pfvhwversion, @pfvcpunum, @fn)
    puts "#{@aVM.inspect}" if (@mydebug == true) 
  end

  def self.find_vm
    # verify path
    verify_path
    # come up with list of files without "." and ".."
    return @myresult if (not @myresult.empty?)
    @fname.clear
    @fname = Dir.entries(".")
    @fname.delete_if {|x| x =~ /^\./}
    # parse all data files to look for matching VM
    @fname.each {|@fn|
    # only process if the item is a file
      if File.file?(@fn) then
        puts "#{@fn}" if (@mydebug == true) 
        aFile = File.open(@fn, 'r')
        aFile.each_line {|ln|
          if not ln =~ /HOSTINFO/
            @aLn = ln.strip.split(',')
            parse_file
            populate_instance
            if (@aVM.vmname =~ /#{@myvmname}/) then
              @myresult.push "#{@aVM.vmcfg}:#{@aVM.vmname}:#{@aVM.memsize}:#{@aVM.os}:" +
                             "#{@aVM.vhwversion}:#{@aVM.vcpunum}:#{@aVM.vrtname}"
            end
          end
        }
      aFile.close
      end     
    }
    Dir.chdir(@curr_dir)
    return @myresult
  end
  
  def self.find_vrt
    verify_path
    return @myresult if (not @myresult.empty?)
    if File.exist?(@myvrtname) then
      puts "#{@myvrtname}" if (@mydebug == true)
      @fn = @myvrtname
      aFile = File.open(@fn, 'r')
      aFile.each_line {|ln|
        @aLn = ln.strip.split(',')
        if ln =~ /^HOSTINFO/
          @myresult.push "#{@aLn[1]}:#{@aLn[2]}:#{@aLn[3]}"  # HOSTINFO, $RAM, $HDD, $HDD_AVAIL
          next
        end
        parse_file
        populate_instance
        @myresult.push "#{@aVM.vmcfg}:#{@aVM.vmname}:#{@aVM.memsize}:#{@aVM.os}:" +
                       "#{@aVM.vhwversion}:#{@aVM.vcpunum}"
      }       
      aFile.close
    end
    Dir.chdir(@curr_dir)
    return @myresult
  end

  def self.find_twiki
    verify_path
    return @myresult if (not @myresult.empty?)
    @myresult.clear
    @clus_bu.clear
    @fname.clear
    @fname = Dir.entries(".")
    @fname.delete_if {|x| x =~ /^\./}
    puts "\nValue of mytwiki:  #{@mytwiki.inspect}\n" if (@mydebug == true)
    # parse all data files to look for matching cluster.bizunit
    @fname.each {|@fn|
      puts "#{@fn}" if (@mydebug == true) 
      # build array of all cluster.bizunit combinations
      @clus_bu.push(@fn.split('.')[2,2].join('.'))
      # only process if the cluster section matches and the item is a file
      if ((@fn =~ /#{@mytwiki}/) and (File.file?(@fn))) then
        # pad c_instance with leading zeros to make it 3 positions for sorting purpose
        c_instance = format("%03d", @fn.split('.')[0].split('vrt')[1])
        # handle zero-size files
        if (File.size(@fn) < 30 ) then
          @myresult.push("#{c_instance}:#{@fn}:Cannot find registered VM")
        else
          aFile = File.open(@fn, 'r')
          aFile.each_line {|ln|
            @aLn = ln.strip.split(',')
            if not ln =~ /HOSTINFO/
              parse_file
              populate_instance
              @myresult.push("#{c_instance}:#{@aVM.vrtname}:#{@aVM.vmname}")
            end
          }
          aFile.close
        end
      end     
    }
    # eliminates duplicate entries of cluster.bizunit list
    @clus_bu.uniq!
    Dir.chdir(@curr_dir)
    if (@myresult.empty?) then
      @clus_bu.unshift('NotFound')
      @myresult = @clus_bu.clone
    end
    puts "\nResult by find_twiki:\n#{@myresult.inspect}" if (@mydebug == true)
    return @myresult.sort
  end

end

