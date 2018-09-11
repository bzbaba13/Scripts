#!/usr/bin/env ruby -w

#== Synopsis
#
# This script updates the NFS exports permissions, i.e., NFS clients, of
# a file system on the Infindat Infinibox storage systems.
#
#
# == Author
# Friendly half-blind Mgr, Storage & Linux Systems Administrator
#


require 'getoptlong'
require 'io/console'
require 'json'
require 'net/http'
require 'openssl'
require 'uri'

@tmp_path = '/tmp'
@ro_user = "ro_user"
@ro_pw = "ro_password"
@rw_user = "rw_user"
@rw_pw = "rw_password"
@site_data = { "st1" => "site1", "st2" => "site2" }
@uri_query_type = '/api/rest/exports?page_size=888&fields='
@uri_query_fields = 'export_path,id,permissions'
@fs_id = 'bad_id'
@exports_info = Array.new
@verbose = false
@mymsg = Array.new
@mysite = ''
@input_path = ''
@myperms = Array.new
@new_perms = Array.new
@new_perms_json = ''
@del_perms = Array.new

def show_usage
   puts "Usage: #{$0} [--site|-s {arg}] [--verbose|-v]"
   puts "\t--site|-s:\tsite: st1 (site1) or st2 (site2)"
   puts "\t--help|-h:\tThis message"
   puts "\t--verbose|-v:\tVerbose output for debug purposes."
   puts
   exit 2
end

opts = GetoptLong.new(
   [ "--site", "-s", GetoptLong::REQUIRED_ARGUMENT ],
   [ "--help", "-h", GetoptLong::NO_ARGUMENT ],
   [ "--verbose", "-v", GetoptLong::NO_ARGUMENT ]
)

opts.each {|opt, arg|
   case opt
   when /-s/
      @mysite = arg
   when /-h/
      show_usage
   when /-v/
      @verbose = true
   else
      show_usage
   end
}

def bailout
   @mymsg.each do |line|
      puts "#{line}"
   end
   puts
   exit 1
end

def fetch_exports
   @mymsg.clear
   @exports_info.clear
   case @mysite
   when "st1"
      base_uri = 'https://site1'
   when "st2"
      base_uri = 'https://site2'
   else
      base_uri = 'http://bad_site'
   end
   uri = URI( base_uri + @uri_query_type + @uri_query_fields )
   puts "\tURI: #{uri}" if @verbose
   if system("ping", "-c1", uri.host, :out=>"/dev/null", :err=>"/dev/null") == true
      Net::HTTP.start( uri.host, uri.port,
                       :open_timeout => 3,
                       :read_timeout => 8,
                       :use_ssl => uri.scheme == 'https',
                       :verify_mode => OpenSSL::SSL::VERIFY_NONE ) do |http|
         request = Net::HTTP::Get.new uri.request_uri
         request.basic_auth @ro_user, @ro_pw
         response = http.request request
         puts "\tHTTP Response: #{response}" if @verbose
         if response.code == "200"
            data = JSON.load( response.body )
            @exports_info = data["result"]
         else
            @mymsg.push("Unable to fetch exports data from #{base_uri}.")
            @mymsg.push("HTTP response is: #{response}.")
         end
      end
   else
      @mymsg.push("#{uri.host} is not reachable via ICMP PING packet.")
   end
   if not @mymsg.empty?
      bailout
   end
end

def display_exports_info
   puts "The following export path(s) is/are identified for #{@site_data[@mysite]}:"
   @exports_info.each do |e|
      puts "\t#{e["export_path"]} (#{e["id"]})"
   end
end

def request_input
   puts "\nPlease provide the NFS export path you would like to update, e.g., /mypath):"
   t = 0
   loop do
      @input_path = gets.chomp!
      break if (not @input_path.empty? or t == 2)
      t += 1
   end
   puts "\tUser's input:  #{@input_path}" if @verbose
   if @input_path.empty?
      @mymsg.push("No export path provided.  Abort.")
      bailout
   end
end

def obtain_id
   @fs_id = 'bad_id'
   @myperms.clear
   @exports_info.each do |e|
      if e["export_path"] == @input_path
         @fs_id = e["id"]
         puts "\tFound export path #{e["export_path"]}." if @verbose
         @myperms = e["permissions"]
         puts "\t@myperms: #{@myperms}" if @verbose
         break
      else
         puts "\tNo match: #{e["export_path"]}" if @verbose
      end
   end
end

def display_perms
   if not @myperms.empty?
      puts "Found existing permissions as follows..."
      @myperms.each do |p|
         puts "\t#{p}"
      end
   else
      puts "No existing permissions found."
   end
end

def request_deletion
   @del_perms.clear
   if not @myperms.empty?
      puts "\nPlease enter the NFS client(s) for deletion one at a time,"
      puts "e.g., myhost.mydomain, IPv4 address, IPv4 address range."
      puts "Press the <Enter> key after each entry."
      puts "Enter 'all' to delete all existing permission(s)."
      puts "Enter 'none' to skip.  Enter 'done' when finished."
      perms = ''
      loop do
         perms = gets.chomp!
         case perms.downcase
         when 'none'
            puts "Skipping deletion as requested."
            @del_perms.clear
            puts
            break
         when 'all'
            @myperms.each do |p|
               @del_perms.push( p["client"] )
            end
            puts
            break
         when 'done'
            puts
            break
         else
            @del_perms.push( perms )
         end
      end
      @del_perms.delete("")
      @del_perms.uniq!
      @del_perms.compact!
      puts "\tdel_perms: #{@del_perms}" if @verbose
   else
      puts "\tNo existing permissions for deletion." if @verbose
   end
end

def request_new_perms
   puts "Please provide new permission(s) below in the following space-delimited format:"
   puts "<NFS client (FQDN|IPv4)> <access (ro/rw)>.  Press the <Enter> key after each entry,"
   puts "e.g., myhost.mydomain ro"
   puts "      192.168.0.1 rw"
   puts "      192.168.0.1-192.168.0.254 ro"
   puts "Enter 'done' when finished."
   perms = ''
   @new_perms.clear
   loop do
      perms = gets.chomp!
      break if perms.downcase == 'done'
      @new_perms.push( perms.split(' ')[0] => perms.split(' ')[1] ) if not perms.empty?
   end
   puts "\tuser's input: #{@new_perms}" if @verbose
   if @new_perms.empty?
      puts "No new permission(s) specified."
   end
end

def clean_input_data
   puts "\tVerifying user's input..." if @verbose
   bad_perms = Array.new
   if not @new_perms.empty?
      @new_perms.each do |n|
         n.each_pair do |k,v|
            if k =~ /\// or v.nil? or ( v.downcase != "rw" and v.downcase != "ro" )
               bad_perms.push(n)
            end
         end
      end
      puts "\tbad_perms: #{bad_perms}" if @verbose
      if not bad_perms.empty?
         puts "Some of the entries provided are invalid and will be removed:"
         bad_perms.each do |b|
            puts "\t#{b}"
         end
         bad_perms.each do |b|
            @new_perms.delete(b)
         end
         puts "\tcleaned new_perms: #{@new_perms}" if @verbose
      else
         puts "\tAll data clean." if @verbose
      end
      puts
   end
end

def confirm_changes
   if @del_perms.empty? and @new_perms.empty?
      @mymsg.push("No deletion(s) and/or addition(s) specified.  Exiting.")
      bailout
   else
      puts "The following changes have been requested for export path #{@input_path}:"
      if not @del_perms.empty?
         puts "Deletion(s):"
         @del_perms.each do |d|
            puts( sprintf("%8s%s", '', d) )
         end
         puts
      end
      if not @new_perms.empty?
         puts "Addition(s):"
         @new_perms.each do |n|
            n.each_pair do |k,v|
               puts( sprintf("%8s%s: %s", '', k, v) )
            end
         end
         puts
      end
      puts "Please confirm the following requested changes: (y|N)"
      ans = gets.chomp!
      if ans.downcase =~ /y/
         puts "\nProceeding with confirmed changes..."
      else
         @mymsg.push("Cancelled.")
         bailout
      end
   end
end

def delete_perms
   if not @del_perms.empty?
      @del_perms.each do |d|
         @myperms.each_with_index do |p,i|
            if p["client"] == d
               @myperms.delete_at(i)
               puts "\tDeleted #{p} based on #{d}" if @verbose
               break
            else
               puts "\tNo match: #{d} & #{p["client"]}" if @verbose
            end
         end
      end
   end
end

def request_rw_pw
   t = 0
   puts
   loop do
      @rw_pw = STDIN.getpass("Please enter password for #{@rw_user}: ")
      break if (not @rw_pw.empty? or t == 2)
      t += 1
   end
   if @rw_pw.empty?
      @mymsg.push("No password entered after 3 times.  Abort.")
      bailout
   end
end

def build_json
   puts "Building JSON structure..." if @verbose
   body = Array.new
   new_perms_h = Hash.new
   @new_perms.each do |n|
      n.each_pair do |k,v|
         body.push( "access" => v.upcase,
                    "client" => k,
                    "no_root_squash" => true )
      end
   end
   puts "\tbody: #{body}" if @verbose
   puts "\tmyperms after deletion: #{@myperms}" if @verbose
   if not body.empty?
      @myperms.push( body )
      @myperms.flatten!
   end
   puts "\tmyperms new: #{@myperms}" if @verbose
   new_perms_h["permissions"] = @myperms
   puts "\tHash: #{new_perms_h}" if @verbose
   @new_perms_json = new_perms_h.to_json
   puts "\tJSON: #{@new_perms_json}" if @verbose
end

def transmit_changes
   puts "Transmitting changes to #{@site_data[@mysite]}..."
   @mymsg.clear
   case @mysite
   when "st1"
      base_uri = 'https://site1'
   when "st2"
      base_uri = 'https://site2'
   else
      base_uri = 'http://bad_site'
   end
   uri = URI( base_uri + '/api/rest/exports/' + @fs_id.to_s )
   if system("ping", "-c1", uri.host, :out=>"/dev/null", :err=>"/dev/null") == true
      Net::HTTP.start( uri.host, uri.port,
                       :open_timeout => 3,
                       :read_timeout => 8,
                       :use_ssl => uri.scheme == 'https',
                       :verify_mode => OpenSSL::SSL::VERIFY_NONE ) do |http|
         request = Net::HTTP::Put.new uri.request_uri
         request.basic_auth @rw_user, @rw_pw
         request.content_type = "application/json"
         request.body = @new_perms_json
         response = http.request request
         puts "\tHTTP Response: #{response}" if @verbose
         if response.code == "200"
            puts "Successfully PUT data to #{base_uri}."
            puts "New permission(s) for export path of #{@input_path}:"
            data = JSON.load( response.body )
            data["result"]["permissions"].each do |p|
               puts "\t#{p}"
            end
         else
            @mymsg.push("Failed to PUT data to #{base_uri}.")
            @mymsg.push("HTTP response is: #{response}.")
            message = JSON.load(response.body)["error"]["message"]
            @mymsg.push("Response message: #{message}")
         end
         puts
      end
   else
      @mymsg.push("#{uri.host} is not reachable via ICMP PING packet.")
   end
   if not @mymsg.empty?
      bailout
   end
end


# main line
begin
   fetch_exports
   display_exports_info
   request_input
   obtain_id
   if @fs_id != 'bad_id'
      display_perms
      request_deletion
      request_new_perms
      clean_input_data
      confirm_changes
      delete_perms
      build_json
      request_rw_pw
      transmit_changes
   else
      @mymsg.push("Unable to find user-provided export path #{@input_path}.  Abort.")
      bailout
   end
rescue Exception
   puts "\nException occurred.  Abort."
end
