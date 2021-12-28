#! /bin/bash

#############################################################################
#                                                                           #
# Author:       Martin Boller                                               #
#                                                                           #
# Email:        martin                                                      #
# Last Update:  2021-12-26                                                  #
# Version:      1.00                                                        #
#                                                                           #
# Changes:      Initial Version (1.00)                                      #
#                                                                           #
#                                                                           #
# Instruction:  builds latest Cyberchef version and copies                  #
#               build to host ./CyberChef to use for prod                   #
#               system. Create vagrant system or copy all of                #
#               ./CyberChef to your own web-server                          #
#                                                                           #
#                                                                           #
#############################################################################


install_prerequisites() {
    /usr/bin/logger 'install_prerequisites' -t 'CyberChef-20211226';
    echo -e "\e[1;32m--------------------------------------------\e[0m";
    echo -e "\e[1;32mInstalling Prerequisite packages\e[0m";
    export DEBIAN_FRONTEND=noninteractive;
    # OS Version
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
    /usr/bin/logger "Operating System: $OS Version: $VER" -t 'CyberChef-20211226';
    echo -e "\e[1;32mOperating System: $OS Version: $VER\e[0m";
 
    # Install prerequisites
    apt-get update;
    # Set correct locale
    locale-gen;
    update-locale;
    # Other pre-requisites for CyberChef
    apt-get -y install python3-pip python-is-python3 curl gnupg2;
    apt-get -y install bash-completion git iptables;
    # NodeJS 10 required for CyberChef, so going to install NVM to be able to install Node v10.24.1
    curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
    # Installing and enabling node v10.24.1 as default
    source ~/.bashrc;
    nvm install v10.24.1;
    nvm use v10.24.1;
    # A little apt
    apt-get -y install --fix-missing;
    apt-get update;
    apt-get -y full-upgrade;
    apt-get -y autoremove --purge;
    apt-get -y autoclean;
    apt-get -y clean;
    # Python pip packages
    python3 -m pip install --upgrade pip;
    /usr/bin/logger 'install_prerequisites finished' -t 'CyberChef-20211226';
}

obtain_cyberchef() {
    /usr/bin/logger 'obtain_cyberchef()' -t 'CyberChef-20211226';
    cd /opt/;
    # Get latest version from GitHub
    git clone https://github.com/gchq/CyberChef.git;
    sync;
    /usr/bin/logger 'obtain_cyberchef() finished' -t 'CyberChef-20211226';
}

install_cyberchef() {
    /usr/bin/logger 'install_cyberchef()' -t 'CyberChef-20211226';
    export NODE_OPTIONS=--max_old_space_size=2048
    cd /opt/CyberChef/;
    /usr/bin/logger '...Fix for fixCryptoApiImports()' -t 'CyberChef-20211226';
    sed -ie '/fixCryptoApiImports: {/a\        options: {shell: "/bin/bash"},' Gruntfile.js
    /usr/bin/logger '...Install Grunt' -t 'CyberChef-20211226';
    npm install -g grunt-cli;
    npm install grunt;

    /usr/bin/logger '...NPM Install of CyberChef' -t 'CyberChef-20211226';
    npm --experimental-modules --unsafe-perm install;

    /usr/bin/logger '...Rebuild CyberChef' -t 'CyberChef-20211226';
    npm --experimental-modules --unsafe-perm rebuild;

    /usr/bin/logger '...Audit and fix NPM modules CyberChef' -t 'CyberChef-20211226';
    npm --experimental-modules --unsafe-perm audit fix --force;

    /usr/bin/logger '...Create Prod build of CyberChef' -t 'CyberChef-20211226';
    grunt prod --force;

    /usr/bin/logger '...Set permissions' -t 'CyberChef-20211226';
    chown -R www-data:www-data $BUILD_LOCATION;
    /usr/bin/logger 'install_cyberchef()' -t 'CyberChef-20211226';
}

install_nginx() {
    /usr/bin/logger 'install_nginx()' -t 'CyberChef-20211226';
    apt-get -y install nginx apache2-utils;
    /usr/bin/logger 'install_nginx() finished' -t 'CyberChef-20211226';
}

configure_nginx() {
    /usr/bin/logger 'configure_nginx()' -t 'CyberChef-20211226';
    openssl dhparam -out /etc/nginx/dhparam.pem 2048 &>/dev/null
    # TLS
    cat << __EOF__ > /etc/nginx/sites-available/default;
#
# Changed by: Martin Boller
# Last Update: 2021-11-21
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
    }
  }

__EOF__
    /usr/bin/logger 'configure_nginx() finished' -t 'CyberChef-20211226';
}

nginx_certificates() {
    ## Use this if you want to create a request to send to corporate PKI for the web interface, also change the NGINX config to use that
    /usr/bin/logger 'nginx_certificates()' -t 'CyberChef-20211226';

    ## NGINX stuff
    ## Required information for NGINX certificates
    # organization name
    # (see also https://www.switch.ch/pki/participants/)
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
    /usr/bin/logger 'nginx_certificates() finished' -t 'CyberChef-20211226';
}

copy_build_2_host() {
    /usr/bin/logger 'copy_build_2_host()' -t 'CyberChef-20211226';
    cp -r $BUILD_LOCATION/* /mnt/build/;
    /usr/bin/logger 'copy_build_2_host() finished' -t 'CyberChef-20211226';
}

start_services() {
    /usr/bin/logger 'start_services' -t 'CyberChef-20211226';
    # Load new/changed systemd-unitfiles
    systemctl daemon-reload;
    systemctl restart nginx.service;
    echo -e "\e[1;32m-----------------------------------------------------------------\e[0m";
    echo -e "\e[1;32mChecking core daemons for CyberChef......\e[0m";
    if systemctl is-active --quiet nginx.service;
    then
        /usr/bin/logger 'nginx.service started successfully' -t 'CyberChef-20211226';
        echo -e "\e[1;32mnginx.service started successfully\e[0m";
    else
        /usr/bin/logger 'nginx.service FAILED!' -t 'CyberChef-20211226';
        echo -e "\e[1;32mnginx.service FAILED! check logs and certificates\e[0m";
    fi
    /usr/bin/logger 'start_services finished' -t 'CyberChef-20211226';
}


##################################################################################################################
## Main                                                                                                          #
##################################################################################################################

main() {
    BUILD_LOCATION="/opt/CyberChef/build/prod";
    # NGINX and certificates
    # Create and Install certificates
    CERTIFICATE_ORG="CyberChef"
    # Local information
    CERTIFICATE_COUNTRY="DK"
    CA_CERTIFICATE_STATE="Denmark"
    CERTIFICATE_LOCALITY="Copenhagen"
    install_prerequisites;
    obtain_cyberchef;
    # To test the build immediately install and configure NGINX with certificates (uncomment below)
#    install_nginx;
#    nginx_certificates;
#    configure_nginx;
    install_cyberchef;
    copy_build_2_host;
}

main;

exit 0;
