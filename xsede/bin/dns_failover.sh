#!/bin/bash


check_index_page()
{
  title=`curl -s "http://$1/inca/jsp/index.jsp" | grep '<title>Inca XSEDE Status Pages</title>'`
  exit_status=$?
  #title=`curl -s "http://$1/inca/view/status/prodkits" | grep 'inca-powered-by.jpg'`
  date=`date`
  echo $date $exit_status $title >> ${HOME}/logs/dns.log
  if [ $exit_status -ne 0 -o -z "$title" -o "$title" = "" ]; then
    return 1
  fi
}


SECONDARY_HOSTNAME="bobo.nics.utk.edu" # do not use inca.nic.utk.edu
DYNAMIC_HOSTNAME="inca.dyn.xsede.org"
STATIC_HOSTNAME="inca.xsede.org"
KEYFILE="$HOME/xsede/dns_keys/phoover.sdsc.edu.dyn.xsede.org.private"

ip_address=`dig $DYNAMIC_HOSTNAME +short`
hostname=`dig -x $ip_address +short`


if [ "$hostname" != "$SECONDARY_HOSTNAME." ]; then
  if ! check_index_page $STATIC_HOSTNAME; then
    sleep 60

    if ! check_index_page $STATIC_HOSTNAME; then
      if ! check_index_page $SECONDARY_HOSTNAME; then
        echo "Neither $STATIC_HOSTNAME nor $SECONDARY_HOSTNAME are available"

        exit 1
      fi

      new_ip_address=`dig $SECONDARY_HOSTNAME +short`

      nsupdate -v -k $KEYFILE<< EOF
server ns1.xsede.org
zone dyn.xsede.org.
update delete $DYNAMIC_HOSTNAME A
update add $DYNAMIC_HOSTNAME 900 A $new_ip_address
send
EOF

{
  echo "From: Inca <inca@$SECONDARY_HOSTNAME>"
  echo "To: Inca User <inca@sdsc.edu>"
  echo "Subject: Inca DNS change"
  echo "Content-Type: TEXT/PLAIN; charset=US-ASCII"
  echo
  echo "Changed the target of $DYNAMIC_HOSTNAME from $hostname to $SECONDARY_HOSTNAME"

} | /usr/sbin/sendmail -t
    fi
  fi
fi


exit 0

