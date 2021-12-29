#! /bin/bash

#############################################################################
#                                                                           #
# Author:       Martin Boller                                               #
#                                                                           #
# Email:        martin                                                      #
# Last Update:  2021-12-29                                                  #
# Version:      1.10                                                        #
#                                                                           #
# Changes:      Initial Version (1.00)                                      #
#                                                                           #
# Instruction:  Installs and configures NGINX with self-signed              #
#               certificates. Manually copy CyberChef build to              #
#               /var/www/CyberChef/                                         #
#                                                                           #
#############################################################################

obtain_cyberchef_build() {
    /usr/bin/logger 'obtain_cyberchef_build()' -t 'CyberChef-20211226';
    mkdir -p /var/www/CyberChef/;
    echo -e "\e[1;31m--------------------------------------------\e[0m";
    echo -e "\e[1;31mCopy the finished production build of CyberChef to $BUILD_LOCATION before continuing";
    read -p "Press Return to continue" Dummy;
    echo -e "\e[0m"
    chown -R www-data:www-data /var/www/;
    /usr/bin/logger 'obtain_cyberchef_build() finished' -t 'CyberChef-20211226';
}

install_prerequisites() {
    /usr/bin/logger 'install_prerequisites' -t 'CyberChef-20211229';
    echo -e "\e[1;32m--------------------------------------------\e[0m";
    echo -e "\e[1;32mInstalling Prerequisite packages\e[0m";
    export DEBIAN_FRONTEND=noninteractive;
    # OS Version
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
    /usr/bin/logger "Operating System: $OS Version: $VER" -t 'CyberChef-20211229';
    echo -e "\e[1;32mOperating System: $OS Version: $VER\e[0m";
    # Install prerequisites
    apt-get update;
    # Set correct locale
    locale-gen;
    update-locale;
    # Other pre-requisites for CyberChef
    apt-get -y install python3-pip python-is-python3 curl gnupg2;
    apt-get -y install bash-completion git sudo iptables;

    # A little apt for cleanup
    apt-get -y install --fix-missing;
    apt-get update;
    apt-get -y full-upgrade;
    apt-get -y autoremove --purge;
    apt-get -y autoclean;
    apt-get -y clean;
    # Python pip packages
    python3 -m pip install --upgrade pip;
    echo -e "\e[32minstall_prerequisites() finished\e[0m";
    /usr/bin/logger 'install_prerequisites() finished' -t 'CyberChef-20211229';
}

install_nodejs_10() {
    # NodeJS 10 required for CyberChef, so going to install NVM to install Node v10.24.1
    /usr/bin/logger 'install_nodejs_10()' -t 'CyberChef-20211229';
    echo -e "\e[32minstall_nodejs_10()\e[0m";
    curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
    source ~/.bashrc;
    nvm install v10.24.1;
    nvm use v10.24.1;
    echo -e "\e[32minstall_nodejs_10() finished\e[0m";
    /usr/bin/logger 'install_nodejs_10() finished' -t 'CyberChef-20211229';
}

install_nodejs_debian_repo() {
    /usr/bin/logger 'install_nodejs_debian_repo()' -t 'CyberChef-20211229';
    echo -e "\e[32minstall_nodejs_debian_repo()\e[0m";
    apt-get -y install nodejs;
    echo -e "\e[32minstall_nodejs_debian_repo() finished\e[0m";
    /usr/bin/logger 'install_nodejs_debian_repo() finished' -t 'CyberChef-20211229';
}

install_nginx() {
    /usr/bin/logger 'install_nginx()' -t 'CyberChef-20211229';
    echo -e "\e[32mobtain_nginx()\e[0m";
    apt-get -y install nginx apache2-utils;
    echo -e "\e[32mobtain_nginx() finished\e[0m";
    /usr/bin/logger 'install_nginx() finished' -t 'CyberChef-20211229';
}

configure_nginx() {
    /usr/bin/logger 'configure_nginx()' -t 'CyberChef-20211229';
    echo -e "\e[32mconfigure_nginx()\e[0m";
    openssl dhparam -out /etc/nginx/dhparam.pem 2048 &>/dev/null
    # TLS
    cat << __EOF__ > /etc/nginx/sites-available/default;
#
# Changed by: Martin Boller
# Last Update: 2021-11-26
#
# Web Server for CyberChef
# Running on, or redirecting to, port 443 TLS
##

server {
    listen 80;
    return 301 https://\$host\$request_uri;
}

server {
    client_max_body_size 32M;
    listen 443 ssl http2;
    root $BUILD_LOCATION;
    index index.html;
    ssl_certificate           /etc/nginx/certs/$HOSTNAME.crt;
    ssl_certificate_key       /etc/nginx/certs/$HOSTNAME.key;
    ssl on;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!eNULL:!EXPORT:!CAMELLIA:!DES:!MD5:!PSK:!RC4;
    ssl_prefer_server_ciphers on;
    # Enable HSTS
    add_header Strict-Transport-Security "max-age=31536000" always;
    # Optimize session cache
    ssl_session_cache   shared:SSL:40m;
    ssl_session_timeout 4h;  # Enable session tickets
    ssl_session_tickets on;
    # Diffie Hellman Parameters
    ssl_dhparam /etc/nginx/dhparam.pem;
    location / {
        try_files \$uri \$uri/ =404;
        # Authentication
        #auth_basic "CyberChef login";
        #auth_basic_user_file /etc/nginx/.htpasswd;
        # Access log for cyberchef
        access_log /var/log/nginx/cyberchef.access.log;
    }
  }

__EOF__
    echo -e "\e[32mconfigure_nginx() finished\e[0m";
    /usr/bin/logger 'configure_nginx() finished' -t 'CyberChef-20211229';
}

configure_nginx_auth() {
    /usr/bin/logger 'configure_nginx_auth()' -t 'CyberChef-20211229';
    echo -e "\e[32mconfigure_nginx_auth()\e[0m";
    sed -i -e 's/#auth_basic "CyberChef login"/auth_basic "CyberChef login"/' /etc/nginx/sites-available/default;
    sed -i -e 's/#auth_basic_user_file \/etc\/nginx\/.htpasswd/auth_basic_user_file \/etc\/nginx\/.htpasswd/' /etc/nginx/sites-available/default;
    echo -e "\e[32mconfigure_nginx_auth() finished\e[0m";
    /usr/bin/logger 'configure_nginx_auth() finished' -t 'CyberChef-20211229';
}

nginx_certificates() {
    ## Use this if you want to create a request to send to corporate PKI for the web interface, also change the NGINX config to use that
    /usr/bin/logger 'nginx_certificates()' -t 'CyberChef-20211229';
    echo -e "\e[32mnginx_certificates()\e[0m";

    ## NGINX stuff
    ## Required information for NGINX certificates
    # organization name
    export ORGNAME=$CERTIFICATE_ORG
    # the fully qualified server (or service) name, change if other servicename than hostname
    export FQDN=$HOSTNAME;
    # Local information
    export ISOCOUNTRY=$CERTIFICATE_COUNTRY
    export PROVINCE=$CA_CERTIFICATE_STATE
    export LOCALITY=$CERTIFICATE_LOCALITY
    # subjectAltName entries: to add DNS aliases to the CSR, delete
    # the '#' character in the ALTNAMES line, and change the subsequent
    # 'DNS:' entries accordingly. Please note: all DNS names must
    # resolve to the same IP address as the FQDN.
    export ALTNAMES=DNS:$HOSTNAME   # , DNS:bar.example.org , DNS:www.foo.example.org

    mkdir -p /etc/nginx/certs/;
    cat << __EOF__ > ./openssl.cnf
## Request for $FQDN
[ req ]
default_bits = 2048
default_md = sha256
prompt = no
encrypt_key = no
distinguished_name = dn
req_extensions = req_ext

[ dn ]
countryName         = $ISOCOUNTRY
stateOrProvinceName = $PROVINCE
localityName        = $LOCALITY
organizationName    = $ORGNAME
organizationalUnitName = $ORGUNIT

CN = $FQDN

[ req_ext ]
subjectAltName = $ALTNAMES
__EOF__
    sync;
    # generate Certificate Signing Request to send to corp PKI
    openssl req -new -config openssl.cnf -keyout /etc/nginx/certs/$HOSTNAME.key -out /etc/nginx/certs/$HOSTNAME.csr
    # generate self-signed certificate (remove when CSR can be sent to Corp PKI)
    openssl x509 -in /etc/nginx/certs/$HOSTNAME.csr -out /etc/nginx/certs/$HOSTNAME.crt -req -signkey /etc/nginx/certs/$HOSTNAME.key -days 365
    chmod 600 /etc/nginx/certs/$HOSTNAME.key
    echo -e "\e[32mnginx_certificates finished\e[0m";
    /usr/bin/logger 'nginx_certificates() finished' -t 'CyberChef-20211229';
}

configure_iptables() {
    /usr/bin/logger 'configure_iptables()' -t 'CyberChef-20211229';
    echo -e "\e[32mconfigure_iptables()\e[0m";
    echo -e "\e[32m-Creating iptables rules file\e[0m";
    cat << __EOF__  >> /etc/network/iptables.rules
##
## Ruleset for CyberChef Server
##
## IPTABLES Ruleset Author: Martin Boller 2021-12-26 v1

*filter
## Dropping anything not explicitly allowed
##
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
:LOG_DROPS - [0:0]

## DROP IP fragments
-A INPUT -f -j LOG_DROPS
-A INPUT -m ttl --ttl-lt 4 -j LOG_DROPS

## DROP bad TCP/UDP combinations
-A INPUT -p tcp --dport 0 -j LOG_DROPS
-A INPUT -p udp --dport 0 -j LOG_DROPS
-A INPUT -p tcp --tcp-flags ALL NONE -j LOG_DROPS
-A INPUT -p tcp --tcp-flags ALL ALL -j LOG_DROPS

## Allow everything on loopback
-A INPUT -i lo -j ACCEPT

## SSH, DNS, WHOIS, DHCP ICMP - Add anything else here needed for ntp, monitoring, dhcp, icmp, updates, and ssh
##
## SSH
-A INPUT -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT
## HTTP(S)
-A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
## NTP
### ICMP
-A INPUT -p icmp -j ACCEPT
## Already established sessions
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT

## Logging
-A INPUT -j LOG_DROPS
## get rid of broadcast noise
-A LOG_DROPS -d 255.255.255.255 -j DROP
# Drop Broadcast to internal networks
-A LOG_DROPS -m pkttype --pkt-type broadcast -d 192.168.0.0/16 -j DROP
-A LOG_DROPS -p ip -m limit --limit 60/sec -j LOG --log-prefix "iptables:" --log-level 7
-A LOG_DROPS -j DROP

## Commit everything
COMMIT
__EOF__

# ipv6 rules
    cat << __EOF__  >> /etc/network/ip6tables.rules
##
## Ruleset for CyberChef Server
##
## IP6TABLES Ruleset Author: Martin Boller 2021-12-26 v1

*filter
## Dropping anything not explicitly allowed
##
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
:LOG_DROPS - [0:0]

## DROP bad TCP/UDP combinations
-A INPUT -p tcp --dport 0 -j LOG_DROPS
-A INPUT -p udp --dport 0 -j LOG_DROPS
-A INPUT -p tcp --tcp-flags ALL NONE -j LOG_DROPS
-A INPUT -p tcp --tcp-flags ALL ALL -j LOG_DROPS

## Allow everything on loopback
-A INPUT -i lo -j ACCEPT

## SSH, DNS, WHOIS, DHCP ICMP - Add anything else here needed for ntp, monitoring, dhcp, icmp, updates, and ssh
## SSH
-A INPUT -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT
## HTTP(S)
-A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
## NTP
#-A INPUT -p udp -m udp --dport 123 -j ACCEPT
## ICMP
-A INPUT -p icmp -j ACCEPT
## Already established sessions
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT

## Logging
-A INPUT -j LOG_DROPS
-A LOG_DROPS -p ip -m limit --limit 60/sec -j LOG --log-prefix "iptables:" --log-level 7
-A LOG_DROPS -j DROP

## Commit everything
COMMIT
__EOF__

    # Configure separate file for iptables logging
    cat << __EOF__  >> /etc/rsyslog.d/30-iptables-syslog.conf
:msg,contains,"iptables:" /var/log/iptables.log
& stop
__EOF__
    sync;
    systemctl restart rsyslog.service;

    # Configure daily logrotation (forward this log to log mgmt)
    cat << __EOF__  >> /etc/logrotate.d/iptables
/var/log/iptables.log {
  rotate 2
  daily
  compress
  create 640 root root
  notifempty
  postrotate
    /usr/lib/rsyslog/rsyslog-rotate
  endscript
}
__EOF__

# Apply iptables at boot
    echo -e "\e[36m-Script applying iptables rules\e[0m";
    cat << __EOF__  >> /etc/network/if-up.d/firewallrules
#! /bin/bash
iptables-restore < /etc/network/iptables.rules
ip6tables-restore < /etc/network/ip6tables.rules
exit 0
__EOF__
    sync;
    ## make the script executable
    chmod +x /etc/network/if-up.d/firewallrules;
    # Apply firewall rules for the first time
    /etc/network/if-up.d/firewallrules;
    echo -e "\e[32mconfigure_iptables finished\e[0m";
    /usr/bin/logger 'configure_iptables() finished' -t 'CyberChef-20211229';
}

start_services() {
    /usr/bin/logger 'start_services' -t 'CyberChef-20211229';
    echo -e "\e[32mstart_services() finished\e[0m";
    # Load new/changed systemd-unitfiles
    systemctl daemon-reload;
    systemctl restart nginx.service;
    echo -e "\e[1;32m-----------------------------------------------------------------\e[0m";
    echo -e "\e[1;32mChecking core daemons for CyberChef......\e[0m";
    if systemctl is-active --quiet nginx.service;
    then
        /usr/bin/logger 'nginx.service started successfully' -t 'CyberChef-20211229';
        echo -e "\e[1;32mnginx.service started successfully\e[0m";
    else
        /usr/bin/logger 'nginx.service FAILED!' -t 'CyberChef-20211229';
        echo -e "\e[1;32mnginx.service FAILED! check logs and certificates\e[0m";
    fi
    echo -e "\e[32mstart_services finished\e[0m";
    /usr/bin/logger 'start_services finished' -t 'CyberChef-20211229';
}

create_web_user() {
    /usr/bin/logger 'create_web_user()' -t 'CyberChef-20211229';
    echo -e "\e[32mcreate_web_user() finished\e[0m";
    htpasswd -cbB /etc/nginx/.htpasswd cyberchef $cyberchef_web_pw;
    mkdir /var/lib/cyberchef;
    echo $cyberchef_web_pw > /var/lib/cyberchef/cyberchef_pw;
    echo -e "\e[32mcreate_web_user() finished\e[0m";
    /usr/bin/logger 'create_web_user() finished' -t 'CyberChef-20211229';
}

##################################################################################################################
## Main                                                                                                          #
##################################################################################################################

main() {
    # Some variables to use with build
    BUILD_LOCATION="/var/www/CyberChef";
    # User for basic authentication with NGINX
    cyberchef_web_user=cyberchef;
    cyberchef_web_pw="$(< /dev/urandom tr -dc A-Za-z0-9 | head -c 12)";

    obtain_cyberchef_build;
    # NGINX and certificates
    # Create and Install certificates
    CERTIFICATE_ORG="CyberChef"
    # Local information
    CERTIFICATE_COUNTRY="DK"
    CA_CERTIFICATE_STATE="Denmark"
    CERTIFICATE_LOCALITY="Aabenraa"
    ORG_UNIT="Security"
    # Install requirements
    install_prerequisites;
    # Install the version of node you want (default "debian repo provided")
    install_nodejs_debian_repo;
    #install_nodejs_10;
    # Install and configure NGINX with self-signed certificate
    install_nginx;
    create_web_user;
    nginx_certificates;
    # Without Authentication (see below)
    configure_nginx;
    # If you want basic authentication on the web server (htpasswd) use configure_nginx_auth instead of configure_nginx
    #configure_nginx_auth;
    # Copy the finished build from the virtual host server
    configure_iptables
    # Restart NGINX
    start_services;
}

main;

exit 0;
