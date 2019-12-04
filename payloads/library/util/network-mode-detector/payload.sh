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
#todo, add a bunch of led status

#first we chill and wait until we are connected
while mii-tool eth0 | grep -q 'eth0: no link'; do
  sleep 1
done

LED R SOLID
#this will exit 0 if a dhcp related packet is seen, and 124 if not
#todo, specifically look for dhcp discover?
if timeout 10 tcpdump -i eth0 -c 1 -q port 67 and port 68 > /dev/null 2>&1; then
  #we saw someone looking for a dhcp server, so let's grant the wish
  NETMODE DHCP_SERVER
  LED Y SOLID
else
  #we didn't see anyone looking for a dhcp server, so we try being a client
  NETMODE DHCP_CLIENT
  for i in {1..60}; do
    #could drop the space after inet to include ipv6 only networks
    if ip addr show eth0 | grep -q 'inet '; then
      LED G SOLID
      break
    else
      sleep 1
    fi
  done
  #at this point we have waited 60 seconds for dhcp and not gotten an address, that is long enough
  /etc/init.d/odhcpd stop #add this to NETMODE?
  LED W FAST
  #tcpdump here for a valid ip and netmask
  #arp ping addresses in the valid range and find on that doesn't respond
  #set ip address
  LED W SOLID
fi

#now we are connected, do evil things
