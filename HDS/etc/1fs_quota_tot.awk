#$Id: 1fs_quota_tot.awk 10489 2017-04-25 21:39:02Z fma $

BEGIN {
   usage = 0
   limit = 0
}

{
   if (/Usage/ && /TB/) usage += $3*1024
   if (/Usage/ && /GB/) usage += $3
   if (/Usage/ && /MB/) usage += $3/1024
   if (/Limit/ && /TB/) limit += $3*1024
   if (/Limit/ && /GB/) limit += $3
   if (/Limit/ && /MB/) usage += $3/1024
   print $0
}

END {
   print "\n= = = = = = = = = = = = = = = = = ="
   print "Totals:"
   printf("%-16s: " usage " GB\n", "Usage")
   printf("%-16s: " limit " GB\n\n", "  Limit")
}
