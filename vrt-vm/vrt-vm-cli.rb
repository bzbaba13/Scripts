#!/software/ruby/1.8.7/bin/ruby -w

# == Synopsis
#
# This is the CLI to the vmrt application for working with information in
# information in regards to VRT/VM systems.
#
# == Classes
# * vmrt_query.rb handles queries and returns results in an array format.
# * prt_twiki.rb handles printing of twiki-friendly text.
#
# == Author
# Friendly half-blind Systems Administrator with smiles

# $Id: vrt-vm-cli.rb,v 1.46 2010/01/28 22:13:35 francis Exp $


$:.unshift('/opt/local/lib/vrt-vm/')

require 'getoptlong'
require 'vmrt_query'
require 'prt_twiki'
require 'vm_reset'
require 'yaml'

CONF_FILE='/opt/local/etc/vrt-vm/vrt-vm.conf'
msg = ''
@mypath = ''
fname = Array.new
myconfig = Hash.new
mydebug = false
myresetvm = false
myvmname = ''
myvrtlist = Array.new
myvrtname = ''
mytwiki = ''
mycluster = ''
mybizunit = ''
mycounter = 0
myresult = Array.new
mytwiki_result = Array.new

def showusage
  puts "Usage: #{$0} <options>"
  puts
  puts "\t--guest|-g:\t<Name of VM, e.g., app1.shared, dev99, \"atl.*(dev15|qa7)\", etc>"
  puts
  puts "\t--vrt|-v:\t<Name of VRT, e.g., vrt83.sys.adm2.websys.tmcs[,vrt88.sys.adm2.websys.tmcs,...]>"
  puts
  puts "\t--twiki|-t:\t<Print text output for twiki, e.g., bej1.websys>"
  puts
  puts "\t--reset|-r:\t<Reset one VM.>"
  puts
  puts "\t--path|-p:\t<Path (absolute/ralative) to the data directory>"
  puts "\t\t\t(default to \'#{@mypath}\' based on configuration file)."
  puts
  puts "\t--help|-h:\tThis message."
  puts
  puts "\t--debug|-d:\t<Turn on debug to display extra information (only if you absolutely have to).>"
  puts
  exit
end

myconfig = YAML.load_file(CONF_FILE)
@mypath = myconfig['data_dir']

opts = GetoptLong.new(
  [ "--guest", "-g", GetoptLong::REQUIRED_ARGUMENT ],
  [ "--vrt", "-v", GetoptLong::REQUIRED_ARGUMENT ],
  [ "--twiki", "-t", GetoptLong::REQUIRED_ARGUMENT ],
  [ "--reset", "-r", GetoptLong::NO_ARGUMENT ],
  [ "--path", "-p", GetoptLong::REQUIRED_ARGUMENT ],
  [ "--debug", "-d", GetoptLong::NO_ARGUMENT ],
  [ "--help", "-h", GetoptLong::NO_ARGUMENT ]
)

opts.each do |opt, arg|
#  puts "Option: #{opt} with argument of #{arg.inspect}\n"
  case opt
  when /-g/
    myvmname = arg
  when /-v/
    myvrtlist = arg
  when /-t/
    mytwiki = arg.downcase
  when /-r/
    myresetvm = true
  when /-p/
    @mypath = arg
  when /-d/
    mydebug = true
  else
    showusage
  end
end

# show usage and quit if path is not entered
showusage if (@mypath.length == 0)

def display_vm_result(myresult, mydebug)
  # myresult = [ "@vmcfg:@vmname:@memsize:@os:@vhwversion:@vcpunum:@vrtname" , "... ]
  puts myresult.inspect if (mydebug == true)
  printf("\n%-33s %-5s %-13s %-28s\n", "VM Name", "RAM", "OS", "VRT Name")
  78.times { print "~" } ; puts
  mycounter = 0
  myresult.each {|ln|
    aLn = ln.split(':')
    printf("%-33s %-5s %-13s %-28s\n", aLn[1], aLn[2], aLn[3], aLn[6])
    mycounter += 1
  }
  puts
  puts "Total number of VM systems is:  #{mycounter.to_s}."
  puts
end

def display_vrt_result(myvrtname, myresult, mydebug)
  myhostinfo = myresult.shift.split(':')
  puts myresult.inspect if (mydebug == true)
  print "\n#{myvrtname.upcase.strip}  (RAM: #{myhostinfo[0].strip}  "
  print "HDD: #{myhostinfo[2].strip}/#{myhostinfo[1].strip})\n"
  28.times { print '~' } ; puts
  printf("%-33s %-5s %-13s %-10s %-8s\n", "VM Name", "RAM", "OS", "Vir HW Ver", "Vir CPU#")
  78.times { print "~" } ; puts
  mycounter = 0
  myresult.each {|ln|
    aLn = ln.split(':')
    printf("%-33s %-5s %-13s %-10s %-8s\n", aLn[1], aLn[2], aLn[3], aLn[4].center(10), aLn[5].center(8))
    mycounter += 1
  }
  puts
  puts "Total number of VM systems on this VRT is:  #{mycounter.to_s}."
  puts
end

def process_twiki_data(mytwiki_data, mybizunit, mycluster, mydebug)
  # eliminate 0-padded instance and build array for prt_twiki to process
  tmparr = Array.new
  newarr = Array.new
  mytwiki_data.each {|x|
    myvrtname = nil
    myvmname = nil
    tmparr = x.split(':')
    myvrtname = tmparr[1].sub(/.#{mybizunit}.*/, '')
    myvmname = tmparr[2].sub(/\.tmc.*$/, '')
    puts "VRT: #{myvrtname}\tVM: #{myvmname}" if (mydebug == true)
    newarr.push("#{myvrtname}:#{myvmname}")
  }
  PrtTwiki.mydebug = mydebug
  PrtTwiki.mycluster = mycluster
  PrtTwiki.mybizunit = mybizunit
  PrtTwiki.vrtinfo = newarr
  PrtTwiki.proc_data
end


# verify existence of path
if File.exist?(@mypath) then
  mytype = File.ftype(@mypath) 
  case mytype
  # only do work if the entered path ends as a directory
  when 'directory'
    # convert to absolute path and change to directory
    @mypath = File.expand_path(@mypath)
    Dir.chdir(@mypath)
    puts Dir.getwd if (mydebug == true) 
  else    
    puts "\nSorry, \"#{@mypath}\" is not a directory but a #{mytype}."
    puts
    exit
  end     
else    
  puts "\nSorry, path \"#{@mypath}\" does not exist.\n"
  puts
  exit
end

VMRT.mypath = @mypath
VMRT.mydebug = mydebug

# Hosting system (VRT) section
if (not myvrtlist.empty?) then
  myvrtname = myvrtlist.split(',')
  myvrtname.each {|vrt|
    VMRT.myvrtname = vrt.downcase.strip
    myresult.clear
    myresult = VMRT.find_vrt
    puts myresult.inspect if (mydebug == true)
    if (myresult.length <= 1) then
      puts "\nSorry, no registered VM can be found hosted on #{vrt.upcase}."
      puts
    else
      display_vrt_result(vrt, myresult, mydebug)
    end
  }
end

# Guest system (VM) section
if (not myvmname.empty?) then
  puts "Processing VM query..." if (mydebug == true)
  VMRT.myvmname = myvmname
  myresult.clear
  myresult = VMRT.find_vm
  puts myresult.inspect if (mydebug == true)
  if (myresult.empty?) then
    puts "\nSorry, no VM that matches #{myvmname.upcase} can be found."
    puts
  else
    display_vm_result(myresult, mydebug)
  end

  if (myresetvm == true) then
    puts "Processing reset VM..." if (mydebug == true)
    puts "Number of matches:  #{myresult.length}" if (mydebug == true)
    if (myresult.length > 1) then
      msg = "Sorry, your search criteria returns more than one VM."
      msg = msg + "\nPlease use the result displayed above to help narrow down your"
      msg = msg + "\nsearch criteria, i.e., copy and paste the VM name your want to"
      msg = msg + "\nreset as the argument of the -g option.  Sorry for the"
      msg = msg + "\ninconvenience."
      puts msg
      puts
    else
      aLn = myresult[0].split(':')
      print "WARNING!  Not shutting down the OS gracefully from the OS may cause data loss.\n"
      print "          Are you sure about resetting #{aLn[1].upcase}\n"
      print "          hosted by #{aLn[6].upcase} [yes/no]? "
      ans = gets.chomp
      puts "Answer is: #{ans.dump}" if (mydebug == true)
      if (ans.downcase == 'yes') then
        puts "Working on resetting #{aLn[1]}..."
        VMreset.debug = mydebug
        VMreset.vmcfg = aLn[0]
        VMreset.vmname = aLn[1]
        VMreset.vrtname = aLn[6]
        VMreset.vmaction = 'stop hard'
        myresult.clear
        myresult = VMreset.process_vm
        if (myresult[0] == true ) then
          puts "\t#{aLn[1].upcase} successfully stopped."
          puts
          sleep 3
          VMreset.vmaction = 'start'
          myresult.clear
          myresult = VMreset.process_vm
          myresult.inspect if (mydebug == true)
          if (myresult[0] == true) then
            puts "\t#{aLn[1].upcase} successfully started."
            puts "\tPlease try accessing the system in a minute."
          else
            puts "\t#{aLn[1].upcase} failed to start."
            puts "\tPlease consult with Systems Administration."
          end
          puts
        else
          puts "#{myresult[1].capitalize}"
          puts
        end
      end
    end
  end
end

# twiki-friendly output section
if (not mytwiki.empty?) then
  puts "Processing twiki stuff..." if (mydebug == true)
  mycluster = mytwiki.split('.')[0]
  mybizunit = mytwiki.split('.')[1]
  puts "Value of mycluster is: #{mycluster}" if (mydebug == true)
  puts "Value of mybizunit is: #{mybizunit}" if (mydebug == true)
  mybizunit = '-' if (mybizunit.nil?)
  puts "Cluster.Businessunit combination is: #{mytwiki}" if (mydebug == true)
  VMRT.mytwiki = mycluster + '.' + mybizunit
  myresult.clear
  myresult = VMRT.find_twiki
  puts "\nData from find_twiki:\n#{myresult.inspect}\n" if (mydebug == true)
  if (myresult[0] == 'NotFound') then
    myresult.shift  # eliminate the 'NotFound' record
    if (mycluster == 'all') then
      puts "\nPrinting ALL host/guest systems information in all available clusters."
      puts
      myresult.each {|csbu|
        puts "\nProcessing #{csbu}..." if (mydebug == true)
        mycluster = csbu.split('.')[0]
        mybizunit = csbu.split('.')[1]
        puts "Value of mycluster is: #{mycluster}" if (mydebug == true)
        puts "Value of mybizunit is: #{mybizunit}" if (mydebug == true)
        VMRT.mytwiki = csbu
        mytwiki_result.clear
        mytwiki_result = VMRT.find_twiki
        # mytwiki_result is always found as VMRT.mytwiki comes from existing file names
        puts "\nData returned from find_twiki is:\n#{mytwiki_result.inspect}\n" if (mydebug == true)
        puts "\n---+++ #{mycluster}-#{mybizunit}"
        process_twiki_data(mytwiki_result, mybizunit, mycluster, mydebug)
      }
    else
      puts "\nNo matching cluster & businessunit combination (#{mytwiki.upcase}) can be found."
      puts "Available \"cluster.businessunit\" combinations are:"
      myresult.each {|csbu|
        puts "\t\t#{csbu}"
      }
      puts
    end
  else
    process_twiki_data(myresult, mybizunit, mycluster, mydebug)
  end
end

