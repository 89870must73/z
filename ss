#!/bin/bash
# Thanks for using this script, Enjoy Highspeed OpenVPN Service

#############################
#############################
# Variables (Can be changed depends on your preferred values)
# Script name
MyScriptName='SigulaDev-Premium Script'

# OpenSSH Ports
SSH_Port1='22'
SSH_Port2='53'
SSH_Port2='820'

# Your SSH Banner
SSH_Banner='https://raw.githubusercontent.com/raziman869/AutoScriptDB/master/Files/Plugins/banner'

# Dropbear Ports
Dropbear_Port1='445'
Dropbear_Port2='442'

# Stunnel Ports
Stunnel_Port1='446' # through Dropbear
Stunnel_Port2='444' # through OpenSSH

# OpenVPN Ports
OpenVPN_TCP_Port='443'
OpenVPN_UDP_Port='25222'

# Privoxy Ports
Privoxy_Port1='3356'
Privoxy_Port2='8086'

# Squid Ports
Squid_Port1='3128'
Squid_Port2='8080'
Squid_Port3='8888'

# OpenVPN Config Download Port
OvpnDownload_Port='80' # Before changing this value, please read this document. It contains all unsafe ports for Google Chrome Browser, please read from line #23 to line #89: https://chromium.googlesource.com/chromium/src.git/+/refs/heads/master/net/base/port_util.cc

# Server local time
MyVPS_Time='Asia/Manila'
#############################


#############################
#############################
## All function used for this script
#############################
## WARNING: Do not modify or edit anything
## if you did'nt know what to do.
## This part is too sensitive.
#############################
#############################

function InstUpdates(){
 export DEBIAN_FRONTEND=noninteractive
 apt-get update
 apt-get upgrade -y
 
 # Removing some firewall tools that may affect other services
 apt-get remove --purge ufw firewalld -y

 
 # Installing some important machine essentials
 apt-get install nano wget curl zip unzip tar gzip p7zip-full bc rc openssl cron net-tools dnsutils dos2unix screen bzip2 ccrypt -y
 
 # Now installing all our wanted services
 apt-get install dropbear stunnel4 privoxy ca-certificates nginx ruby apt-transport-https lsb-release squid -y

 # Installing all required packages to install Webmin
 apt-get install perl libnet-ssleay-perl openssl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions python dbus libxml-parser-perl -y
 apt-get install shared-mime-info jq fail2ban -y

 
 # Installing a text colorizer
 gem install lolcat

 # Trying to remove obsolette packages after installation
 apt-get autoremove -y
 
 # Installing OpenVPN by pulling its repository inside sources.list file 
 rm -rf /etc/apt/sources.list.d/openvpn*
 echo "deb http://build.openvpn.net/debian/openvpn/stable $(lsb_release -sc) main" > /etc/apt/sources.list.d/openvpn.list
 wget -qO - http://build.openvpn.net/debian/openvpn/stable/pubkey.gpg|apt-key add -
 apt-get update
 apt-get install openvpn -y
}

function InstWebmin(){
 # Download the webmin .deb package
 # You may change its webmin version depends on the link you've loaded in this variable(.deb file only, do not load .zip or .tar.gz file):
 WebminFile='https://github.com/raziman869/AutoScriptDB/raw/master/Files/Plugins/webmin_1.920_all.deb'
 wget -qO webmin.deb "$WebminFile"
 
 # Installing .deb package for webmin
 dpkg --install webmin.deb
 
 rm -rf webmin.deb
 
 # Configuring webmin server config to use only http instead of https
 sed -i 's|ssl=1|ssl=0|g' /etc/webmin/miniserv.conf
 
 # Then restart to take effect
 systemctl restart webmin
}

function InstSSH(){
 # Removing some duplicated sshd server configs
 rm -f /etc/ssh/sshd_config*
 
 # Creating a SSH server config using cat eof tricks
 cat <<'MySSHConfig' > /etc/ssh/sshd_config
# My OpenSSH Server config
Port myPORT1
Port myPORT2
AddressFamily inet
ListenAddress 0.0.0.0
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key
PermitRootLogin yes
MaxSessions 1024
PubkeyAuthentication yes
PasswordAuthentication yes
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding yes
PrintMotd no
ClientAliveInterval 240
ClientAliveCountMax 2
UseDNS no
Banner /etc/banner
AcceptEnv LANG LC_*
Subsystem   sftp  /usr/lib/openssh/sftp-server
MySSHConfig

 # Now we'll put our ssh ports inside of sshd_config
 sed -i "s|myPORT1|$SSH_Port1|g" /etc/ssh/sshd_config
 sed -i "s|myPORT2|$SSH_Port2|g" /etc/ssh/sshd_config

 # Download our SSH Banner
 rm -f /etc/banner
 wget -qO /etc/banner "$SSH_Banner"
 dos2unix -q /etc/banner

 # My workaround code to remove `BAD Password error` from passwd command, it will fix password-related error on their ssh accounts.
 sed -i '/password\s*requisite\s*pam_cracklib.s.*/d' /etc/pam.d/common-password
 sed -i 's/use_authtok //g' /etc/pam.d/common-password

 # Some command to identify null shells when you tunnel through SSH or using Stunnel, it will fix user/pass authentication error on HTTP Injector, KPN Tunnel, eProxy, SVI, HTTP Proxy Injector etc ssh/ssl tunneling apps.
 sed -i '/\/bin\/false/d' /etc/shells
 sed -i '/\/usr\/sbin\/nologin/d' /etc/shells
 echo '/bin/false' >> /etc/shells
 echo '/usr/sbin/nologin' >> /etc/shells
 
 # Restarting openssh service
 systemctl restart ssh
 
 # Removing some duplicate config file
 rm -rf /etc/default/dropbear*
 
 # creating dropbear config using cat eof tricks
 cat <<'MyDropbear' > /etc/default/dropbear
# My Dropbear Config
NO_START=0
DROPBEAR_PORT=PORT01
DROPBEAR_EXTRA_ARGS="-p PORT02"
DROPBEAR_BANNER="/etc/banner"
DROPBEAR_RSAKEY="/etc/dropbear/dropbear_rsa_host_key"
DROPBEAR_DSSKEY="/etc/dropbear/dropbear_dss_host_key"
DROPBEAR_ECDSAKEY="/etc/dropbear/dropbear_ecdsa_host_key"
DROPBEAR_RECEIVE_WINDOW=65536
MyDropbear

 # Now changing our desired dropbear ports
 sed -i "s|PORT01|$Dropbear_Port1|g" /etc/default/dropbear
 sed -i "s|PORT02|$Dropbear_Port2|g" /etc/default/dropbear
 
 # Restarting dropbear service
 systemctl restart dropbear
}

function InsStunnel(){
 StunnelDir=$(ls /etc/default | grep stunnel | head -n1)

 # Creating stunnel startup config using cat eof tricks
cat <<'MyStunnelD' > /etc/default/$StunnelDir
# My Stunnel Config
ENABLED=1
FILES="/etc/stunnel/*.conf"
OPTIONS=""
BANNER="/etc/banner"
PPP_RESTART=0
# RLIMITS="-n 4096 -d unlimited"
RLIMITS=""
MyStunnelD

 # Removing all stunnel folder contents
 rm -rf /etc/stunnel/*
 
 # Creating stunnel certifcate using openssl
 openssl req -new -x509 -days 9999 -nodes -subj "/C=PH/ST=NCR/L=Manila/O=$MyScriptName/OU=$MyScriptName/CN=$MyScriptName" -out /etc/stunnel/stunnel.pem -keyout /etc/stunnel/stunnel.pem &> /dev/null
##  > /dev/null 2>&1

 # Creating stunnel server config
 cat <<'MyStunnelC' > /etc/stunnel/stunnel.conf
# My Stunnel Config
pid = /var/run/stunnel.pid
cert = /etc/stunnel/stunnel.pem
client = no
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1
TIMEOUTclose = 0

[dropbear]
accept = Stunnel_Port1
connect = 127.0.0.1:dropbear_port_c

[openssh]
accept = Stunnel_Port2
connect = 127.0.0.1:openssh_port_c
MyStunnelC

 # setting stunnel ports
 sed -i "s|Stunnel_Port1|$Stunnel_Port1|g" /etc/stunnel/stunnel.conf
 sed -i "s|dropbear_port_c|$(netstat -tlnp | grep -i dropbear | awk '{print $4}' | cut -d: -f2 | xargs | awk '{print $2}' | head -n1)|g" /etc/stunnel/stunnel.conf
 sed -i "s|Stunnel_Port2|$Stunnel_Port2|g" /etc/stunnel/stunnel.conf
 sed -i "s|openssh_port_c|$(netstat -tlnp | grep -i ssh | awk '{print $4}' | cut -d: -f2 | xargs | awk '{print $2}' | head -n1)|g" /etc/stunnel/stunnel.conf

 # Restarting stunnel service
 systemctl restart $StunnelDir

}

function InsOpenVPN(){
 # Checking if openvpn folder is accidentally deleted or purged
 if [[ ! -e /etc/openvpn ]]; then
  mkdir -p /etc/openvpn
 fi

 # Removing all existing openvpn server files
 rm -rf /etc/openvpn/*

 # Creating server.conf, ca.crt, server.crt and server.key
 cat <<'myOpenVPNconf' > /etc/openvpn/server_tcp.conf
# OpenVPN TCP
port OVPNTCP
proto tcp
dev tun
user nobody
group nogroup
persist-key
persist-tun
keepalive 10 120
topology subnet
server 10.9.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "dhcp-option DNS 1.0.0.1"
push "dhcp-option DNS 1.1.1.1"
push "redirect-gateway def1 bypass-dhcp" 
crl-verify crl.pem
ca ca.crt
cert server_ADBtkp0yL46HLXPb.crt
key server_ADBtkp0yL46HLXPb.key
tls-auth tls-auth.key 0
dh dh.pem
auth SHA256
cipher AES-128-CBC
tls-server
tls-version-min 1.2
tls-cipher TLS-DHE-RSA-WITH-AES-128-GCM-SHA256
status openvpn.log
verb 3
plugin /etc/openvpn/openvpn-auth-pam.so /etc/pam.d/login
username-as-common-name
myOpenVPNconf

cat <<'myOpenVPNconf2' > /etc/openvpn/server_udp.conf
# OpenVPN UDP
port OVPNUDP
proto udp
dev tun
user nobody
group nogroup
persist-key
persist-tun
keepalive 10 120
topology subnet
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "dhcp-option DNS 1.0.0.1"
push "dhcp-option DNS 1.1.1.1"
push "redirect-gateway def1 bypass-dhcp" 
crl-verify crl.pem
ca ca.crt
cert server_ADBtkp0yL46HLXPb.crt
key server_ADBtkp0yL46HLXPb.key
tls-auth tls-auth.key 0
dh dh.pem
auth SHA256
cipher AES-128-CBC
tls-server
tls-version-min 1.2
tls-cipher TLS-DHE-RSA-WITH-AES-128-GCM-SHA256
status openvpn.log
verb 3
plugin /etc/openvpn/openvpn-auth-pam.so /etc/pam.d/login
username-as-common-name
myOpenVPNconf2

 cat <<'EOF7'> /etc/openvpn/ca.crt
-----BEGIN CERTIFICATE-----
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
-----END CERTIFICATE-----
EOF7
 cat <<'EOF9'> /etc/openvpn/client.crt
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 2 (0x2)
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: C=KG, ST=NA, L=BISHKEK, O=OpenVPN-TEST/emailAddress=me@myhost.mydomain
        Validity
            Not Before: Oct 22 21:59:53 2014 GMT
            Not After : Oct 19 21:59:53 2024 GMT
        Subject: C=KG, ST=NA, O=OpenVPN-TEST, CN=Test-Client/emailAddress=me@myhost.mydomain
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
                    00:ec:65:8f:e9:12:c2:1a:5b:e6:56:2a:08:a9:82:
                    3a:2d:44:78:a3:00:3b:b0:9f:e7:27:10:40:93:ef:
                    f1:cc:3e:a0:aa:04:a2:80:1b:13:a9:e6:fe:81:d6:
                    70:90:a8:d8:d4:de:30:d8:35:00:d2:be:62:f0:48:
                    da:fc:15:8d:c4:c6:6d:0b:99:f1:2b:83:00:0a:d3:
                    2a:23:0b:e5:cd:f9:35:df:43:61:15:72:ad:95:98:
                    f6:73:21:41:5e:a0:dd:47:27:a0:d5:9a:d4:41:a8:
                    1c:1d:57:20:71:17:8f:f7:28:9e:3e:07:ce:ec:d5:
                    0e:42:4f:1e:74:47:8e:47:9d:d2:14:28:27:2c:14:
                    10:f5:d1:96:b5:93:74:84:ef:f9:04:de:8d:4a:6f:
                    df:77:ab:ea:d1:58:d3:44:fe:5a:04:01:ff:06:7a:
                    97:f7:fd:e3:57:48:e1:f0:df:40:13:9f:66:23:5a:
                    e3:55:54:3d:54:39:ee:00:f9:12:f1:d2:df:74:2e:
                    ba:d7:f0:8d:c6:dd:18:58:1c:93:22:0b:75:fa:a8:
                    d6:e0:b5:2f:2d:b9:d4:fe:b9:4f:86:e2:75:48:16:
                    60:fb:3f:c9:b4:30:42:29:fb:3b:b3:2b:b9:59:81:
                    6a:46:f3:45:83:bf:fd:d5:1a:ff:37:0c:6f:5b:fd:
                    61:f1
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Basic Constraints: 
                CA:FALSE
            X509v3 Subject Key Identifier: 
                D2:B4:36:0F:B1:FC:DD:A5:EA:2A:F7:C7:23:89:FA:E3:FA:7A:44:1D
            X509v3 Authority Key Identifier: 
                keyid:2B:40:E5:C9:7D:F5:F4:96:38:E9:2F:E3:2F:D9:40:64:C9:8E:05:9B
                DirName:/C=KG/ST=NA/L=BISHKEK/O=OpenVPN-TEST/emailAddress=me@myhost.mydomain
                serial:A1:4E:DE:FA:90:F2:AE:81

    Signature Algorithm: sha256WithRSAEncryption
         7f:e0:fe:84:a7:ec:df:62:a5:cd:3c:c1:e6:42:b1:31:12:f0:
         b9:da:a7:9e:3f:bd:96:52:b6:fc:55:74:64:3e:e4:ff:7e:aa:
         f7:3e:06:18:5f:73:85:f8:c8:e0:67:1b:4d:97:ca:05:d0:37:
         07:33:64:9b:e6:78:77:14:9a:55:bb:2a:ac:c3:7f:c9:15:08:
         83:5c:c8:c2:61:d3:71:4c:05:0b:2b:cb:a3:87:6d:a0:32:ed:
         b0:b3:27:97:4a:55:8d:01:2a:30:56:68:ab:f2:da:5c:10:73:
         c9:aa:0a:9c:4b:4c:a0:5b:51:6e:0a:7e:6c:53:80:b0:00:e1:
         1e:9a:4c:0a:37:9e:20:89:bc:c5:e5:79:58:b7:45:ff:d3:c4:
         a1:fd:d9:78:3d:45:16:74:df:82:44:1d:1d:81:50:5a:b9:32:
         4c:e2:4f:3f:0e:3a:65:5a:64:83:3b:29:31:c4:99:88:bc:c5:
         84:39:f2:19:12:e1:66:d0:ea:fb:75:b1:d2:27:be:91:59:a3:
         2b:09:d5:5c:bf:46:8e:d6:67:d6:0b:ec:da:ab:f0:80:19:87:
         64:07:a9:77:b1:5e:0c:e2:c5:1d:6a:ac:5d:23:f3:30:75:36:
         4e:ca:c3:4e:b0:4d:8c:2c:ce:52:61:63:de:d5:f5:ef:ef:0a:
         6b:23:25:26:3c:3a:f2:c3:c2:16:19:3f:a9:32:ba:68:f9:c9:
         12:3c:3e:c6:1f:ff:9b:4e:f4:90:b0:63:f5:d1:33:00:30:5a:
         e8:24:fa:35:44:9b:6a:80:f3:a6:cc:7b:3c:73:5f:50:c4:30:
         71:d8:74:90:27:0a:01:4e:a5:5e:b1:f8:da:c2:61:81:11:ae:
         29:a3:8f:fa:7e:4c:4e:62:b1:00:de:92:e3:8f:6a:2e:da:d9:
         38:5d:6b:7c:0d:e4:01:aa:c8:c6:6d:8b:cd:c0:c8:6e:e4:57:
         21:8a:f6:46:30:d9:ad:51:a1:87:96:a6:53:c9:1e:c6:bb:c3:
         eb:55:fe:8c:d6:5c:d5:c6:f3:ca:b0:60:d2:d4:2a:1f:88:94:
         d3:4c:1a:da:0c:94:fe:c1:5d:0d:2a:db:99:29:5d:f6:dd:16:
         c4:c8:4d:74:9e:80:d9:d0:aa:ed:7b:e3:30:e4:47:d8:f5:15:
         c1:71:b8:c6:fd:ee:fc:9e:b2:5f:b5:b7:92:ed:ff:ca:37:f6:
         c7:82:b4:54:13:9b:83:cd:87:8b:7e:64:f6:2e:54:3a:22:b1:
         c5:c1:f4:a5:25:53:9a:4d:a8:0f:e7:35:4b:89:df:19:83:66:
         64:d9:db:d1:61:2b:24:1b:1d:44:44:fb:49:30:87:b7:49:23:
         08:02:8a:e0:25:f3:f4:43
-----BEGIN CERTIFICATE-----
MIIFFDCCAvygAwIBAgIBAjANBgkqhkiG9w0BAQsFADBmMQswCQYDVQQGEwJLRzEL
MAkGA1UECBMCTkExEDAOBgNVBAcTB0JJU0hLRUsxFTATBgNVBAoTDE9wZW5WUE4t
VEVTVDEhMB8GCSqGSIb3DQEJARYSbWVAbXlob3N0Lm15ZG9tYWluMB4XDTE0MTAy
MjIxNTk1M1oXDTI0MTAxOTIxNTk1M1owajELMAkGA1UEBhMCS0cxCzAJBgNVBAgT
Ak5BMRUwEwYDVQQKEwxPcGVuVlBOLVRFU1QxFDASBgNVBAMTC1Rlc3QtQ2xpZW50
MSEwHwYJKoZIhvcNAQkBFhJtZUBteWhvc3QubXlkb21haW4wggEiMA0GCSqGSIb3
DQEBAQUAA4IBDwAwggEKAoIBAQDsZY/pEsIaW+ZWKgipgjotRHijADuwn+cnEECT
7/HMPqCqBKKAGxOp5v6B1nCQqNjU3jDYNQDSvmLwSNr8FY3Exm0LmfErgwAK0yoj
C+XN+TXfQ2EVcq2VmPZzIUFeoN1HJ6DVmtRBqBwdVyBxF4/3KJ4+B87s1Q5CTx50
R45HndIUKCcsFBD10Za1k3SE7/kE3o1Kb993q+rRWNNE/loEAf8Gepf3/eNXSOHw
30ATn2YjWuNVVD1UOe4A+RLx0t90LrrX8I3G3RhYHJMiC3X6qNbgtS8tudT+uU+G
4nVIFmD7P8m0MEIp+zuzK7lZgWpG80WDv/3VGv83DG9b/WHxAgMBAAGjgcgwgcUw
CQYDVR0TBAIwADAdBgNVHQ4EFgQU0rQ2D7H83aXqKvfHI4n64/p6RB0wgZgGA1Ud
IwSBkDCBjYAUK0DlyX319JY46S/jL9lAZMmOBZuhaqRoMGYxCzAJBgNVBAYTAktH
MQswCQYDVQQIEwJOQTEQMA4GA1UEBxMHQklTSEtFSzEVMBMGA1UEChMMT3BlblZQ
Ti1URVNUMSEwHwYJKoZIhvcNAQkBFhJtZUBteWhvc3QubXlkb21haW6CCQChTt76
kPKugTANBgkqhkiG9w0BAQsFAAOCAgEAf+D+hKfs32KlzTzB5kKxMRLwudqnnj+9
llK2/FV0ZD7k/36q9z4GGF9zhfjI4GcbTZfKBdA3BzNkm+Z4dxSaVbsqrMN/yRUI
g1zIwmHTcUwFCyvLo4dtoDLtsLMnl0pVjQEqMFZoq/LaXBBzyaoKnEtMoFtRbgp+
bFOAsADhHppMCjeeIIm8xeV5WLdF/9PEof3ZeD1FFnTfgkQdHYFQWrkyTOJPPw46
ZVpkgzspMcSZiLzFhDnyGRLhZtDq+3Wx0ie+kVmjKwnVXL9GjtZn1gvs2qvwgBmH
ZAepd7FeDOLFHWqsXSPzMHU2TsrDTrBNjCzOUmFj3tX17+8KayMlJjw68sPCFhk/
qTK6aPnJEjw+xh//m070kLBj9dEzADBa6CT6NUSbaoDzpsx7PHNfUMQwcdh0kCcK
AU6lXrH42sJhgRGuKaOP+n5MTmKxAN6S449qLtrZOF1rfA3kAarIxm2LzcDIbuRX
IYr2RjDZrVGhh5amU8kexrvD61X+jNZc1cbzyrBg0tQqH4iU00wa2gyU/sFdDSrb
mSld9t0WxMhNdJ6A2dCq7XvjMORH2PUVwXG4xv3u/J6yX7W3ku3/yjf2x4K0VBOb
g82Hi35k9i5UOiKxxcH0pSVTmk2oD+c1S4nfGYNmZNnb0WErJBsdRET7STCHt0kj
CAKK4CXz9EM=
-----END CERTIFICATE-----
EOF9
 cat <<'EOF10'> /etc/openvpn/client.key
-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDsZY/pEsIaW+ZW
KgipgjotRHijADuwn+cnEECT7/HMPqCqBKKAGxOp5v6B1nCQqNjU3jDYNQDSvmLw
SNr8FY3Exm0LmfErgwAK0yojC+XN+TXfQ2EVcq2VmPZzIUFeoN1HJ6DVmtRBqBwd
VyBxF4/3KJ4+B87s1Q5CTx50R45HndIUKCcsFBD10Za1k3SE7/kE3o1Kb993q+rR
WNNE/loEAf8Gepf3/eNXSOHw30ATn2YjWuNVVD1UOe4A+RLx0t90LrrX8I3G3RhY
HJMiC3X6qNbgtS8tudT+uU+G4nVIFmD7P8m0MEIp+zuzK7lZgWpG80WDv/3VGv83
DG9b/WHxAgMBAAECggEBAIOdaCpUD02trOh8LqZxowJhBOl7z7/ex0uweMPk67LT
i5AdVHwOlzwZJ8oSIknoOBEMRBWcLQEojt1JMuL2/R95emzjIKshHHzqZKNulFvB
TIUpdnwChTKtH0mqUkLlPU3Ienty4IpNlpmfUKimfbkWHERdBJBHbtDsTABhdo3X
9pCF/yRKqJS2Fy/Mkl3gv1y/NB1OL4Jhl7vQbf+kmgfQN2qdOVe2BOKQ8NlPUDmE
/1XNIDaE3s6uvUaoFfwowzsCCwN2/8QrRMMKkjvV+lEVtNmQdYxj5Xj5IwS0vkK0
6icsngW87cpZxxc1zsRWcSTloy5ohub4FgKhlolmigECgYEA+cBlxzLvaMzMlBQY
kCac9KQMvVL+DIFHlZA5i5L/9pRVp4JJwj3GUoehFJoFhsxnKr8HZyLwBKlCmUVm
VxnshRWiAU18emUmeAtSGawlAS3QXhikVZDdd/L20YusLT+DXV81wlKR97/r9+17
klQOLkSdPm9wcMDOWMNHX8bUg8kCgYEA8k+hQv6+TR/+Beao2IIctFtw/EauaJiJ
wW5ql1cpCLPMAOQUvjs0Km3zqctfBF8mUjdkcyJ4uhL9FZtfywY22EtRIXOJ/8VR
we65mVo6RLR8YVM54sihanuFOnlyF9LIBWB+9pUfh1/Y7DSebh7W73uxhAxQhi3Y
QwfIQIFd8OkCgYBalH4VXhLYhpaYCiXSej6ot6rrK2N6c5Tb2MAWMA1nh+r84tMP
gMoh+pDgYPAqMI4mQbxUmqZEeoLuBe6VHpDav7rPECRaW781AJ4ZM4cEQ3Jz/inz
4qOAMn10CF081/Ez9ykPPlU0bsYNWHNd4eB2xWnmUBKOwk7UgJatVPaUiQKBgQCI
f18CVGpzG9CHFnaK8FCnMNOm6VIaTcNcGY0mD81nv5Dt943P054BQMsAHTY7SjZW
HioRyZtkhonXAB2oSqnekh7zzxgv4sG5k3ct8evdBCcE1FNJc2eqikZ0uDETRoOy
s7cRxNNr+QxDkyikM+80HOPU1PMPgwfOSrX90GJQ8QKBgEBKohGMV/sNa4t14Iau
qO8aagoqh/68K9GFXljsl3/iCSa964HIEREtW09Qz1w3dotEgp2w8bsDa+OwWrLy
0SY7T5jRViM3cDWRlUBLrGGiL0FiwsfqiRiji60y19erJgrgyGVIb1kIgIBRkgFM
2MMweASzTmZcri4PA/5C0HYb
-----END PRIVATE KEY-----
EOF10
 cat <<'EOF18'> /etc/openvpn/tls-auth.key
#
# 2048 bit OpenVPN static key
#
-----BEGIN OpenVPN Static key V1-----
40240d75e68c0c904997178f1e02bb26
e0e749654be32a0b7adc37cfc70be68c
1483fa0c9427eec41fd6492b68fa67cd
7fbccce05ed92e02bdf5e94aa028afa6
e1aec19a2f22082409695c958100fd94
d667cb2f9b4ef1294e1fcf8307ad52e0
a2f0ac7d1f64d32bad1b00b502272d87
4d05c2851a09578585d3fcc2626275c2
4b3d98220506b9b1c4b726e2fe8ff0fa
1a0b194e55ce517740c6f9e399808ca2
2017adbb8c0695eaa1686cc64cd5c3cd
3210ca0f3283233be7dc18a5e535adc9
c87fc49ee32b97b6c925014b464ae52d
e6d7b99a22b84f1620d7c94af927c8bb
0ed52d61c9ca821be4e9deb94bc00cb8
29b8d1b0a13e173b68e3b835c46a4a38
-----END OpenVPN Static key V1-----
EOF18
 cat <<'EOF107'> /etc/openvpn/server_ADBtkp0yL46HLXPb.crt
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            51:3f:14:0e:2d:0c:38:91:eb:c3:cd:61:41:9d:27:cb
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN=cn_TZGDkWmsY7phEdpj
        Validity
            Not Before: Jan 25 17:56:35 2018 GMT
            Not After : Jan 23 17:56:35 2028 GMT
        Subject: CN=server_ADBtkp0yL46HLXPb
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (3072 bit)
                Modulus:
                    00:ce:57:b1:a9:2f:ae:7a:cd:80:47:5a:91:43:9c:
                    51:30:48:15:99:d7:ce:c5:cd:7f:5e:bd:29:73:e6:
                    48:3c:6c:b2:79:e7:20:c3:72:34:a9:e4:fc:16:95:
                    ca:1c:33:0e:76:7d:33:1f:f9:01:18:b9:29:f7:a7:
                    0a:d4:9c:05:04:a4:d4:8a:4b:e7:eb:db:c7:d3:b8:
                    ac:80:80:d7:d3:49:c9:e6:08:4a:72:da:99:7c:5d:
                    87:fd:3e:7c:0e:10:33:db:3e:8d:68:5b:82:7a:73:
                    17:e4:78:e8:f3:fb:97:ce:0f:24:c5:c1:62:cb:58:
                    89:ac:8c:16:ac:f3:fc:32:05:a0:69:6f:c3:04:73:
                    69:4b:c5:8c:c6:bc:64:47:90:30:97:20:60:86:62:
                    bf:09:54:e6:62:00:4a:8a:8e:cc:c5:04:65:96:f5:
                    fb:08:ae:f3:5b:54:a9:42:15:3a:63:c7:06:9f:70:
                    5c:0d:3b:f2:37:8a:41:0b:87:dc:40:7e:c9:a2:c8:
                    ba:1b:a4:e3:84:19:64:90:96:8a:11:1b:10:6a:61:
                    ef:ca:a4:a4:82:69:db:cd:d1:62:b4:cd:4f:2d:a7:
                    ac:4e:43:d9:9e:f7:61:ea:75:1c:2d:cf:bc:ad:b9:
                    bd:8c:19:9a:69:33:35:a5:20:e7:d7:4c:9b:24:f8:
                    ca:9d:11:8b:15:17:2b:92:e2:5a:08:04:43:81:cf:
                    7c:38:24:15:c1:79:cb:cd:88:92:be:d5:3f:4a:2c:
                    77:81:b5:6f:81:70:8f:37:dc:63:0e:7e:e9:bb:05:
                    8d:f5:83:05:e0:23:57:98:9f:a5:a9:32:3d:e0:54:
                    da:97:7b:6e:af:44:0f:ef:77:6d:81:21:98:59:a1:
                    2f:85:79:55:9a:87:6f:28:86:4d:b3:96:b4:fd:10:
                    07:bf:a4:34:7d:f6:59:34:0c:da:68:e9:b7:c9:aa:
                    c0:8d:92:05:70:4a:60:8b:18:19:ca:15:2a:7c:b4:
                    18:40:8f:35:f5:20:09:21:c3:03
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Basic Constraints: 
                CA:FALSE
            X509v3 Subject Key Identifier: 
                16:A6:D1:D3:89:39:AF:C6:16:99:7E:6A:60:AF:44:E9:E9:57:F6:2D
            X509v3 Authority Key Identifier: 
                keyid:48:81:6F:AF:5C:78:84:8A:0E:A1:CE:8E:F2:21:A6:98:5E:7B:06:B3
                DirName:/CN=cn_TZGDkWmsY7phEdpj
                serial:B7:73:D2:2D:71:D0:A1:32

            X509v3 Extended Key Usage: 
                TLS Web Server Authentication
            X509v3 Key Usage: 
                Digital Signature, Key Encipherment
            X509v3 Subject Alternative Name: 
                DNS:server_ADBtkp0yL46HLXPb
    Signature Algorithm: sha256WithRSAEncryption
         a5:2c:94:99:ca:29:19:0e:b2:1a:3f:12:db:ba:a3:00:c5:fb:
         0e:cf:e7:c4:02:17:de:90:86:2e:86:97:54:94:1c:06:d6:62:
         b0:8b:90:96:bf:80:2d:ae:7f:7c:94:f6:26:69:1b:1c:e9:32:
         58:c3:da:52:c2:e5:d5:c6:09:57:2a:9b:23:68:80:7e:d6:08:
         7f:34:10:0c:cf:c2:3e:5b:53:73:f0:fa:26:78:2a:68:4d:29:
         da:05:c6:80:43:e3:56:0e:38:38:16:26:dc:c9:af:13:33:51:
         2f:01:58:8c:ca:52:be:78:17:6d:4a:f3:f2:24:a6:44:bc:ab:
         8a:69:e6:63:e1:fe:8c:70:b6:3a:be:61:df:77:e9:b4:b5:a5:
         aa:d7:57:05:78:ae:4e:63:6e:fd:44:8c:a2:c8:5e:90:22:e7:
         95:49:f7:3d:e2:2f:1a:b3:d8:7a:49:b8:30:6b:be:2b:7e:34:
         16:6b:25:a8:8c:34:ff:aa:53:3f:65:5d:de:0b:cd:47:b7:57:
         f7:e5:84:de:33:41:13:33:4b:11:9b:01:20:37:5e:69:61:df:
         26:80:25:a2:c2:21:54:c2:84:d9:80:2c:27:68:83:bf:06:ba:
         66:13:7e:a9:4e:0b:95:a9:7a:96:a2:f1:0d:8e:ed:df:2c:e6:
         32:2c:3f:a4:7b:d1:8d:7c:97:52:8c:ab:00:6c:63:87:dc:72:
         0c:0a:ef:f5:84:6f:45:61:58:3b:53:16:8a:e5:fd:62:37:e5:
         1d:0d:00:b7:0a:47:2f:e8:f6:e0:df:74:cc:97:4e:1a:02:1c:
         b5:6d:46:49:c8:f9:da:c4:15:3b:b2:4d:d8:12:c4:48:46:aa:
         1f:3b:1d:7b:61:22:08:d5:46:69:de:4f:9e:ce:3f:30:33:2a:
         20:80:f2:c5:8f:ba:62:01:9d:ad:a7:39:85:a4:dd:97:b3:f1:
         b5:a0:c0:42:e2:2c:f9:b7:76:14:12:5b:cc:aa:8b:f1:ee:d6:
         88:c8:f4:0f:f4:4b
-----BEGIN CERTIFICATE-----
MIIEjjCCAvagAwIBAgIQUT8UDi0MOJHrw81hQZ0nyzANBgkqhkiG9w0BAQsFADAe
MRwwGgYDVQQDDBNjbl9UWkdEa1dtc1k3cGhFZHBqMB4XDTE4MDEyNTE3NTYzNVoX
DTI4MDEyMzE3NTYzNVowIjEgMB4GA1UEAwwXc2VydmVyX0FEQnRrcDB5TDQ2SExY
UGIwggGiMA0GCSqGSIb3DQEBAQUAA4IBjwAwggGKAoIBgQDOV7GpL656zYBHWpFD
nFEwSBWZ187FzX9evSlz5kg8bLJ55yDDcjSp5PwWlcocMw52fTMf+QEYuSn3pwrU
nAUEpNSKS+fr28fTuKyAgNfTScnmCEpy2pl8XYf9PnwOEDPbPo1oW4J6cxfkeOjz
+5fODyTFwWLLWImsjBas8/wyBaBpb8MEc2lLxYzGvGRHkDCXIGCGYr8JVOZiAEqK
jszFBGWW9fsIrvNbVKlCFTpjxwafcFwNO/I3ikELh9xAfsmiyLobpOOEGWSQlooR
GxBqYe/KpKSCadvN0WK0zU8tp6xOQ9me92HqdRwtz7ytub2MGZppMzWlIOfXTJsk
+MqdEYsVFyuS4loIBEOBz3w4JBXBecvNiJK+1T9KLHeBtW+BcI833GMOfum7BY31
gwXgI1eYn6WpMj3gVNqXe26vRA/vd22BIZhZoS+FeVWah28ohk2zlrT9EAe/pDR9
9lk0DNpo6bfJqsCNkgVwSmCLGBnKFSp8tBhAjzX1IAkhwwMCAwEAAaOBwzCBwDAJ
BgNVHRMEAjAAMB0GA1UdDgQWBBQWptHTiTmvxhaZfmpgr0Tp6Vf2LTBOBgNVHSME
RzBFgBRIgW+vXHiEig6hzo7yIaaYXnsGs6EipCAwHjEcMBoGA1UEAwwTY25fVFpH
RGtXbXNZN3BoRWRwaoIJALdz0i1x0KEyMBMGA1UdJQQMMAoGCCsGAQUFBwMBMAsG
A1UdDwQEAwIFoDAiBgNVHREEGzAZghdzZXJ2ZXJfQURCdGtwMHlMNDZITFhQYjAN
BgkqhkiG9w0BAQsFAAOCAYEApSyUmcopGQ6yGj8S27qjAMX7Ds/nxAIX3pCGLoaX
VJQcBtZisIuQlr+ALa5/fJT2JmkbHOkyWMPaUsLl1cYJVyqbI2iAftYIfzQQDM/C
PltTc/D6JngqaE0p2gXGgEPjVg44OBYm3MmvEzNRLwFYjMpSvngXbUrz8iSmRLyr
imnmY+H+jHC2Or5h33fptLWlqtdXBXiuTmNu/USMoshekCLnlUn3PeIvGrPYekm4
MGu+K340FmslqIw0/6pTP2Vd3gvNR7dX9+WE3jNBEzNLEZsBIDdeaWHfJoAlosIh
VMKE2YAsJ2iDvwa6ZhN+qU4Llal6lqLxDY7t3yzmMiw/pHvRjXyXUoyrAGxjh9xy
DArv9YRvRWFYO1MWiuX9YjflHQ0AtwpHL+j24N90zJdOGgIctW1GScj52sQVO7JN
2BLESEaqHzsde2EiCNVGad5Pns4/MDMqIIDyxY+6YgGdrac5haTdl7PxtaDAQuIs
+bd2FBJbzKqL8e7WiMj0D/RL
-----END CERTIFICATE-----
EOF107
 cat <<'EOF113'> /etc/openvpn/server_ADBtkp0yL46HLXPb.key
-----BEGIN PRIVATE KEY-----
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
dr3Szfw/1BrXI2OgvFxke2i6hA==
-----END PRIVATE KEY-----
EOF113
 cat <<'EOF13'> /etc/openvpn/dh.pem
-----BEGIN DH PARAMETERS-----
MIIBiAKCAYEAwnm17lIOZot3TN0jJ56XFidX6d3EWkdHf45MJlYQIGb02h5Z79TG
aSW9G07KTM2Cey8hYjBCNOMoPo8Ste05reKmAfSxWO5WYLgWspPG60hTr3V8kE2n
5yjKchSDpIYQXOztHrKKiCYnea2AVoGKh9/eNoek2miAIpktS6f592JGg2YXgO9t
PV/3ljaL4V5vk9UHr4Udvsa8fqLSRAJow+U7/DLao5ZNijG+Z5IsKNqWPV1ELpyg
XRmiOurBzGsataIj+KGuQRsxSgTSu7sWQ78ecskx0t2rFE6/ZErrsB0eEE+HNtR3
4VQ1LQ2z2a375sNVHed3oHhHcbtyGVpEghlBINaNihg7lkRlTVRsI1Cb2uoa3CCZ
90jxre5d8fCTyla+lYjHA5KUuMLqdzrdmvqn4WWtHSKlVT03URoj97lSIlwzTNxU
KPQaxjFC7VakqPmPvl77+aTf0AYFlZFhSMFBYOgK7ctfAXkhPkLY59fmICzpEJto
YR3+ry8FO9ozAgEC
-----END DH PARAMETERS-----
EOF13
 cat <<'EOF103'> /etc/openvpn/crl.pem
-----BEGIN X509 CRL-----
MIIBsDCBmQIBATANBgkqhkiG9w0BAQsFADATMREwDwYDVQQDDAhSYWR6IFZQThcN
MTkwODA4MDM1NDI1WhcNMjAwMjA0MDM1NDI1WqBSMFAwTgYDVR0jBEcwRYAUpZcJ
dK9kVRcXepwjPkZbQahd+YKhF6QVMBMxETAPBgNVBAMMCFJhZHogVlBOghQHkI1U
FC2+EYQoi9jXsAtjsYTrHzANBgkqhkiG9w0BAQsFAAOCAQEAauCvXzfFxGk1x1sz
UKTjrG4A1QG3nD/5V9Zd2N0uClXGwHUi7wn4BDT7ckGtdNyl37SQ+WK+C73lUbz8
u6Pj40k8/YOMD3IasInHYG74ZulVCg0KbXxCgi6TXl5/c1XT+sSSuO46XNpRWkV3
lRhj31D3Uh5jbrCJ6bCyWU+nv/DA1QsFXXo2BfcMU7a6XoJ6n/zrogwzrXvPpYkh
CuZEyGkEZO8Wd0KYGm7pT2nsFzmUqES2W5LLZkVtgYziKG7/5Lcw4u1OOd/R3Jqy
NDJboL0lnAK6QLMspx3OThLdusI2Kn/cEQiSdhC9RExBibS83N2Fti+3lom0rjdX
j+cNXw==
-----END X509 CRL-----
EOF103

 # Getting all dns inside resolv.conf then use as Default DNS for our openvpn server
 grep -v '#' /etc/resolv.conf | grep 'nameserver' | grep -E -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | while read -r line; do
	echo "push \"dhcp-option DNS $line\"" >> /etc/openvpn/server_tcp.conf
done

 # Creating a New update message in server.conf
 cat <<'NUovpn' > /etc/openvpn/server.conf
 # New Update are now released, OpenVPN Server
 # are now running both TCP and UDP Protocol. (Both are only running on IPv4)
 # But our native server.conf are now removed and divided
 # Into two different configs base on their Protocols:
 #  * OpenVPN TCP (located at /etc/openvpn/server_tcp.conf
 #  * OpenVPN UDP (located at /etc/openvpn/server_udp.conf
 # 
 # Also other logging files like
 # status logs and server logs
 # are moved into new different file names:
 #  * OpenVPN TCP Server logs (/etc/openvpn/tcp.log)
 #  * OpenVPN UDP Server logs (/etc/openvpn/udp.log)
 #  * OpenVPN TCP Status logs (/etc/openvpn/tcp_stats.log)
 #  * OpenVPN UDP Status logs (/etc/openvpn/udp_stats.log)
 #
 # Server ports are configured base on env vars
 # executed/raised from this script (OpenVPN_TCP_Port/OpenVPN_UDP_Port)
 #
 # Enjoy the new update
 # Script Updated by SigulaDev
NUovpn

 # setting openvpn server port
 sed -i "s|OVPNTCP|$OpenVPN_TCP_Port|g" /etc/openvpn/server_tcp.conf
 sed -i "s|OVPNUDP|$OpenVPN_UDP_Port|g" /etc/openvpn/server_udp.conf
 
 # Getting some OpenVPN plugins for unix authentication
 wget -qO /etc/openvpn/b.zip 'https://raw.githubusercontent.com/GakodArmy/teli/main/openvpn_plugin64'
 unzip -qq /etc/openvpn/b.zip -d /etc/openvpn
 rm -f /etc/openvpn/b.zip
 
 # Some workaround for OpenVZ machines for "Startup error" openvpn service
 if [[ "$(hostnamectl | grep -i Virtualization | awk '{print $2}' | head -n1)" == 'openvz' ]]; then
 sed -i 's|LimitNPROC|#LimitNPROC|g' /lib/systemd/system/openvpn*
 systemctl daemon-reload
fi

 echo ipv4 >> /etc/modules
 echo ipv6 >> /etc/modules
 sysctl -w net.ipv4.ip_forward=1
 sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
 sed -i 's/#net.ipv6.conf.all.forwarding=1/net.ipv6.conf.all.forwarding=1/g' /etc/sysctl.conf
 sysctl -p
 clear

sysctl -w net.ipv4.ip_forward=1
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
iptables -t nat -I POSTROUTING -s 192.168.100.0/24 -o eth0 -j MASQUERADE
iptables -t nat -I POSTROUTING -o eth0 -j MASQUERADE
iptables-save > /etc/iptables.up.rules
wget -O /etc/network/if-up.d/iptables "https://raw.githubusercontent.com/ara-rangers/vps/master/iptables"
chmod +x /etc/network/if-up.d/iptables
sed -i 's|LimitNPROC|#LimitNPROC|g' /lib/systemd/system/openvpn@.service
systemctl daemon-reload
/etc/init.d/openvpn restart
wget -qO /etc/openvpn/openvpn.bash "https://raw.githubusercontent.com/sumailranger93/sumail/main/openvpn.bash"
chmod +x /etc/openvpn/openvpn.bash
bash /etc/openvpn/openvpn.bash
 
 # Starting OpenVPN server
 systemctl start openvpn@server_tcp
 systemctl enable openvpn@server_tcp
 systemctl start openvpn@server_udp
 systemctl enable openvpn@server_udp

}
function InsProxy(){

 # Removing Duplicate privoxy config
 rm -rf /etc/privoxy/config*
 
 # Creating Privoxy server config using cat eof tricks
 cat <<'privoxy' > /etc/privoxy/config
# My Privoxy Server Config
user-manual /usr/share/doc/privoxy/user-manual
confdir /etc/privoxy
logdir /var/log/privoxy
filterfile default.filter
logfile logfile
listen-address 0.0.0.0:Privoxy_Port1
listen-address 0.0.0.0:Privoxy_Port2
toggle 1
enable-remote-toggle 0
enable-remote-http-toggle 0
enable-edit-actions 0
enforce-blocks 0
buffer-limit 4096
enable-proxy-authentication-forwarding 1
forwarded-connect-retries 1
accept-intercepted-requests 1
allow-cgi-request-crunching 1
split-large-forms 0
keep-alive-timeout 5
tolerate-pipelining 1
socket-timeout 300
permit-access 0.0.0.0/0 IP-ADDRESS
privoxy

 # Setting machine's IP Address inside of our privoxy config(security that only allows this machine to use this proxy server)
 sed -i "s|IP-ADDRESS|$IPADDR|g" /etc/privoxy/config
 
 # Setting privoxy ports
 sed -i "s|Privoxy_Port1|$Privoxy_Port1|g" /etc/privoxy/config
 sed -i "s|Privoxy_Port2|$Privoxy_Port2|g" /etc/privoxy/config

 # Removing Duplicate Squid config
 rm -rf /etc/squid/squid.con*
 
 # Creating Squid server config using cat eof tricks
 cat <<'mySquid' > /etc/squid/squid.conf
# My Squid Proxy Server Config
acl VPN dst IP-ADDRESS/32
http_access allow VPN
http_access deny all 
http_port 0.0.0.0:Squid_Port1
http_port 0.0.0.0:Squid_Port2
http_port 0.0.0.0:Squid_Port3
### Allow Headers
acl all src 0.0.0.0/0
http_access allow all
forwarded_for off
via off
request_header_access Host allow all
request_header_access Content-Length allow all
request_header_access Content-Type allow all
request_header_access All deny all
coredump_dir /var/spool/squid
dns_nameservers 1.1.1.1 1.0.0.1
refresh_pattern ^ftp: 1440 20% 10080
refresh_pattern ^gopher: 1440 0% 1440
refresh_pattern -i (/cgi-bin/|\?) 0 0% 0
refresh_pattern . 0 20% 4320
visible_hostname localhost
mySquid

 # Setting machine's IP Address inside of our Squid config(security that only allows this machine to use this proxy server)
 sed -i "s|IP-ADDRESS|$IPADDR|g" /etc/squid/squid.conf
 
 # Setting squid ports
 sed -i "s|Squid_Port1|$Squid_Port1|g" /etc/squid/squid.conf
 sed -i "s|Squid_Port2|$Squid_Port2|g" /etc/squid/squid.conf
 sed -i "s|Squid_Port3|$Squid_Port3|g" /etc/squid/squid.conf

 # Starting Proxy server
 echo -e "Restarting proxy server..."
 systemctl restart squid
}

function OvpnConfigs(){
 # Creating nginx config for our ovpn config downloads webserver
 cat <<'myNginxC' > /etc/nginx/conf.d/johnfordtv-ovpn-config.conf
# My OpenVPN Config Download Directory
server {
 listen 0.0.0.0:myNginx;
 server_name localhost;
 root /var/www/openvpn;
 index index.html;
}
myNginxC

 # Setting our nginx config port for .ovpn download site
 sed -i "s|myNginx|$OvpnDownload_Port|g" /etc/nginx/conf.d/johnfordtv-ovpn-config.conf

 # Removing Default nginx page(port 80)
 rm -rf /etc/nginx/sites-*

 # Creating our root directory for all of our .ovpn configs
 rm -rf /var/www/openvpn
 mkdir -p /var/www/openvpn

 # Creating our root directory for all of our .ovpn configs
 rm -rf /var/www/openvpn
 mkdir -p /var/www/openvpn
# Now creating all of our OpenVPN Configs 
cat <<EOF152> /var/www/openvpn/tcp.ovpn
client
dev tun
proto tcp
setenv FRIENDLY_NAME "I'M MASTA GAKOD"
remote $IPADDR $OpenVPN_TCP_Port
http-proxy $IPADDR $Squid_Port1
http-proxy-retry
dev tun
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
verify-x509-name server_ADBtkp0yL46HLXPb name
auth SHA256
auth-nocache
cipher AES-128-CBC
tls-client
tls-version-min 1.2
tls-cipher TLS-DHE-RSA-WITH-AES-128-GCM-SHA256
setenv opt block-outside-dns
verb 3
<auth-user-pass>
sam
sam
</auth-user-pass>
<ca>
$(cat /etc/openvpn/ca.crt)
</ca>
<cert>
$(cat /etc/openvpn/server_ADBtkp0yL46HLXPb.crt)
</cert>
<key>
$(cat /etc/openvpn/server_ADBtkp0yL46HLXPb.key)
</key>
<tls-auth>
$(cat /etc/openvpn/tls-auth.key)
</tls-auth>
EOF152

cat <<EOF16> /var/www/openvpn/udp.ovpn
# Credits to GakodX
client
dev tun
proto udp
setenv FRIENDLY_NAME "I'M MASTA GAKOD"
remote $IPADDR $OpenVPN_UDP_Port
resolv-retry infinite
route-method exe
nobind
persist-key
persist-tun
comp-lzo
cipher AES-256-CBC
auth SHA256
push "redirect-gateway def1 bypass-dhcp"
verb 3
push-peer-info
ping 10
ping-restart 60
hand-window 70
server-poll-timeout 4
reneg-sec 2592000
sndbuf 0
rcvbuf 0
remote-cert-tls server
key-direction 1
<auth-user-pass>
sam
sam
</auth-user-pass>
<ca>
$(cat /etc/openvpn/ca.crt)
</ca>
<cert>
$(cat /etc/openvpn/server_ADBtkp0yL46HLXPb.crt)
</cert>
<key>
$(cat /etc/openvpn/server_ADBtkp0yL46HLXPb.key)
</key>
<tls-auth>
$(cat /etc/openvpn/tls-auth.key)
</tls-auth>
EOF16

cat <<EOF17> /var/www/openvpn/ssl.ovpn
client
proto tcp-client
dev tun
setenv FRIENDLY_NAME "I'M MASTA GAKOD"
remote 127.0.0.1 443
route $IPADDR 255.255.255.255 net_gateway 
http-proxy $IPADDR 8080
http-proxy-retry
resolv-retry infinite
route-method exe
nobind
persist-key
persist-tun
comp-lzo
cipher AES-256-CBC
auth SHA256
push "redirect-gateway def1 bypass-dhcp"
verb 3
push-peer-info
ping 10
ping-restart 60
hand-window 70
server-poll-timeout 4
reneg-sec 2592000
sndbuf 0
rcvbuf 0
remote-cert-tls server
key-direction 1
<auth-user-pass>
sam
sam
</auth-user-pass>
<ca>
$(cat /etc/openvpn/ca.crt)
</ca>
<cert>
$(cat /etc/openvpn/client.crt)
</cert>
<key>
$(cat /etc/openvpn/client.key)
</key>
<tls-auth>
$(cat /etc/openvpn/tls-auth.key)
</tls-auth>
EOF17

# Setting UFW
apt-get install ufw
ufw allow ssh
ufw allow 443/tcp
sed -i 's|DEFAULT_INPUT_POLICY="DROP"|DEFAULT_INPUT_POLICY="ACCEPT"|' /etc/default/ufw
sed -i 's|DEFAULT_FORWARD_POLICY="DROP"|DEFAULT_FORWARD_POLICY="ACCEPT"|' /etc/default/ufw
cat > /etc/ufw/before.rules <<-END
# START OPENVPN RULES
# NAT table rules
*nat
:POSTROUTING ACCEPT [0:0]
# Allow traffic from OpenVPN client to eth0
-A POSTROUTING -s 10.8.0.0/8 -o eth0 -j MASQUERADE
COMMIT
# END OPENVPN RULES
END
ufw status
ufw disable

# OpenVPN monitoring
apt-get install -y gcc libgeoip-dev python-virtualenv python-dev geoip-database-extra uwsgi uwsgi-plugin-python
wget -O /srv/openvpn-monitor.tar "https://raw.githubusercontent.com/gatotx/AutoScriptDebian9/main/Res/Panel/openvpn-monitor.tar"
cd /srv
tar xf openvpn-monitor.tar
cd openvpn-monitor
virtualenv .
. bin/activate
pip install -r requirements.txt
wget -O /etc/uwsgi/apps-available/openvpn-monitor.ini "https://raw.githubusercontent.com/gatotx/AutoScriptDebian9/main/Res/Panel/openvpn-monitor.ini"
ln -s /etc/uwsgi/apps-available/openvpn-monitor.ini /etc/uwsgi/apps-enabled

#Shadowsocks
wget -N --no-check-certificate -c -t3 -T60 -O ss-plugins.sh https://git.io/fjlbl
chmod +x ss-plugins.sh

#v2ray
source <(curl -sL https://multi.netlify.com/v2ray.sh) --zh

#obfs proxy
wget -O /etc/openvpn/ "https://raw.githubusercontent.com/HRomie/obfs4proxy-openvpn/master/obfs4proxy-openvpn"
chmod +x /etc/openvn/obfs4proxy-openvpn


 # Creating OVPN download site index.html
cat <<'mySiteOvpn' > /var/www/openvpn/index.html
<!DOCTYPE html>
<html lang="en">

<!-- Simple OVPN Download site by Sigula -->

<head><meta charset="utf-8" /><title>Sigula OVPN Config Download</title><meta name="description" content="MyScriptName Server" /><meta content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" name="viewport" /><meta name="theme-color" content="#000000" /><link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.8.2/css/all.css"><link href="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.3.1/css/bootstrap.min.css" rel="stylesheet"><link href="https://cdnjs.cloudflare.com/ajax/libs/mdbootstrap/4.8.3/css/mdb.min.css" rel="stylesheet"></head><body><div class="container justify-content-center" style="margin-top:9em;margin-bottom:5em;"><div class="col-md"><div class="view"><img src="https://openvpn.net/wp-content/uploads/openvpn.jpg" class="card-img-top"><div class="mask rgba-white-slight"></div></div><div class="card"><div class="card-body"><h5 class="card-title">Config List</h5><br /><ul class="list-group"><li class="list-group-item justify-content-between align-items-center" style="margin-bottom:1em;"><p>For Sun <span class="badge light-blue darken-4">Android/iOS/PC/Modem</span><br /><small> UDP Server For TU/CTC/CTU Promos</small></p><a class="btn btn-outline-success waves-effect btn-sm" href="http://IP-ADDRESS:NGINXPORT/tcp.ovpn" style="float:right;"><i class="fa fa-download"></i> Download</a></li><li class="list-group-item justify-content-between align-items-center" style="margin-bottom:1em;"><p>For Sun <span class="badge light-blue darken-4">Android/iOS/PC/Modem</span><br /><small> TCP+Proxy Server For TU/CTC/CTU Promos</small></p><a class="btn btn-outline-success waves-effect btn-sm" href="http://IP-ADDRESS:NGINXPORT/udp.ovpn" style="float:right;"><i class="fa fa-download"></i> Download</a></li><li class="list-group-item justify-content-between align-items-center" style="margin-bottom:1em;"><p>For Globe/TM <span class="badge light-blue darken-4">Android/iOS/PC/Modem</span><br /><small> For EasySURF/GoSURF/GoSAKTO Promos with WNP,SNS,FB and IG freebies</small></p><a class="btn btn-outline-success waves-effect btn-sm" href="http://IP-ADDRESS:NGINXPORT/ssl.ovpn" style="float:right;"><i class="fa fa-download"></i> Download</a></li><li class="list-group-item justify-content-between align-items-center" style="margin-bottom:1em;"><p>For Sun <span class="badge light-blue darken-4">Modem</span><br /><small> Without Promo/Noload (Reconnecting Server, Use Low-latency VPS for fast reconnectivity)</small></p><a class="btn btn-outline-success waves-effect btn-sm" href="http://IP-ADDRESS:NGINXPORT/sun-noload.ovpn" style="float:right;"><i class="fa fa-download"></i> Download</a></li></ul></div></div></div></div></body></html>
mySiteOvpn
 
 # Setting template's correct name,IP address and nginx Port
 sed -i "s|NGINXPORT|$OvpnDownload_Port|g" /var/www/openvpn/index.html
 sed -i "s|IP-ADDRESS|$IPADDR|g" /var/www/openvpn/index.html

 # Restarting nginx service
 systemctl restart nginx
 
 # Creating all .ovpn config archives
 cd /var/www/openvpn
 zip -qq -r configs.zip *.ovpn
 cd
}

function ip_address(){
  local IP="$( ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1 )"
  [ -z "${IP}" ] && IP="$( wget -qO- -t1 -T2 ipv4.icanhazip.com )"
  [ -z "${IP}" ] && IP="$( wget -qO- -t1 -T2 ipinfo.io/ip )"
  [ ! -z "${IP}" ] && echo "${IP}" || echo
} 
IPADDR="$(ip_address)"

function ConfStartup(){
 # Daily reboot time of our machine
 # For cron commands, visit https://crontab.guru
 echo -e "0 4\t* * *\troot\treboot" > /etc/cron.d/b_reboot_job

 # Creating directory for startup script
 rm -rf /etc/Sigula
 mkdir -p /etc/Sigula
 chmod -R 755 /etc/Sigula
 
 # Creating startup script using cat eof tricks
 cat <<'EOFSH' > /etc/johnfordtv/startup.sh
#!/bin/bash
# Setting server local time
ln -fs /usr/share/zoneinfo/MyVPS_Time /etc/localtime

# Prevent DOS-like UI when installing using APT (Disabling APT interactive dialog)
export DEBIAN_FRONTEND=noninteractive

# Allowing ALL TCP ports for our machine (Simple workaround for policy-based VPS)
iptables -A INPUT -s $(wget -4qO- http://ipinfo.io/ip) -p tcp -m multiport --dport 1:65535 -j ACCEPT

# Allowing OpenVPN to Forward traffic
/bin/bash /etc/openvpn/openvpn.bash

# Deleting Expired SSH Accounts
/usr/local/sbin/delete_expired &> /dev/null
exit 0
EOFSH
 cat <<'FordServ' > /etc/systemd/system/Sigula.service
 
 # Setting server local time every time this machine reboots
 sed -i "s|MyVPS_Time|$MyVPS_Time|g" /etc/Sigula/startup.sh

 # 
 rm -rf /etc/sysctl.d/99*

 # Setting our startup script to run every machine boots 
 cat <<'FordServ' > /etc/systemd/system/Sigula.service
[Unit]
Description=Sigula Startup Script
Before=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/bin/bash /etc/Sigula/startup.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
FordServ
 chmod +x /etc/systemd/system/Sigula.service
 systemctl daemon-reload
 systemctl start Sigula
 systemctl enable Sigula &> /dev/null
 systemctl enable fail2ban &> /dev/null
 systemctl start fail2ban &> /dev/null

 # Rebooting cron service
 systemctl restart cron
 systemctl enable cron
 
}
 #Create Admin
 useradd -m admin
 echo "admin:itangsagli" | chpasswd

function ConfMenu(){
echo -e " Creating Menu scripts.."

cd /usr/local/sbin/
rm -rf {accounts,base-ports,base-ports-wc,base-script,bench-network,clearcache,connections,create,create_random,create_trial,delete_expired,diagnose,edit_dropbear,edit_openssh,edit_openvpn,edit_ports,edit_squid3,edit_stunnel4,locked_list,menu,options,ram,reboot_sys,reboot_sys_auto,restart_services,server,set_multilogin_autokill,set_multilogin_autokill_lib,show_ports,speedtest,user_delete,user_details,user_details_lib,user_extend,user_list,user_lock,user_unlock}
wget -q 'https://github.com/raziman869/AutoScriptDB/raw/master/Files/Menu/bashmenu.zip'
unzip -qq bashmenu.zip
rm -f bashmenu.zip
chmod +x ./*
dos2unix ./* &> /dev/null
sed -i 's|/etc/squid/squid.conf|/etc/privoxy/config|g' ./*
sed -i 's|http_port|listen-address|g' ./*
cd ~
}

function ScriptMessage(){
 echo -e " [\e[1;32m$MyScriptName VPS Installer\e[0m]"
 echo -e ""
 echo -e " t.me/Gakod"
 echo -e " [PAYPAL] GakodXGaming@gmail.com"
 echo -e ""
}

function InstBadVPN(){
 # Pull BadVPN Binary 64bit or 32bit
if [ "$(getconf LONG_BIT)" == "64" ]; then
 wget -O /usr/bin/badvpn-udpgw "https://github.com/raziman869/AutoScriptDB/raw/master/Files/Plugins/badvpn-udpgw64"
else
 wget -O /usr/bin/badvpn-udpgw "https://github.com/raziman869/AutoScriptDB/raw/master/Files/Plugins/badvpn-udpgw"
fi
 # Set BadVPN to Start on Boot via .profile
 sed -i '$ i\screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300' /root/.profile
 # Change Permission to make it Executable
 chmod +x /usr/bin/badvpn-udpgw
 # Start BadVPN via Screen
 screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300
}


#############################################
#############################################
########## Installation Process##############
#############################################
## WARNING: Do not modify or edit anything
## if you did'nt know what to do.
## This part is too sensitive.
#############################################
#############################################

 # Begin Installation by Updating and Upgrading machine and then Installing all our wanted packages/services to be install.
 ScriptMessage
 sleep 2
 InstUpdates
 
 # Configure OpenSSH and Dropbear
 echo -e "Configuring ssh..."
 InstSSH
 
 # Configure Stunnel
 echo -e "Configuring stunnel..."
 InsStunnel
 
 # Configure BadVPN UDPGW
 echo -e "Configuring BadVPN UDPGW..."
 InstBadVPN
 
 # Configure Webmin
 echo -e "Configuring webmin..."
 InstWebmin
 
 # Configure Squid
 echo -e "Configuring proxy..."
 InsProxy
 
 # Configure OpenVPN
 echo -e "Configuring OpenVPN..."
 InsOpenVPN
 
 # Configuring Nginx OVPN config download site
 OvpnConfigs

 # Some assistance and startup scripts
 ConfStartup

 ## DNS maker plugin for SUN users(for vps script usage only)
 wget -qO dnsmaker "https://raw.githubusercontent.com/Bonveio/BonvScripts/master/DNSMaster/debian"
 chmod +x dnsmaker
 ./dnsmaker
 rm -rf dnsmaker
 sed -i "s|http-proxy $IPADDR|http-proxy $(cat /tmp/abonv_mydns)|g" /var/www/openvpn/suntu-dns.ovpn
 sed -i "s|remote $IPADDR|remote $(cat /tmp/abonv_mydns)|g" /var/www/openvpn/sun-tuudp.ovpn
 curl -4sSL "$(cat /tmp/abonv_mydns_domain)" &> /dev/null
 mv /tmp/abonv_mydns /etc/bonveio/my_domain_name
 mv /tmp/abonv_mydns_id /etc/bonveio/my_domain_id
 rm -rf /tmp/abonv*

 # VPS Menu script v1.0
 ConfMenu
 
 # Setting server local time
 ln -fs /usr/share/zoneinfo/$MyVPS_Time /etc/localtime
 
 clear
 cd ~
 
  # Running screenfetch
 wget -O /usr/bin/screenfetch "https://raw.githubusercontent.com/raziman869/AutoScriptDB/master/Files/Plugins/screenfetch"
 chmod +x /usr/bin/screenfetch
 echo "/bin/bash /etc/openvpn/openvpn.bash" >> .profile
 echo "clear" >> .profile
 echo "screenfetch" >> .profile

 
 # Showing script's banner message
 ScriptMessage
 
 # Showing additional information from installating this script
echo " "
echo "Installation has been completed!!"
echo "--------------------------------------------------------------------------------"
echo "                            Debian Premium Script                               "
echo "                                 -SigulaDev-                                   "
echo "--------------------------------------------------------------------------------"
echo ""  | tee -a log-install.txt
echo "Server Information"  | tee -a log-install.txt
echo "   - Timezone    : Asia/Malaysia (GMT +8)"  | tee -a log-install.txt
echo "   - Fail2Ban    : [ON]"  | tee -a log-install.txt
echo "   - IPtables    : [ON]"  | tee -a log-install.txt
echo "   - Auto-Reboot : [ON]"  | tee -a log-install.txt
echo "   - IPv6        : [OFF]"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Application & Port Information"  | tee -a log-install.txt
echo "   - OpenVPN		: TCP $OpenVPN_TCP_Port UDP $OpenVPN_UDP_Port "  | tee -a log-install.txt
echo "   - OpenSSH		: $SSH_Port1, $SSH_Port2 "  | tee -a log-install.txt
echo "   - Dropbear		: $Dropbear_Port1, $Dropbear_Port2"  | tee -a log-install.txt
echo "   - Stunnel/SSL 	: $Stunnel_Port1, $Stunnel_Port2"  | tee -a log-install.txt
echo "   - Squid Proxy	: $Squid_Port1 , $Squid_Port2 (limit to IP Server)"  | tee -a log-install.txt
echo "   - Squid ELITE	: $Squid_Port3 (limit to IP Server)"  | tee -a log-install.txt
echo "   - Privoxy		: $Privoxy_Port1 , $Privoxy_Port2 (limit to IP Server)"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Premium Script Information"  | tee -a log-install.txt
echo "   To display list of commands: menu"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Important Information"  | tee -a log-install.txt
echo "   - Installation Log        : cat /root/log-install.txt"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "   - Webmin                  : http://$IPADDR:10000/"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "OpenVPN Configs Download"  | tee -a log-install.txt
echo "   - Download Link           : http://$IPADDR:85/configs.zip"  | tee -a log-install.txt
echo " Â©SigulaDev"  | tee -a log-install.txt
echo " t.me/sigula"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo " This script is under project of https://github.com/raziman869/AutoScriptDB"  | tee -a log-install.txt
echo " Please Reboot your VPS"

 # Clearing all logs from installation
 rm -rf /root/.bash_history && history -c && echo '' > /var/log/syslog

rm -f ss*
exit 1