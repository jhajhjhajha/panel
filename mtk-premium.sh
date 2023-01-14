#!/bin/bash
rm -rf install.sh
clear
read -p "Please enter your NS: " NS
echo $NS > /root/ns.txt

apt-get update

rm -rf /usr/local/go1*
clear
apt-get update -y
apt-get install lsof git screen -y

cd /usr/local
wget https://golang.org/dl/go1.16.2.linux-amd64.tar.gz
tar xvf go1.16.2.linux-amd64.tar.gz

export GOROOT=/usr/local/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH
cd /root
git config --global http.sslverify false
git clone https://www.bamsoftware.com/git/dnstt.git
cd /root/dnstt/dnstt-server
go build
./dnstt-server -gen-key -privkey-file server.key -pubkey-file server.pub

cat <<\EOM > /root/dnstt/dnstt-server/server.key
124d51aed2abceb984978cfe73bbfaa1b74ec0be869510ac254efc6e9ec7addc
EOM

cat <<\EOM > /root/dnstt/dnstt-server/server.pub
5d30d19aa2524d7bd89afdffd9c2141575b21a728ea61c8cd7c8bf3839f97032
EOM

cd /root/dnstt/dnstt-server

screen -dmS slowdns ./dnstt-server -udp :5300 -privkey-file server.key $NS 127.0.0.1:22

iptables -A INPUT -i eth0 -p udp --dport 53 -j ACCEPT
iptables -A INPUT -i eth0 -p udp --dport 5300 -j ACCEPT
iptables -A INPUT -i ens3 -p udp --dport 53 -j ACCEPT
iptables -A INPUT -i ens3 -p udp --dport 5300 -j ACCEPT
iptables -A PREROUTING -t nat -i eth0 -p udp --dport 53 -j REDIRECT --to-port 5300
iptables -A PREROUTING -t nat -i ens3 -p udp --dport 53 -j REDIRECT --to-port 5300
