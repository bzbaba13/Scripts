#!/usr/bin/env ruby -w

# This is a simple ruby [1.8.x] script written to convert public keys 
# generated by Windows program, e.g., Putty, Secure CRT, etc. to the
# format that typical SSH of the UNIX world utilizes.  The script 
# removes leading and trailing whitespace, <ctrl>M, \r, etc. characters.
# SSH2 DSA public key file is assumed, for that is our current policy.
# Enhancement to detect RSA vs. DSA key file may be added in the future
# if time permits.


require 'getoptlong'

fname = ''
email = 'Where is the E-mail Address?'
type = 'dsa'
verbose = false
pubkey = Array.new

def showusage
    puts "Usage: #{$0}"
    puts "\t\t--email|-e:\t<E-mail address>"
    puts "\t\t--file|-f:\t<Path to the file, e.g., ~/tmp/mykey.txt>"
    puts "\t\t--type|-t:\t<Type of key, i.e., DSA (default) or RSA>"
    puts "\t\t--help|-h:\tThis message"
    puts "\t\t--verbose|-v:\tDumps contents of original file as well."
    puts
    exit
end

opts = GetoptLong.new(
    [ "--email", "-e", GetoptLong::REQUIRED_ARGUMENT ],
    [ "--file", "-f", GetoptLong::REQUIRED_ARGUMENT ],
    [ "--type", "-t", GetoptLong::REQUIRED_ARGUMENT ],
    [ "--help", "-h", GetoptLong::NO_ARGUMENT ],
    [ "--verbose", "-v", GetoptLong::NO_ARGUMENT ]
)


opts.each do |opt, arg|
#    puts "Option: #{opt} with argument of #{arg.inspect}\n"
    case opt
        when /-f/
            fname = arg
        when /-e/
            email = arg
        when /-t/
            type = arg
        when /-v/
            verbose = true
        when /-h/
            showusage
        else
            showusage
    end
end

# bail if no option/argument for file name is provided
showusage if (fname.length == 0)

if FileTest.exist?(fname) then
    ftype = File.ftype(fname)
    case ftype
        when 'file'
            aFile = File.open(fname, 'r')
            pubkey.clear
            if type.downcase == 'rsa' then
                pubkey.push("ssh-rsa ")
            else
                pubkey.push("ssh-dss ")
            end
            if verbose == true then
                puts "\nContents of original file..."
                28.times { print '~' }
                puts
            end
            aFile.each_line {|ln|
                puts ln.dump if (verbose == true)
                pubkey.push(ln.strip) if !(
# line exclusion beings
                    ln =~ /BEGIN/ ||
                    ln =~ /SSH/ ||
                    ln =~ /^Subject/ ||
                    ln =~ /^Comment/ ||
                    ln =~ /ModBitSize/ ||
                    ln =~ /END/
# line exclusion ends
                )
            }
            pubkey.push(" " + email)
            aFile.close
            puts
            puts pubkey.to_s
        else
            puts "\nSorry, #{fname} is not a file but a #{ftype}.\n\n"
            showusage
    end
else
    puts "\nSorry, #{fname} does not exist.\n\n"
    showusage
end
