#$Id: fs-perf-stats_tot.awk 10972 2018-03-19 21:32:40Z fma $

BEGIN {
   Rops = 0
   Wops = 0
   Rmb = 0
   Wmb = 0
   Tops = 0
   Tmb = 0
}

{
   if ( /TOTAL/ )
   {
      Rops += $3
      Wops += $4
      Rmb += $6
      Wmb += $7
      Tops += $9
      Tmb += $10
   }
   print $0
}

END {
   print "\n                     |   Read  Write |   Read  Write |  Total  Total |"
   print "                     |  ops/s  ops/s |   MB/s   MB/s |  ops/s   MB/s |"
   print "-------------------- | ------ ------ | ------ ------ | ------ ------ |"
   printf("%20s | %6d %6d | %6d %6d | %6d %6d |\n", 
"Grand Total", Rops, Wops, Rmb, Wmb, Tops, Tmb)
}
