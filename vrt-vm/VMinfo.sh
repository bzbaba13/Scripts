#!/bin/bash
#
# This script is not meant to be run on it's own but to process output passed
# over via xargs to obtain information regardsing VM's to get around VM's
# with space(s) in the name of the configuration file, e.g.,
# /vrt/vm/bwell2.sys.adm2.websys.tmcs/Red Hat Enterprise Linux 4.vmx
#
# Usage:
# LOG_DIR={where_you_want_the_files_go}
# nhs -class vrt -businessunit "(web|uk)sys" -hostnameformat v3 |
#   onall -p -y -r 50 -Q -o $LOG_DIR '
#   echo -e "HOSTINFO, \c" ;
#   echo -e "$(free -m | head -2 | tail -1 | awk "{print \$2}")MB, \c" ;
#   echo -e "$(df -h -t ext3 | grep -v boot | tail -1 | awk "{print \$2}"), \c" ;
#   echo -e "$(df -h -t ext3 | grep -v boot | tail -1 | awk "{print \$3}")" ;
#   /usr/bin/vmware-cmd -l 1>/dev/null 2>&1 ;
#   [ "$?" -eq 0 ] && (echo "$(/usr/bin/vmware-cmd -l)" |
#   xargs -i /$CLASS/shared/bin/VMinfo.sh {}) || exit'
#
# $Id: VMinfo.sh,v 1.28 2008/09/19 19:57:54 francis Exp $ 

IFS=':'
echo -e "$1, \c"
echo -e "$(awk -F'"' '/displayName/ { print $2 }' $1), \c"
echo -e "$(awk -F'"' '/memsize/ { print $2 }' $1), \c"
echo -e "$(awk -F'"' '/guestOS/ { print $2 }' $1), \c"
echo -e "$(awk -F'"' '/virtualHW.version/ { print $2 }' $1), \c"
echo -e "$(awk -F'"' '/numvcpus/ {print $2}' $1)"
