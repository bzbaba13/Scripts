#$Id: fss_total.awk 10477 2017-04-19 00:04:55Z fma $

BEGIN {
   NT = 0
   NTc = 0
   T0 = 0
   T1 = 0
   T1c = 0
}

{
   if (/Mount/ && ! /Below/) NT += $6
   if (/Mount/ && ! /Below/) NTc += $NF
   if (/Tier\ 0/) T0 += $4
   if (/Tier\ 1/) T1 += $4
   if (/Tier\ 1/) T1c += $NF
}

END {
   print "\n= = = = = = = = = = = = = = = = = ="
   print "Totals:"
   printf("%18s: %6d GB, confined to %7d GB\n", "Not NAS-tiered", NT, NTc)
   printf("%18s: %6d GB\n", "Tier 0", T0)
   printf("%18s: %6d GB, confined to %7d GB\n", "Tier 1", T1, T1c)
   printf("%18s: %6d GB, confined to %7d GB\n\n", "Total consumed", NT+T0+T1, NTc+T1c)
}
