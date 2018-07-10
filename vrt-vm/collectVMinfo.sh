#!/bin/bash
#
# This script is for gathering information in regards to registered VM systems
# and forward the data file via rsync to the vrt-vm central data storage for
# the vrt-vm application.
#
#
# Author:
#
# Friendly half-blind Systems Administrator of Ticketmaster.

# $Id: collectVMinfo.sh,v 1.18 2008/12/24 22:14:16 francis Exp francis $ 


PATH=/usr/bin:/bin:/sbin
cfg_file='/opt/local/etc/vrt-vm/collectVMinfo.conf'
rsync_opt=''
tmp_file='/tmp/vm_cfg'
out_line=''
unset CENTRAL_HOST
unset CENTRAL_MODULE
unset TIMEOUT

[[ -f ${cfg_file} ]] && . ${cfg_file}

my_central_host=${CENTRAL_HOST:=vrt-vm}
my_central_module=${CENTRAL_MODULE:=vrt-vm}
my_timeout=${TIMEOUT:=8}

# functions
cleanup() {
   rm -f ${tmp_file} ${out_file} 1>/dev/null 2>&1
}


# sleep for some seconds before begin processing
sleep $(( ${RANDOM} / 1000 ))

# verify that the central_host is up with rsyncd running and module configured
rsync -q --timeout=${my_timeout} ${rsync_opt} ${my_central_host}::${my_central_module} \
  1>/dev/null 2>&1
[[ "$?" != '0' ]] && exit

# figure out fqdn of host
if [[ -f /etc/nodename ]] ; then
   # spine (rubix) managed systems should have fqdn in this file
   fqdn=$(< /etc/nodename)
else
   # use reverse dns to try it otherwise
   ip=$(ifconfig eth0 | head -n2 | tail -n1 | awk '{print $2}' | awk -F':' '{ print $NF }')
   fqdn=$(host $ip | awk '{ print $NF }' | cut -d'.' -f1-5)
fi

# no fqdn, no luv for you
if [[ ! -z "$fqdn" ]] ; then
   out_file="/tmp/$fqdn"
   cleanup
else
   echo 'Cannot figure out the FQDN; cannot proceed.'
   exit 1
fi

# collect information about host system
tot_ram="$(free -m | head -n2 | tail -1 | awk '{ print $2 }')MB"
root_size=$(df -h -t ext3 | grep -v boot | tail -n1 | awk '{ print $2 }')
root_avail=$(df -h -t ext3 | grep -v boot | tail -n1 | awk '{ print $3 }')
echo "HOSTINFO, ${tot_ram}, ${root_size}, ${root_avail}" > ${out_file}

# make sure vmware-cmd exists AND can be executed with exit code of 0 or report it
if [[ -x /usr/bin/vmware-cmd ]] ; then
   /usr/bin/vmware-cmd -l 1>${tmp_file} 2>/dev/null
   if [[ "$?" == '0' ]] ; then
      while read vm_cfg ; do
         disp_name=$(awk -F'"' '/displayName/ { print $2 }' "$vm_cfg")
         mem_size=$(awk -F'"' '/memsize/ { print $2 }' "$vm_cfg")
         guest_os=$(awk -F'"' '/guestOS/ { print $2 }' "$vm_cfg")
         virt_hw_ver=$(awk -F'"' '/virtualHW.version/ { print $2 }' "$vm_cfg")
         num_v_cpu=$(awk -F'"' '/numvcpus/ { print $2 }' "$vm_cfg")
         [[ -z ${num_v_cpu} ]] && num_v_cpu=1

         # output data in YAML format
         out_line="${fqdn}:"
         out_line="${out_line}\n  vm_vmx:\n    ${vm_cfg}"
         out_line="${out_line}\n  vm_name:\n    ${disp_name}"
         out_line="${out_line}\n  vm_ram:\n    ${mem_size}"
         out_line="${out_line}\n  vm_os:\n    ${guest_os}"
         out_line="${out_line}\n  vm_hw_ver:\n    ${virt_hw_ver}"
         out_line="${out_line}\n  vm_vcpus:\n    ${num_v_cpu}"
         echo -e "$out_line" >> ${out_file}
      done < ${tmp_file}
   else
      out_line="${fqdn}:"
      out_line="${out_line}\n  vm_vmx:\n"
      out_line="${out_line}\n  vm_name:\n    CANNOT"
      out_line="${out_line}\n  vm_ram:\n    execute"
      out_line="${out_line}\n  vm_os:\n    vmware-cmd"
      out_line="${out_line}\n  vm_hw_ver:\n    although"
      out_line="${out_line}\n  vm_vcpus:\n    found"
      echo -e "$out_line" > ${out_file}
   fi
else
   out_line="${fqdn}:"
   out_line="${out_line}\n  vm_vmx:\n"
   out_line="${out_line}\n  vm_name:\n    vmware-cmd"
   out_line="${out_line}\n  vm_ram:\n    NOT"
   out_line="${out_line}\n  vm_os:\n    found"
   out_line="${out_line}\n  vm_hw_ver:\n    in"
   out_line="${out_line}\n  vm_vcpus:\n    /usr/bin"
   echo -e "$out_line" > ${out_file}
fi

# transfer file to central
if [[ -f ${out_file} ]] ; then
   if [ "$1" == '-v' ] ; then
      rsync -avz --progress --timeout=${my_timeout} ${out_file} \
        ${my_central_host}::${my_central_module}
   else
      rsync -aqz --timeout=${my_timeout} ${out_file} \
        ${my_central_host}::${my_central_module} 1>/dev/null 2>&1
   fi
fi

# clean up temporary files
cleanup
exit 0

