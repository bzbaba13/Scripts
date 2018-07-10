#$Id: nas_total.awk 10477 2017-04-19 00:04:55Z fma $

BEGIN {
   NT = 0
   NTc = 0
   T0 = 0
   T1 = 0
   T1c = 0
}

{
   if (/NAS-tiered/) NT += $3
   if (/NAS-tiered/) NTc += $7
   if (/Tier\ 0/) T0 += $3
   if (/Tier\ 1/) T1 += $3
   if (/Tier\ 1/) T1c += $7
   print $0
}

END {
   print "= = = = = = = = = = = = = = = = = ="
   print "Totals:"
   printf("%18s: %6d GB, confined to %7d GB\n", "Not NAS-tiered", NT, NTc)
   printf("%18s: %6d GB\n", "Tier 0", T0)
   printf("%18s: %6d GB, confined to %7d GB\n", "Tier 1", T1, T1c)
   printf("%18s: %6d GB, confined to %7d GB\n\n", "Total consumed", NT+T0+T1, NTc+T1c)
}
