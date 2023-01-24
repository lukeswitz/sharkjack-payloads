#!/bin/bash
#
# Title:        Network Mode Detector
# Author:       Zero_Chaos
# Version:      1.0
#
# Description:	This payload tests the port to see if the other side expects a DHCP server,
# a DHCP client, or a static address
#
# LED SETUP (Magenta)... Ready, not plugged in yet
# LED Red... Port is alive
# LED Yellow... DHCP Server
# LED Green... DHCP Client
# LED White Fast... sniffing for valid ip range
# LED White ... static ip set

LED SETUP
CONNECTIVITY="false"
#todo, add a bunch of led status

#first we chill and wait until we are connected
while mii-tool eth0 | grep -q 'eth0: no link'; do
  sleep 1
done

LED R SOLID
#this will exit 0 if a dhcp related packet is seen, and 124 if not
#todo: this only looks for a dhcp request/discover and doesn't check that there was no reply...
if timeout 10 tcpdump -Z nobody -i eth0 -c 1 -q udp src port 68 > /dev/null 2>&1; then
  #we saw someone looking for a dhcp server, so let's grant the wish
  NETMODE DHCP_SERVER
  CONNECTIVITY="true"
  LED Y SOLID
else
  #we didn't see anyone looking for a dhcp server, so we try being a client
  NETMODE DHCP_CLIENT
  LED G FAST
  for i in {1..60}; do
    #could drop the space after inet to include ipv6 only networks
    if ip addr show eth0 | grep -q 'inet '; then
      LED G SOLID
      CONNECTIVITY="true"
      break
    else
      sleep 1
    fi
  done
  if [ "${CONNECTIVITY}" != "true" ]; then
    #at this point we have waited 60 seconds for dhcp and not gotten an address, that is long enough
    #/etc/init.d/odhcpd stop #add this to NETMODE?
    #this next bit is theoretical and hard
    #LED W FAST
    #tcpdump here for a valid ip and netmask
    #ipcalc -rn $(tcpdump -G 60 -W 1 -Z nobody -ni eth0 not host 0.0.0.0 and not host 255.255.255.255 and not host 172.20.1.182 and 'ip or arp' -c 200 2> /dev/null | awk '{if ($2=="IP") {print $3"\n"substr($5, 1, length($5)-1)} else {print $5"\n"substr($7, 1, length($7)-1)}}' | awk -F. '{print $1"."$2"."$3"."$4}' | sort -u | grep -vE '^224\.|^23.\.|^0\.0\.0\.0$' | sed -e 1b -e '$!d' | sed -e 's#\.1$#\.0#' | tr "\n" " ") | tail -n 1
    #arp ping addresses in the valid range and find on that doesn't respond
    #set ip address
    #LED W SOLID
    true
  fi
fi

if [ "${CONNECTIVITY}" = "true" ]; then
  #now we are connected, do evil things
  true
fi
