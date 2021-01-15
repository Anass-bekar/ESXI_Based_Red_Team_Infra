#!/bin/bash
#installing neccessary packages
sudo apt install -y openvpn
sudo apt install -y network-manager-openvpn
#updating time and launching openvpn
echo "#!/bin/sh 
ntpdate ntp.ubuntu.com 
openvpn --config /tmp/redirect.ovpn --daemon  --log openvpn.log" > /tmp/ntp.sh
#updating
apt install -y ntpdate
apt install -y nginx
apt update
chmod +x /tmp/ntp.sh
/tmp/ntp.sh
#configuring nginx
mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak; cp /tmp/nginx.conf /etc/nginx/nginx.conf
echo "server {" > /etc/nginx/sites-enabled/default
for i in {1..65535};do echo "      listen $i;" >> /etc/nginx/sites-enabled/default ; done
#echo  "        listen 0-65535;" >> /etc/nginx/sites-enabled/default
echo  "          proxy_pass 10.8.0.2:\$server_port;" >> /etc/nginx/sites-enabled/default
echo  "}" >> /etc/nginx/sites-enabled/default
service nginx reload
