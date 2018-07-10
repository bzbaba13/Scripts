#$Id: all_pools.awk 10675 2017-07-19 21:01:27Z fma $

BEGIN {
   avail = 0
   total = 0
   while ( (getline < "/tmp/pool_name.txt") > 0 )
      PoolName[$1] = $4"\t\t"$9"\t"$10"\t"$11"\t"$12
}

{
   if (/POLN/) {
      avail += $5
      total += $6
   }
   print $0"\t"PoolName[$1]
}

END {
   printf"%47s\n", "= = = = = = = = = = = = ="
   printf("%20s %12d %12d\n", "Totals (TB):", avail/1024/1024, total/1024/1024)
}
