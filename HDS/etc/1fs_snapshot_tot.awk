#$Id: 1fs_snapshot_tot.awk 10508 2017-04-28 00:01:12Z fma $

BEGIN {
   usage = 0
}

{
   if (/Manually/ && /TB/) usage += $4*1024
   if (/Manually/ && /GB/) usage += $4
   if (/Manually/ && /MB/) usage += $4/1024
   if (/By\ Rule/ && /TB/) usage += $5*1024
   if (/By\ Rule/ && /GB/) usage += $5
   if (/By\ Rule/ && /MB/) usage += $5/1024
   if (/By\ Object\ Replication/ && /TB/) usage += $6*1024
   if (/By\ Object\ Replication/ && /GB/) usage += $6
   if (/By\ Object\ Replication/ && /MB/) usage += $6/1024
   print $0
}

END {
   print "= = = = = = = = = = = = = = = = = ="
   printf("%41s: %11.3f GB\n\n", "Total Preserved Space for snapshot(s)", usage)
}
