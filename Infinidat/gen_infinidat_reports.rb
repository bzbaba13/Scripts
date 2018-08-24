#!/usr/bin/env ruby -w

# == Synopsis
#
# This script reads the json output filef from Infinidat Infinibox storage
# systems fetched via API and prints out reports in text format.
#
#
# == Author
# Friendly half-blind Lead Storage/Systems Administrator with smiles.
#


require 'getoptlong'
require 'time'
require 'json'

@src_path = File.expand_path("~/ifndt-tmp")
@dest_path = '/var/www/html/ifndt_reports'
@verbose = false
@mymsg = Array.new
@myreport = Array.new
@pri_data_h = Hash.new
@sec_data_h = Hash.new
@data_h = Hash.new
@site_data = { "st1" => "Site One", "ev1" => "Site Two" }


def show_usage
   puts "Usage: #{$0} [--src|-s {arg}] [--dest|-d {arg}] [-v]"
   puts "\t--src|-s:\tPath to json output files from Infinibox (default: ~/ifndt-tmp)."
   puts "\t--dest|-d:\tPath for text report files (default: /var/www/html/ifndt_reports)."
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
   puts
   @mymsg.each{ |line|
      puts "#{line}"
   }
   puts
   exit 1
end

def read_pri_data_h(pri_file)
   @pri_data_h.clear
   @pri_data_h = JSON.load(IO.read(pri_file))
   puts "\n#{pri_file}\t#{@pri_data_h.length}\n" if @verbose
end

def read_sec_data_h(sec_file)
   @sec_data_h.clear
   @sec_data_h = JSON.load(IO.read(sec_file))
   puts "\n#{sec_file}\t#{@sec_data.length}\n" if @verbose
end

def read_data_h(data_file)
   @data_h.clear
   @data_h = JSON.load( IO.read ( data_file ) )
   puts "\n#{data_file}\t#{@data_h.length}\n" if @verbose
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

def load_data(datafiles)
   all_data = Array.new
   puts "\ndatafiles: #{datafiles.inspect}" if @verbose
   datafiles.each { |df|
      read_data_h(df)
      if not @data_h["result"].empty?
         @data_h["result"].each { |r|
            all_data.push(r)
         }
      end
      puts "\n#{df}\nall_data length: #{all_data.length}" if @verbose
   }
   return all_data
end

def users(site)
   rpt_body = Array.new
   users_data = Array.new
   datafiles = Array.new
   fn = 'users'
   rpt_title = 'Users Report - ' + @site_data[site]
   rpt_file = @dest_path + '/'+ fn + '_' + site + '.txt'
   datafiles = Dir.glob("#{fn}_*_#{site}.json").sort
   if not datafiles.empty?
      users_data = load_data(datafiles)
   else
      @mymsg.push("Critical:  Cannot find data file(s) related to #{fn}.")
   end
   if not users_data.empty?
      users_data.each { |u|
         u.each_pair { |k,v|
            rpt_body.push( sprintf( "%28s: %-s", k, v ) )
         }
         rpt_body.push("\n")
      }
   else
      rpt_body.push( sprintf( "%38s", "users_data is empty." ) )
   end
   prt_report(rpt_file,rpt_title,rpt_body)
   puts "\nReport body: #{rpt_body.length}" if @verbose
   rpt_body.clear
   datafiles.clear
   users_data.clear
end

def config(site)
   rpt_body = Array.new
   fn = 'config'
   rpt_title = 'Configuration Report - ' + @site_data[site]
   rpt_file = @dest_path + '/'+ fn + '_' + site + '.txt'
   pri_file = Dir.glob("#{fn}_*#{site}.json").pop
   if File.exist?(pri_file)
      read_pri_data_h(pri_file)
   else
      @mymsg.push("Critical:  Cannot access #{pri_file}.")
   end
   if not @pri_data_h["result"].empty?
      @pri_data_h["result"].each_key { |rk|
         rpt_body.push( sprintf( "%50s %-s", '', "= = = = = = = =" ) )
         rpt_body.push( sprintf( "%50s %-s", '', " #{rk} Section" ) )
         rpt_body.push( sprintf( "%50s %-s", '', "= = = = = = = =" ) )
         if @pri_data_h["result"][rk].class == Hash
            if @pri_data_h["result"][rk].empty?
               rpt_body.push( sprintf( "%50s %-s", '', 'No data available.' ) )
            else
               @pri_data_h["result"][rk].each_pair { |k,v|
                  if v.nil?
                     rpt_body.push( sprintf( "%60s : %-s", k, 'n/a' ) )
                  else
                     rpt_body.push( sprintf( "%60s : %-s", k, v ) )
                  end
               }
            end
         elsif @pri_data_h["result"][rk].class == Array
            @pri_data_h["result"][rk].each { |r|
               r.each_pair { |k,v|
                  if v.nil?
                     rpt_body.push (sprintf( "%60s : %-s", k, 'n/a' ) )
                  else
                     rpt_body.push (sprintf( "%60s : %-s", k, v ) )
                  end
               }
            }
         end
         rpt_body.push("\n")
      }
   else
      rpt_body.push("The 'result' of config has no content.\n")
   end
   prt_report(rpt_file,rpt_title,rpt_body)
   puts "\nReport body: #{rpt_body.length}" if @verbose
   rpt_body.clear
end

def pools(site)
   rpt_body = Array.new
   datafiles = Array.new
   pools_data = Array.new
   fn = 'pools'
   rpt_title = 'Pools Report - ' + @site_data[site]
   rpt_file = @dest_path + '/'+ fn + '_' + site + '.txt'
   datafiles = Dir.glob("#{fn}_*_#{site}.json").sort
   if not datafiles.empty?
      pools_data = load_data(datafiles)
   else
      @mymsg.push("Critical:  Cannot find data file(s) related to #{fn}.")
   end
   if not pools_data.empty?
      pools_data.each { |r|
         r.each_pair { |k,v|
            rpt_body.push( sprintf( "%38s : %-s", k, v ) )
         }
         rpt_body.push("\n")
      }
   else
      rpt_body.push("pools_data is empty.\n")
   end
   prt_report(rpt_file,rpt_title,rpt_body)
   puts "\nReport body: #{rpt_body.length}" if @verbose
   rpt_body.clear
   datafiles.clear
   pools_data.clear
end

def network_interfaces(site)
   rpt_body = Array.new
   datafiles = Array.new
   net_int_data = Array.new
   fn = 'network_interfaces'
   rpt_title = 'Network Interfaces Report - ' + @site_data[site]
   rpt_file = @dest_path + '/'+ fn + '_' + site + '.txt'
   datafiles = Dir.glob("#{fn}_*_#{site}.json").sort
   if not datafiles.empty?
      net_int_data = load_data(datafiles)
   else
      @mymsg.push("Critical:  Cannot find data file(s) related to #{fn}.")
   end
   if not net_int_data.empty?
      net_int_data.each { |n|
         n.each_pair { |k,v|
            if v.nil?
               rpt_body.push( sprintf( "%38s : %-s", k, 'n/a' ) )
            else
               rpt_body.push( sprintf( "%38s : %-s", k, v ) )
            end
         }
         rpt_body.push("\n")
      }
   else
      rpt_body.push("net_int_data is empty.\n")
   end
   prt_report(rpt_file,rpt_title,rpt_body)
   puts "\nReport body: #{rpt_body.length}" if @verbose
   rpt_body.clear
   datafiles.clear
   net_int_data.clear
end

def notifications(site)
   rpt_body = Array.new
   datafiles = Array.new
   notifications_data = Array.new
   fn = 'notifications'
   rpt_title = 'Notifications Report - ' + @site_data[site]
   rpt_file = @dest_path + '/'+ fn + '_' + site + '.txt'
   [ 'targets', 'rules' ].each { |nt|
      datafiles = Dir.glob("#{fn}_#{nt}_*_#{site}.json").sort
      if not datafiles.empty?
         notifications_data = load_data(datafiles)
         rpt_body.push( sprintf( "%28s %-s", '', '= = = = = = = = =' ) )
         rpt_body.push( sprintf( "%28s %-s", '', "'#{nt}' Section" ) )
         rpt_body.push( sprintf( "%28s %-s", '', '= = = = = = = = =' ) )
         if not notifications_data.empty?
            notifications_data.each { |nd|
               if not nd.empty?
                  nd.each_pair { |k,v|
                     rpt_body.push( sprintf( "%38s : %-s", k, v ) )
                  }
               else
                  rpt_body.push( sprintf( "#-28s", "No '#{nt}' available.\n\n" ) )
               end
            }
            notifications_data.clear
         else
            rpt_body.push( sprintf( "%28s %-s", '', "No '#{nt}' available.\n\n" ) )
         end
      else
         @mymsg.push("Critical:  Cannot find file(s) related to #{fn}_#{nt}.")
      end
      rpt_body.push("\n")
   }
   prt_report(rpt_file,rpt_title,rpt_body)
   puts "\nReport body: #{rpt_body.length}" if @verbose
   rpt_body.clear
   datafiles.clear
   notifications_data.clear
end

def hosts_details(site)
   rpt_body = Array.new
   datafiles = Array.new
   cgs_data = Array.new
   volumes_data = Array.new
   hosts_data = Array.new
   fn = 'hosts'
   rpt_title = 'Hosts Details Report - ' + @site_data[site]
   rpt_file = @dest_path + '/'+ fn + '_' + site + '.txt'
   datafiles = Dir.glob("#{fn}_*_#{site}.json").sort
   if not datafiles.empty?
      hosts_data = load_data(datafiles)
   else
      @mymsg.push("Critical:  Cannot find file(s) related to #{fn}.")
   end
   fn = 'cgs'
   datafiles = Dir.glob("#{fn}_*_#{site}.json").sort
   if not datafiles.empty?
      cgs_data = load_data(datafiles)
   else
      @mymsg.push("Critical:  Cannot find file(s) related to #{fn}.")
   end
   fn = 'volumes'
   datafiles = Dir.glob("#{fn}_*_#{site}.json").sort
   if not datafiles.empty?
      volumes_data = load_data(datafiles)
   else
      @mymsg.push("Critical:  Cannot find file(s) related to #{fn}.")
   end
   if not hosts_data.empty? and not cgs_data.empty? and not volumes_data.empty?
      hosts_data.each { |h|
         rpt_body.push("Name: #{h["name"]} (#{h["id"]})  #LUNs: #{h["luns"].count}")
         h["luns"].each {|l|
            volumes_data.each {|v|
               if v["id"] == l["volume_id"]
                  cgs_info = 'Unknown'
                  cgs_data.each {|c|
                     if c["id"] == v["cg_id"]
                        cgs_info = c["name"] + " (" + c["id"].to_s + ")"
                     end
                  }
                  rpt_body.push("\tName: #{v["name"]} (#{v["id"]})  \
Size: #{v["size"]/1024**3} GiB   Cons-Grp: #{cgs_info}")
               end
            }
         }
         rpt_body.push("\n")
      }
   else
      rpt_body.push("Either 'hosts_data,' 'cgs_data,' or 'volumes_data' is empty.")
   end
   prt_report(rpt_file,rpt_title,rpt_body)
   puts "\nReport body: #{rpt_body.length}" if @verbose
   rpt_body.clear
   datafiles.clear
   cgs_data.clear
   volumes_data.clear
   hosts_data.clear
end

def cgs_volumes(site)
   rpt_body = Array.new
   datafiles = Array.new
   cgs_data = Array.new
   volumes_data = Array.new
   rpt_title = 'Consistency Groups Report - ' + @site_data[site]
   fn = 'cgs'
   rpt_file = @dest_path + '/'+ fn + '_' + site + '.txt'
   datafiles = Dir.glob("#{fn}_*_#{site}.json").sort
   if not datafiles.empty?
      cgs_data = load_data(datafiles)
   else
      @mymsg.push("Critical:  Cannot find file(s) related to #{fn}.")
   end
   fn = 'volumes'
   datafiles = Dir.glob("#{fn}_*_#{site}.json").sort
   if not datafiles.empty?
      volumes_data = load_data(datafiles)
   else
      @mymsg.push("Critical:  Cannot find file(s) related to #{fn}.")
   end
   if not cgs_data.empty? and not volumes_data.empty?
      cgs_data.each { |c|
         rpt_body.push("Name: #{c["name"]} (#{c["id"]})  #Members: \
#{c["members_count"]}  Replicated? #{c["is_replicated"]}  Type: #{c["type"]}")
         volumes_data.each { |v|
            if v["cg_id"] == c["id"]
               rpt_body.push("\t#{v["name"]} (#{v["id"]})  Size: \
#{v["size"]/1024**3} GiB  Used: #{v["used"]/1024**3} GiB")
            end
         }
         rpt_body.push("\n")
      }
   else
      rpt_body.push("Either 'cgs_data' or 'volumes_data' is empty.")
   end
   prt_report(rpt_file,rpt_title,rpt_body)
   puts "\nReport body: #{rpt_body.length}" if @verbose
   rpt_body.clear
   datafiles.clear
   cgs_data.clear
   volumes_data.clear
end

def network_spaces(site)
   rpt_body = Array.new
   datafiles = Array.new
   net_spc_data= Array.new
   mykey = ''
   fn = 'network_spaces'
   rpt_title = 'Network Spaces Report - ' + @site_data[site]
   rpt_file = @dest_path + '/'+ fn + '_' + site + '.txt'
   datafiles = Dir.glob("#{fn}_*_#{site}.json").sort
   if not datafiles.empty?
      net_spc_data = load_data(datafiles)
   else
      @mymsg.push("Critical:  Cannot find file(s) related to #{fn}.")
   end
   if not net_spc_data.empty?
      net_spc_data.each { |n|
         n.each_pair { |k,v|
            mykey = k
            case v.class.to_s
               when 'Array'
                  v.each { |vv|
                     rpt_body.push( sprintf( "%28s : %-s", mykey, vv ) )
                     mykey = ''
                  }
               when "Hash"
                  v.each_pair { |vk,vv|
                     rpt_body.push( sprintf( "%28s : %-s : %-s", mykey, vk, vv ) )
                     mykey = ''
                  }
               else
                  if not v.nil?
                     rpt_body.push( sprintf( "%28s : %-s", k, v ) )
                  else
                     rpt_body.push( sprintf( "%28s : %-s", k, 'n/a' ) )
                  end
            end
         }
         rpt_body.push( sprintf( "\n%-18s\n", '~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~' ) )
      }
   else
      rpt_body.push("net_spc_data is empty.")
   end
   prt_report(rpt_file,rpt_title,rpt_body)
   puts "\nReport body: #{rpt_body.length}" if @verbose
   rpt_body.clear
   datafiles.clear
   net_spc_data.clear
end

def san_clients(site)
   rpt_body = Array.new
   datafiles = Array.new
   san_clients_data= Array.new
   volumes_data = Array.new
   fn = 'san_clients'
   rpt_title = 'SAN Clients Report - ' + @site_data[site]
   rpt_file = @dest_path + '/'+ fn + '_' + site + '.txt'
   datafiles = Dir.glob("#{fn}_*_#{site}.json").sort
   if not datafiles.empty?
      san_clients_data = load_data(datafiles)
   else
      @mymsg.push("Critical:  Cannot find file(s) related to #{fn}.")
   end
   fn = 'volumes'
   datafiles = Dir.glob("#{fn}_*_#{site}.json").sort
   if not datafiles.empty?
      volumes_data = load_data(datafiles)
   else
      @mymsg.push("Critical:  Cannot find file(s) related to #{fn}.")
   end
   if not san_clients_data.empty? and not volumes_data.empty?
      san_clients_data.each { |s|
         s.each_pair { |k,v|
            mykey = k
            case v.class.to_s
               when 'Array'
                  v.each { |vv|
                     if k == 'luns'
                        volumes_data.each { |vd|
                           if vd["id"] == vv["volume_id"]
                              rpt_body.push( sprintf( "%38s : %-s (%-s)  Size: %-s GB", \
mykey, vd["name"] , vd["id"], vd["size"]/1024**3 ) )
                           end
                        }
                     elsif k == 'hosts'
                        mykey = k
                        vv.each_pair { |vvk,vvv|
                           if vvk == 'luns'
                              vvv.each { |vvvv|
                                 volumes_data.each { |vd|
                                    if vd["id"] == vvvv["volume_id"]
                                       rpt_body.push( sprintf( "%38s : luns : %-s (%-s)  \
   Size: %-s GB", mykey, vd["name"], vd["id"], vd["size"]/1024**3 ) )
                                    end
                                 }
                              }
                           elsif vvk == 'ports'
                              vvv.each { |vvvv|
                                 rpt_body.push( sprintf( "%38s : ports : %-s", \
mykey, vvvv ) )
                              }
                           else
                              if vvv.nil?
                                 rpt_body.push( sprintf( "%38s : %-s : %-s", \
mykey, vvk, 'n/a' ) )
                              else
                                 rpt_body.push( sprintf( "%38s : %-s : %-s", \
mykey, vvk, vvv ) )
                              end
                           end
                           mykey = ''
                        }
                     else
                        rpt_body.push( sprintf( "%38s : %-s", mykey, vv ) )
                     end
                     mykey = ''
                  }
               when "Hash"
                  v.each_pair { |vk,vv|
                     rpt_body.push( sprintf( "%38s : %-s : %-s", mykey, vk, vv ) )
                  }
               else
                  if not v.nil?
                     rpt_body.push( sprintf( "%38s : %-s", k, v ) )
                  else
                     rpt_body.push( sprintf( "%38s : %-s", k, 'n/a' ) )
                  end
            end
         }
         rpt_body.push( sprintf( "\n%23s%-s\n", '', '~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~' ) )
      }
   else
      rpt_body.push("Either san_clients_data or volumes_data is empty.")
   end
   puts "\nReport body: #{rpt_body.length}" if @verbose
   prt_report(rpt_file,rpt_title,rpt_body)
   rpt_body.clear
   datafiles.clear
   san_clients_data.clear
   volumes_data.clear
end

def filesystems(site)
   rpt_body = Array.new
   datafiles = Array.new
   filesystems_data= Array.new
   fn = 'filesystems'
   rpt_title = 'File Systems Report - ' + @site_data[site]
   rpt_file = @dest_path + '/'+ fn + '_' + site + '.txt'
   datafiles = Dir.glob("#{fn}_*_#{site}.json").sort
   if not datafiles.empty?
      filesystems_data = load_data(datafiles)
   else
      @mymsg.push("Critical:  Cannot find file(s) related to #{fn}.")
   end
   if not filesystems_data.empty?
      filesystems_data.each { |f|
         f.each_pair { |k,v|
            if v.nil?
               rpt_body.push( sprintf( "%38s : %-s", k, 'n/a' ) )
            else
               rpt_body.push( sprintf( "%38s : %-s", k, v ) )
            end
         }
         rpt_body.push( "\n" )
      }
   else
      rpt_body.push( sprintf( "%38s", 'No file system exists.' ) )
   end
   prt_report(rpt_file,rpt_title,rpt_body)
   puts "\nReport body: #{rpt_body.length}" if @verbose
   rpt_body.clear
   datafiles.clear
   filesystems_data.clear
end

def services(site)
   rpt_body = Array.new
   datafiles = Array.new
   services_data= Array.new
   fn = 'services'
   rpt_title = 'Services Report - ' + @site_data[site]
   rpt_file = @dest_path + '/'+ fn + '_' + site + '.txt'
   datafiles = Dir.glob("#{fn}_*_#{site}.json").sort
   if not datafiles.empty?
      services_data = load_data(datafiles)
   else
      @mymsg.push("Critical:  Cannot find file(s) related to #{fn}.")
   end
   if not services_data.empty?
      services_data.each { |s|
         s.each_pair { |k,v|
            mykey = k
            if v.class == Array
               v.each { |vv|
                  vv.each_pair { |vvk,vvv|
                     rpt_body.push( sprintf( "%28s : %-8s : %-s", mykey, vvk, vvv ) )
                     mykey = ''
                  }
               }
            else
               rpt_body.push( sprintf( "%28s : %-s", k, v ) )
            end
         }
         rpt_body.push("\n")
      }
   else
      rpt_body.push("#{fn}_data is empty.")
   end
   prt_report(rpt_file,rpt_title,rpt_body)
   puts "\nReport body: #{rpt_body.length}" if @verbose
   rpt_body.clear
   datafiles.clear
end

def events(site)
   rpt_body = Array.new
   datafiles = Array.new
   events_data= Array.new
   num = 10
   rpt_title = 'Events (critical, error, & warning) Report - ' + @site_data[site]
   fn = 'events'
   rpt_file = @dest_path + '/'+ fn + '_' + site + '.txt'
   [ "critical", "error", "warning" ].each { |l|
      fn = 'events' + '_' + l
      datafiles = Dir.glob("#{fn}_*_#{site}.json").sort
      rpt_body.push( sprintf( "%28s %s %s\n", '= = =', "#{l.upcase} Events", '= = =' ) )
      if not datafiles.empty?
         events_data = load_data(datafiles)
      else
         @mymsg.push("Critical:  Cannot find file(s) related to #{fn}.")
      end
      if not events_data.empty?
         for i in 0..(num - 1)
            events_data[i].each_pair { |k,v|
               if k !~ /template/ and k !~ /system_version/
                  if k == 'timestamp'
                     rpt_body.push( sprintf( "%28s : %s\n", k, Time.at( v.to_s.slice(0,10).to_i ) ) )
                  else
                     rpt_body.push( sprintf( "%28s : %s\n", k, v ) )
                  end
               end
            }
            rpt_body.push( sprintf( "%23s %s", '', '- - - - - - - -' ) )
         end
         rpt_body.push("\n")
      else
         rpt_body.push("\t\tNo #{l} events.")
         rpt_body.push("\n")
         rpt_body.push( sprintf( "%23s %s", '', '- - - - - - - -' ) )
         rpt_body.push("\n")
      end
   }
   prt_report(rpt_file,rpt_title,rpt_body)
   puts "\nReport body: #{rpt_body.length}" if @verbose
   rpt_body.clear
   datafiles.clear
end

#def template(site)
#   rpt_body = Array.new
#   datafiles = Array.new
#   {blah}_data= Array.new
#   fn = 'filename'
#   rpt_title = 'Drives Report - ' + @site_data[site]
#   rpt_file = @dest_path + '/'+ fn + '_' + site + '.txt'
#   pri_file = @src_path + '/' + fn + '_' + site + '.json'
#   datafiles = Dir.glob("#{fn}_*_#{site}.json").sort
#   if not datafiles.empty?
#      {blah}_data = load_data(datafiles)
#   else
#      @mymsg.push("Critical:  Cannot find file(s) related to #{fn}.")
#   end
#   if not {blah}_data.empty?
#      {blah}_data.each { |x|
#      }
#   else
#      rpt_body.push("{blah}_data is empty.")
#   end
#   prt_report(rpt_file,rpt_title,rpt_body)
#   puts "\nReport body: #{rpt_body.length}" if @verbose
#   rpt_body.clear
#   datafiles.clear
#end

# verify source and destination directories
if File.directory?("#{@src_path}") and File.directory?("#{@dest_path}")
   puts 'Directories verified' if @verbose
   Dir.chdir(@src_path)
   @mymsg.clear
   @site_data.each_key { |site|
      users(site)
      config(site)
      pools(site)
      network_interfaces(site)
      notifications(site)
      hosts_details(site)
      cgs_volumes(site)
      network_spaces(site)
      san_clients(site)
      filesystems(site)
      services(site)
      events(site)
   }
   bailout if not @mymsg.empty?
else
   @mymsg.push("\nCritical")
   @mymsg.push("\tEither the source path of \"#{@src_path}\" or")
   @mymsg.push("\tthe destination path of \"#{@dest_path}\" is not valid.")
   bailout
end
