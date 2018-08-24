#!/usr/bin/env ruby -w

# == Synopsis
#
# This script reads the json output file from Solidfire storage systems fetched
# via API and prints out reports in text format.
#
#
# == Author
# Friendly half-blind Lead Storage/Systems Administrator with smiles.
#


require 'getoptlong'
require 'time'
require 'json'

@src_path = File.expand_path("~/sf-tmp")
@dest_path = '/var/www/html/sf_reports'
@verbose = false
@mymsg = Array.new
@myreport = Array.new
@pri_data = Array.new
@pri_data_h = Hash.new
@sec_data = Array.new
@ter_data = Array.new
@site_data = { "wc1" => "Irvine, CA", "ev1" => "Ashburn, VA" }


def show_usage
   puts "Usage: #{$0} [--src|-s {arg}] [--dest|-d {arg}] [-v]"
   puts "\t--src|-s:\tPath to json output file from Solidfire (default: ~/sf-tmp)."
   puts "\t--dest|-d:\tPath for text report files (default: /var/www/html/sf_reports)."
   puts "\t--help|-h:\tThis message"
   puts "\t--verbose|-v:\tVerbose output for debug purposes."
   puts
   exit
end

opts = GetoptLong.new(
   [ "--src", "-s", GetoptLong::REQUIRED_ARGUMENT ],
   [ "--dest", "-d", GetoptLong::REQUIRED_ARGUMENT ],
   [ "--help", "-h", GetoptLong::NO_ARGUMENT ],
   [ "--verbose", "-v", GetoptLong::NO_ARGUMENT ]
)

opts.each {|opt, arg|
   case opt
      when /-s/
         @src_path = File.expand_path(arg)
      when /-d/
         @dest_path = File.expand_path(arg)
      when /-h/
         show_usage
      when /-v/
         @verbose = true
      else
         show_usage
   end
}

def bailout
   @mymsg.each{ |line|
      puts "#{line}"
   }
   puts
   exit 1
end

def read_pri_data_h(pri_file)
   @pri_data_h.clear
   @pri_data_h = JSON.load(IO.read(pri_file))
   puts "\n#{pri_file}\n#{@pri_data_h}\n" if @verbose
end

def read_pri_data(pri_file)
   @pri_data.clear
   @pri_data = JSON.load(IO.read(pri_file))
   puts "\n#{pri_file}\n#{@pri_data}\n" if @verbose
end

def read_sec_data(sec_file)
   @sec_data.clear
   @sec_data = JSON.load(IO.read(sec_file))
   puts "\n#{sec_file}\n#{@sec_data}\n" if @verbose
end

def read_ter_data(ter_file)
   @ter_data.clear
   @ter_data = JSON.load(IO.read(ter_file))
   puts "\n#{ter_file}\n#{@ter_data}\n" if @verbose
end

def prt_report(rpt_file,rpt_title,rpt_body)
   File.open(rpt_file, "w", 0644) { |f|
      f.puts "#{rpt_title}"
      f.puts "Generated on #{Time.now}"
      f.puts '~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
      f.puts ''
   }
   File.open(rpt_file, "a") { |f|
      rpt_body.each { |l|
         f.puts "#{l}"
      }
   }
end

def vol_acc_grp(site)
   rpt_body = Array.new
   fn = 'ListVolumeAccessGroup'
   rpt_title = 'Volume Access Group Report - ' + @site_data[site]
   rpt_file = @dest_path + '/'+ fn + '_' + site + '.txt'
   pri_file = @src_path + '/' + fn + '_' + site + '.json'
   if File.exist?(pri_file) then
      read_pri_data(pri_file)
      @pri_data["result"]["volumeAccessGroups"].each { |i|
         rpt_body.push("Name: #{i["name"]}\tID: #{i["volumeAccessGroupID"]}")
         i["initiators"].each { |j|
            rpt_body.push("\tInitiator: #{j}")
         }        
         rpt_body.push("\n")
      }
      puts "\nReport body: #{rpt_body.inspect}" if @verbose
      prt_report(rpt_file,rpt_title,rpt_body)
   else
      @mymsg.push("Critical:  Cannot access #{pri_file}.")
   end
   rpt_body.clear
end

def active_vol(site)
   rpt_body = Array.new
   fn = 'ListActiveVolumes'
   rpt_title = 'Active Volumes Report - ' + @site_data[site]
   rpt_file = @dest_path + '/'+ fn + '_' + site + '.txt'
   pri_file = @src_path + '/' + fn + '_' + site + '.json'
   if File.exist?(pri_file) then
      read_pri_data(pri_file)
      @pri_data["result"]["volumes"].each { |i|
         rpt_body.push("Name: #{i["name"]}   ID: #{i["volumeID"]}   \
Size: #{i["totalSize"]/(1024.0*1024*1024)} GB   QoS: #{i["qos"]["maxIOPS"]}")
         rpt_body.push("\tiSCSI Target ID: #{i["iqn"]}")
         rpt_body.push("\n")
      }
      puts "\nReport body: #{rpt_body.inspect}" if @verbose
      prt_report(rpt_file,rpt_title,rpt_body)
   else
      @mymsg.push("Critical:  Cannot access #{pri_file}.")
   end
   rpt_body.clear
end

def nodes(site)
   rpt_body = Array.new
   fn = 'ListAllNodes'
   nodestats_h = Hash.new
   rpt_title = 'Storage Nodes Report - ' + @site_data[site]
   rpt_file = @dest_path + '/'+ fn + '_' + site + '.txt'
   pri_file = @src_path + '/' + fn + '_' + site + '.json'
   sec_file = @src_path + '/' + 'ListNodeStats' + '_' + site + '.json'
   if File.exist?(pri_file) and File.exist?(sec_file) then
      read_pri_data_h(sec_file)
      puts "\nNode stats data: #{@pri_data_h.inspect}" if @verbose
      @pri_data_h["result"]["nodeStats"]["nodes"].each { |i| nodestats_h[i["nodeID"]] = i }
      puts "\nNode stats hash: #{nodestats_h.inspect}" if @verbose
      read_pri_data(pri_file)
      @pri_data["result"]["nodes"].each { |i|
         rpt_body.push("Name: #{i["name"]}   \
Platform: #{i["platformInfo"]["nodeType"]} / #{i["platformInfo"]["chassisType"]} \
/ #{i["platformInfo"]["nodeMemoryGB"]} GB   OS: #{i["softwareVersion"]}")
         rpt_body.push("\tConnectivity: Cluster: #{i["cip"]} (#{i["cipi"]})   \
Management: #{i["mip"]} (#{i["mipi"]})")
         nodestats_h[i["nodeID"]].each_pair { |j,k| 
            case j
            when /[cs]Bytes/
               rpt_body.push( sprintf( "%38s : %-s (\~%.3f TB)\n", j, k, k/1024.0**4 ) )
            when /mBytes/, /Memory/
               rpt_body.push( sprintf( "%38s : %-s (\~%d GB)\n", j, k, k/1024**3 ) )
            when "cpu", /network/
               rpt_body.push( sprintf( "%38s : %-s \%\n", j, k ) )
            else
               rpt_body.push( sprintf( "%38s : %-s\n", j, k ) )
            end
         }
         rpt_body.push("\n")
      }
      puts "\nReport body: #{rpt_body.inspect}" if @verbose
      prt_report(rpt_file,rpt_title,rpt_body)
   else
      @mymsg.push("Critical:  Cannot access #{pri_file} or #{sec_file}.")
   end
   rpt_body.clear
end

def accounts(site)
   rpt_body = Array.new
   fn = 'ListAccounts'
   rpt_title = 'Accounts Report - ' + @site_data[site]
   rpt_file = @dest_path + '/'+ fn + '_' + site + '.txt'
   pri_file = @src_path + '/' + fn + '_' + site + '.json'
   sec_file = @src_path + '/' + 'ListActiveVolumes' + '_' + site + '.json'
   ter_file = @src_path + '/' + 'ListVolumeAccessGroup' + '_' + site + '.json'
   if File.exist?(pri_file) and File.exist?(sec_file) and File.exist?(ter_file) then
      # build tertiary hash array
      read_ter_data(ter_file)
      vag_info = Hash.new
      @ter_data["result"]["volumeAccessGroups"].each { |g|
         vag_info['[' + g["volumeAccessGroupID"].to_s + ']'] = g["name"] + \
' with ' + g["initiators"].count.to_s + ' initiator(s)'
      }
      puts "\nVAG info: #{vag_info.inspect}" if @verbose
      # build secondary hash array
      read_sec_data(sec_file)
      vol_info = Hash.new
      acct_vag = Hash.new
      @sec_data["result"]["volumes"].each { |v|
         vol_info[v["volumeID"]] = v["name"] + ' (' + v["iqn"] + ')'
         acct_vag[v["accountID"]] = vag_info[v["volumeAccessGroups"].to_s] if ! acct_vag.has_key?(v["accountID"])
      }
      puts "\nVol info: #{vol_info.inspect}" if @verbose
      puts "\nAcct_VAG info: #{acct_vag.inspect}" if @verbose
      # process primary data
      read_pri_data(pri_file)
      @pri_data["result"]["accounts"].each { |a|
         acct_vag[a["accountID"]] = 'No associated Volume Access Group.' if acct_vag[a["accountID"]].nil?
         rpt_body.push("Name: #{a["username"]}   \
ID: #{a["accountID"]}   VAG: #{acct_vag[a["accountID"]]}")
         if a["volumes"].empty? then
            rpt_body.push("\tNo volume/LUN associated with this account.")
         else
            a["volumes"].each { |i|
               rpt_body.push("\t#{vol_info[i]}")
            }
         end
         rpt_body.push("\n")
      }
      puts "\nReport body: #{rpt_body.inspect}" if @verbose
      prt_report(rpt_file,rpt_title,rpt_body)
   else
      @mymsg.push("Critical: Cannot access #{pri_file}, #{sec_file}, and/or #{ter_file}.")
   end
   rpt_body.clear
end

def vol_stats(site)
   rpt_body = Array.new
   fn = 'ListVolumesStatsByVolume'
   rpt_title = 'Volume Statistics Report - ' + @site_data[site]
   rpt_file = @dest_path + '/'+ fn + '_' + site + '.txt'
   pri_file = @src_path + '/' + fn + '_' + site + '.json'
   sec_file = @src_path + '/' + 'ListAccounts' + '_' + site + '.json'
   ter_file = @src_path + '/' + 'ListActiveVolumes' + '_' + site + '.json'
   if File.exist?(pri_file) and File.exist?(sec_file) and File.exist?(ter_file) then
      # build tertiary hash array
      read_ter_data(ter_file)
      vol_info = Hash.new
      @ter_data["result"]["volumes"].each { |v|
         vol_info[v["volumeID"]] = [ v["name"], v["totalSize"], v["qos"]["maxIOPS"], v["volumeID"] ]
      }
      puts "\nVol info: #{vol_info.inspect}" if @verbose
      # build secondary hash array
      read_sec_data(sec_file)
      acct_info = Hash.new
      @sec_data["result"]["accounts"].each { |a|
         acct_info[a["accountID"]] = a["username"]
      }
      puts "Acct info: #{acct_info.inspect}" if @verbose
      # process primary data
      read_pri_data(pri_file)
      acct_info.each_pair { |i,j|
         result_count = 0
         rpt_body.push("Account: #{j}   ID: #{i}")
         @pri_data["result"]["volumeStats"].each { |s|
            if s["accountID"] == i then
            result_count += 1
               rpt_body.push("\tVolume: #{vol_info[s["volumeID"]][0]}   \
ID: #{vol_info[s["volumeID"]][3]}   IOPS (Avg.): #{s["averageIOPSize"]}   \
Size: #{vol_info[s["volumeID"]][1]/(1024.0*1024*1024)} GB   QoS: #{vol_info[s["volumeID"]][2]}")
               rpt_body.push("\t\tRead: #{s["readBytes"]/(1024*1024*1024)} GB   \
Latency: #{s["readLatencyUSec"]} μs   OPS: #{s["readOps"]}   Unaligned: #{s["unalignedReads"]}")
               rpt_body.push("\t\tWrite: #{s["writeBytes"]/(1024*1024*1024)} GB   \
Latency: #{s["writeLatencyUSec"]} μs   OPS: #{s["writeOps"]}   Unaligned: #{s["unalignedWrites"]}")
               rpt_body.push("\n")
            end
         }
         if result_count == 0 then
            rpt_body.push("\tNo associated volume exist.")
            rpt_body.push("\n")
         end
         rpt_body.push("\n")
      }
      puts "\nReport body: #{rpt_body.inspect}" if @verbose
      prt_report(rpt_file,rpt_title,rpt_body)
   else
      @mymsg.push("Critical:  Cannot access #{pri_file}, #{sec_file}, and/or #{ter_file}.")
   end
   rpt_body.clear
end

def cluster_capacity(site)
   rpt_body = Array.new
   fn = 'GetClusterCapacity'
   rpt_title = 'Cluster Capacity/Information Report - ' + @site_data[site]
   rpt_file = @dest_path + '/'+ fn + '_' + site + '.txt'
   pri_file = @src_path + '/' + fn + '_' + site + '.json'
   sec_file = @src_path + '/' + 'GetClusterInfo' + '_' + site + '.json'
   if File.exist?(pri_file) and File.exist?(sec_file) then
      read_pri_data(sec_file)
      @pri_data["result"]["clusterInfo"].each { |c|
         rpt_body.push( sprintf( "%33s : %-s", c[0], c[1] ) )
      }
      rpt_body.push( "  =" * 28 )
      read_pri_data_h(pri_file)
      @pri_data_h["result"]["clusterCapacity"].each_pair { |i,j|
         case i
         when "currentIOPS"
            rpt_body.push( sprintf( "%33s : %-s (over the last 5 seconds)", i, j ) )
         when "maxOverProvisionableSpace"
            rpt_body.push( sprintf( "%33s : %-s (\~%.3f TB) \
(maxProvisionedSpace * GetClusterFull)", i, j, j/1024.0/1024/1024/1024 ) )
         when "maxProvisionedSpace"
            rpt_body.push( sprintf( "%33s : %-s (\~%.3f TB)", i, j, j/1024.0**4 ) )
         when "maxUsedMetadataSpace", "usedMetadataSpace", "usedMetadataSpaceInSnapshots"
            rpt_body.push( sprintf( "%33s : %-s (\~%d GB)", i, j, j/1024**3 ) )
         when "nonZeroBlocks"
            rpt_body.push( sprintf( "%33s : %-s (4 KiB blocks with data)", i, j ) )
         when "maxUsedSpace", "usedSpace", "provisionedSpace"
            rpt_body.push( sprintf( "%33s : %-s (\~%.3f TB)", i, j, j/1024.0**4 ) )
         when "zeroBlocks"
            rpt_body.push( sprintf( "%33s : %-s (4 KiB blocks without data)", i, j ) )
         else
            rpt_body.push( sprintf( "%33s : %-s", i, j ) )
         end
      }
      rpt_body.push("\n")
      puts "\nReport body: #{rpt_body.inspect}" if @verbose
      prt_report(rpt_file,rpt_title,rpt_body)
   else
      @mymsg.push("Critical:  Cannot access #{pri_file} and/or #{sec_file}.")
   end
   rpt_body.clear
end

def hardwareinfo(site)
   rpt_body = Array.new
   fn = 'GetHardwareInfo'
   rpt_title = 'Hardware Information Report - ' + @site_data[site]
   rpt_file = @dest_path + '/'+ fn + '_' + site + '.txt'
   pri_file = @src_path + '/' + fn + '_' + site + '.json'
   if File.exist?(pri_file) then
      read_pri_data_h(pri_file)
      @pri_data_h["result"]["nodes"].each { |n|
         if n["result"]["hardwareInfo"].key?("nvram") then
            rpt_body.push("Node ID: #{n["nodeID"]}\tError(s): \
#{n["result"]["hardwareInfo"]["nvram"]["errors"]["numOfErrorLogEntries"]}")
            rpt_body.push("~ ~ ~ ~ ~ ~ ~ ~")
            if not n["result"]["hardwareInfo"]["nvram"]["extended"]["errorConditions"].nil? then
               n["result"]["hardwareInfo"]["nvram"]["extended"]["errorConditions"].each_value { |e|
                  rpt_body.push( sprintf( "%43s: %-s", 'ERROR Condition', e ) )
               }
            end
            n["result"]["hardwareInfo"]["nvram"]["extended"]["measurement"].each { |m|
               if not m["errorPeriod"].nil? then
                  mylabel = 'errorPeriod'
                  if m["errorPeriod"].class == Hash then
                     rpt_body.push( sprintf( "%43s: %-s", mylabel, m["errorPeriod"] ) )
                  else
                     m["errorPeriod"].each { |eP|
                        rpt_body.push( sprintf( "%43s: %-s", mylabel, eP ) )
                        mylabel = ''
                     }
                  end
               end
               if m["name"] =~ /Temperature/ then
                  rpt_body.push( sprintf( "%43s: %-s", m["name"], m["recent"] ) )
               end
            }
         else
            rpt_body.push("Node ID: #{n["nodeID"]}\tError(s): n/a")
            rpt_body.push("~ ~ ~ ~ ~ ~ ~ ~")
            rpt_body.push( sprintf( "%43s", 'No NVRAM data available.' ) )
         end
         rpt_body.push("\n")
      }
      puts "\nReport body: #{rpt_body.inspect}" if @verbose
      prt_report(rpt_file,rpt_title,rpt_body)
   else
      @mymsg.push("Critical:  Cannot access #{pri_file}.")
   end
   rpt_body.clear
end

def template(site)
   rpt_body = Array.new
   fn = 'ListDrives'
   rpt_title = 'Drives Report - ' + @site_data[site]
   rpt_file = @dest_path + '/'+ fn + '_' + site + '.txt'
   pri_file = @src_path + '/' + fn + '_' + site + '.json'
   if File.exist?(pri_file) then
      read_pri_data(pri_file)

      puts "\nReport body: #{rpt_body.inspect}" if @verbose
      prt_report(rpt_file,rpt_title,rpt_body)
   else
      @mymsg.push("Critical:  Cannot access #{pri_file}.")
   end
   rpt_body.clear
end

# verify source and destination directories
if File.directory?("#{@src_path}") and File.directory?("#{@dest_path}") then
   puts 'Directories verified' if @verbose
   @mymsg.clear
   @site_data.each_key { |site|
      vol_acc_grp(site)
      active_vol(site)
      nodes(site)
      accounts(site)
      vol_stats(site)
      cluster_capacity(site)
      hardwareinfo(site)
   }
   bailout if not @mymsg.empty?
else
   @mymsg.push("\nCritical")
   @mymsg.push("\tEither the source path of \"#{@src_path}\" or")
   @mymsg.push("\tthe destination path of \"#{@dest_path}\" is not valid.")
   bailout
end

