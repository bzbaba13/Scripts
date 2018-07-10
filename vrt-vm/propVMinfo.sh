#!/bin/zsh

# $Id: propVMinfo.sh,v 1.2 2008/09/19 19:56:15 francis Exp $


for box in `nhs -class vrt -classinstance 1 -businessunit "(web|uk)sys" \
  -hostnameformat v3 | fping -a`
do
  echo ${box}
  scp -p -o StrictHostKeyChecking=no VMinfo.sh root@${box}:/vrt/shared/bin
done
