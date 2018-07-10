#
# == Synopsis
#
# This script is to reset VM based on @vmname, @vrtname, @vmcfg, and
# @vmaction.
#
# == Assumption
# SSH agent is running and holding necessary private key to enable access to
# systems as root without password.
#
# == Author
# Friendly half-blind Systems Administrator with smiles
#

# $Id: vm_reset.rb,v 1.7 2007/06/30 00:40:45 francis Exp $


class VMreset
#  ENV["PATH"] = '/bin:/usr/bin'

  @tools = [ 'bash', 'ping', 'ssh', 'ssh-add' ]
  @searchpath = Array.new
  PINGCMD = 'ping -q -c 1 '
  SSHCMD = 'ssh -2 -a -x -l root -o StrictHostKeyChecking=no '
  SSHADDCMD = 'ssh-add -l 1>/dev/null 2>&1'
  VMCMD = '/usr/bin/vmware-cmd '
  @mycmd = ''
  @remotec_action = ''
  @myresult = ''

  def self.vmname=(vmname)
    @vmname = vmname
  end

  def self.vrtname=(vrtname)
    @vrtname = vrtname
  end

  def self.vmcfg=(vmcfg)
    @vmcfg = vmcfg
  end

  def self.vmaction=(vmaction)
    @vmaction = vmaction
  end

  def self.debug=(debug=false)
    @debug = debug
  end

  def self.check_tools
    found = false
    notools = Array.new
    notools.clear
    @searchpath = ENV["PATH"].split(':')
    @tools.each {|t|
      @searchpath.each {|d|
        puts "Looking for #{t} in #{d}..." if (@debug == true)
        if (File.executable?("#{d}/#{t}")) then
          found = true
          puts "\tFound #{t} in #{d}..." if (@debug == true)
          break
        else
          found = false
        end
      }
      notools.push(t) if (found == false)
    }
    if (notools.empty?) then
      return true
    else
      msg = "The following item(s) is/are either not found or not executable "
      msg = msg + "in your PATH:\n"
      puts msg
      notools.each {|x|
        puts "\t#{x}"
      }
      return false
    end
  end

  def self.check_ssh_key
    @myresult = system(SSHADDCMD)
    puts 'No SSH key loaded...' if (@myresult == false)
    return @myresult
  end

  def self.verify_vrt
    # verify vrt is at least responding to icmp ping packet
    @mycmd = PINGCMD + @vrtname + ' 1>/dev/null 2>&1'
    @myresult = system(@mycmd)
    return @myresult if (@myresult == false)
    @mycmd = SSHCMD + @vrtname + ' uptime' + ' 1>/dev/null'
    return system(@mycmd)
  end

  def self.process_vm
    @myresult = check_tools
    return [ @myresult, 'At least one of the required tools is not available.' ] if (@myresult == false)
    @myresult = check_ssh_key
    return [ @myresult, 'No SSH key has been loaded.' ] if (@myresult == false)
    @myresult = verify_vrt
    return [ @myresult, 'VRT is not accessible.' ] if (@myresult == false)
    puts "Attempting to \"#{@vmaction}\" #{@vmname.upcase} on #{@vrtname.upcase}..."
    @remote_action = VMCMD + '"' + @vmcfg + '" ' + @vmaction
    @mycmd = SSHCMD + @vrtname + " '" + @remote_action + "' 1>/dev/null"
    puts "Command to be executed is: #{@mycmd}" if (@debug == true)
    @myresult = system(@mycmd)
    if (@myresult == false) then
       msg = "Execution of #{@vmaction.upcase} for #{@vmname.upcase} on #{@vrtname.upcase} was unsuccessful."
    end
    return [ @myresult, msg ]
  end

end
