#!/bin/sh
#preparing environement
export PATH=$PATH:/usr/bin
#updating packages and time
apt install -y ntpdate
apt-get update
ntpdate ntp.ubuntu.com
chmod +x /tmp/openvpn-install.sh
#Installing openvpn server
AUTO_INSTALL=y /tmp/openvpn-install.sh
#modifying script to add another user(c2)
sed '1003s/.*/       CLIENT="c2"/' /tmp/openvpn-install.sh > /tmp/openvpn.sh
chmod +x /tmp/openvpn.sh
AUTO_INSTALL=y /tmp/openvpn.sh
#modifying script to add another user(redirector)
sed '1003s/.*/       CLIENT="redirect"/' /tmp/openvpn-install.sh > /tmp/openvpn-final.sh
chmod +x /tmp/openvpn-final.sh
AUTO_INSTALL=y /tmp/openvpn-final.sh
sed -i 's/remote-cert-tls server/#/' /etc/openvpn/server.conf
sed -i 's/remote-cert-tls server/#/' /root/client.ovpn
sed -i 's/remote-cert-tls server/#/' /root/c2.ovpn
sed -i 's/remote-cert-tls server/#/' /root/redirect.ovpn
echo 'mode server
remote-cert-ku e0
remote-cert-eku "TLS Web Client Authentication"' >> /etc/openvpn/server.conf
