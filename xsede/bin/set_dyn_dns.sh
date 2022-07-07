#!/bin/bash


PRIMARY_HOSTNAME="capac.sdsc.edu"
#PRIMARY_HOSTNAME="bobo.nics.utk.edu"
DYNAMIC_HOSTNAME="inca.dyn.xsede.org"
KEYFILE="$HOME/xsede_dns_keys/phoover.sdsc.edu.dyn.xsede.org.private"

if [ $# -eq 0 ]; then
  new_hostname=$PRIMARY_HOSTNAME
elif [ $# -eq 1 ]; then
  new_hostname="$1"
else
  echo "usage: `basename $0` [ hostname ]"

  exit 1
fi

ip_address=`dig $DYNAMIC_HOSTNAME +short`
hostname=`dig -x $ip_address +short`

if [ "$hostname" == "$new_hostname." ]; then
  echo "$DYNAMIC_HOSTNAME already points to $new_hostname"

  exit 0
fi

new_ip_address=`dig $new_hostname +short`

/localdisk/inca/packages/bind-9.8.1-P1/bin/nsupdate -v -k $KEYFILE<< EOF
server ns1.xsede.org
zone dyn.xsede.org.
update delete $DYNAMIC_HOSTNAME A
update add $DYNAMIC_HOSTNAME 900 A $new_ip_address
send
EOF

if [ $? -eq 0 ]; then
  echo "$DYNAMIC_HOSTNAME now points to $new_hostname"
fi
