#! /bin/bash

install_prerequisites() {
    /usr/bin/logger 'install_prerequisites' -t 'CyberChef-20250121';
    echo -e "\e[1;32m - Installing Prerequisite packages\e[0m";
    export DEBIAN_FRONTEND=noninteractive;
    # OS Version
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
    /usr/bin/logger "Operating System: $OS Version: $VER" -t 'CyberChef-20250121';
    echo -e "\e[1;32m - Operating System: $OS Version: $VER\e[0m";
 
    # Install prerequisites
    apt-get -qq update;
    # Set correct locale
    #locale-gen;
    #update-locale;
    # Other pre-requisites for CyberChef
    apt-get -y -qq install python3-pip python-is-python3 curl gnupg2;
    apt-get -y -qq install bash-completion git iptables;
    # NodeJS 10 required for CyberChef, so going to install NVM to be able to install Node v10.24.1
    curl -s https://raw.githubusercontent.com/creationix/nvm/master/install.sh > ./installnvm.sh
    chmod 744 installnvm.sh;
    ./installnvm.sh;
    # Installing and enabling node v10.24.1 as default
    source ~/.bashrc;
    nvm install v10.24.1;
    nvm use v10.24.1;
    # A little apt
    apt-get -y -qq install --fix-missing;
    apt-get -qq update;
    apt-get -y -qq full-upgrade;
    apt-get -y -qq autoremove --purge;
    apt-get -y -qq autoclean;
    apt-get -y -qq clean;
    # Python pip packages
    python3 -m pip install --upgrade pip;
    echo -e "\e[1;32m - Installing Prerequisite packages finished\e[0m";
    /usr/bin/logger 'install_prerequisites finished' -t 'CyberChef-20250121';
}

obtain_cyberchef() {
    /usr/bin/logger 'obtain_cyberchef()' -t 'CyberChef-20250121';
    echo -e "\e[1;32m-------------------------------------------\e[0m";
    echo -e "\e[1;32m - obtain_cyberchef\e[0m";
    cd /opt/;
    # Get latest version from GitHub
    git clone --quiet https://github.com/gchq/CyberChef.git;
    sync;
    echo -e "\e[1;32m - obtain_cyberchef finished\e[0m";
    /usr/bin/logger 'obtain_cyberchef() finished' -t 'CyberChef-20250121';
}

install_cyberchef() {
    /usr/bin/logger 'install_cyberchef()' -t 'CyberChef-20250121';
    echo -e "\e[1;32m-------------------------------------------\e[0m";
    echo -e "\e[1;32m - install_cyberchef\e[0m";
    export NODE_OPTIONS=--max_old_space_size=2048
    cd /opt/CyberChef/;
    ## rm -fr ./build ./node_modules package-lock.json && git checkout . && npm install && time ./node_modules/grunt/bin/grunt prod --force
    rm -fr ./build ./node_modules package-lock.json .nvmrc
    git checkout .
    /usr/bin/logger 'fix for fixCryptoApiImports()' -t 'CyberChef-20250121';
    echo -e "\e[1;36m ... fix for fixCryptoApiImports()\e[0m";
    sed -ie '/fixCryptoApiImports: {/a\        options: {shell: "/bin/bash"},' Gruntfile.js
    /usr/bin/logger 'install grunt components required' -t 'CyberChef-20250121';
    echo -e "\e[1;36m ... install grunt-cli\e[0m";
    npm install -g grunt-cli ;
    echo -e "\e[1;36m ... install grunt\e[0m";
    npm install grunt;

    /usr/bin/logger 'npm Install CyberChef' -t 'CyberChef-20250121';
    echo -e "\e[1;36m ... npm install CyberChef\e[0m";
    npm --experimental-modules --unsafe-perm install;

    /usr/bin/logger 'npm rebuild CyberChef' -t 'CyberChef-20250121';
    echo -e "\e[1;36m ... npm rebuild CyberChef\e[0m";
    npm --experimental-modules --unsafe-perm rebuild;

    /usr/bin/logger 'audit and fix NPM modules CyberChef' -t 'CyberChef-20250121';
    echo -e "\e[1;36m ... audit and fix npm modules CyberChef\e[0m";
    npm --experimental-modules --unsafe-perm audit fix --force;

    /usr/bin/logger 'creating production build of CyberChef' -t 'CyberChef-20250121';
    echo -e "\e[1;36m ... creating production build of CyberChef\e[0m";
    echo -e "\e[1;36m ... - This will take a few minutes - ...\e[0m";
    grunt prod --fix --force;

    /usr/bin/logger 'Set permissions' -t 'CyberChef-20250121';
    echo -e "\e[1;36m ... Setting permissions on build directory\e[0m";
    chown -R www-data:www-data $BUILD_LOCATION ;
    echo -e "\e[1;32m - install_cyberchef finished\e[0m";
    /usr/bin/logger 'install_cyberchef()' -t 'CyberChef-20250121';
}

install_nginx() {
    /usr/bin/logger 'install_nginx()' -t 'CyberChef-20250121';
    echo -e "\e[1;32m-------------------------------------------\e[0m";
    echo -e "\e[1;32m - install_nginx\e[0m";
    apt-get -y -qq install nginx apache2-utils;
    echo -e "\e[1;32m - install_nginx finished\e[0m";
    /usr/bin/logger 'install_nginx() finished' -t 'CyberChef-20250121';
}

configure_nginx() {
    /usr/bin/logger 'configure_nginx()' -t 'CyberChef-20250121';
    echo -e "\e[1;32m-------------------------------------------\e[0m";
    echo -e "\e[1;32m - configure_nginx\e[0m";
    echo -e "\e[1;36m ... generating dhparam\e[0m";
    openssl dhparam -out /etc/nginx/dhparam.pem 2048 &>/dev/null
    echo -e "\e[1;36m ... create site\e[0m";
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
        # Access and error log for cyberchef
        access_log /var/log/nginx/cyberchef.access.log;
        error_log /var/log/nginx/cyberchef.error.log debug;
    }
  }

__EOF__
    echo -e "\e[1;32m - configure_nginx finished\e[0m";
    /usr/bin/logger 'configure_nginx() finished' -t 'CyberChef-20250121';
}

nginx_certificates() {
    ## Use this if you want to create a request to send to corporate PKI for the web interface, also change the NGINX config to use that
    /usr/bin/logger 'nginx_certificates()' -t 'CyberChef-20250121';
    echo -e "\e[1;32m-------------------------------------------\e[0m";
    echo -e "\e[1;32m - nginx_certificates\e[0m";
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
    echo -e "\e[1;36m ... create certs directory\e[0m";
    mkdir -p /etc/nginx/certs/ ;
    echo -e "\e[1;36m ... create openssl.cnf\e[0m";
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
    echo -e "\e[1;36m ... generate Certificate Signing Request to send to corp PKI\e[0m";
    openssl req -new -config openssl.cnf -keyout /etc/nginx/certs/$HOSTNAME.key -out /etc/nginx/certs/$HOSTNAME.csr
    # generate self-signed certificate (remove when CSR can be sent to Corp PKI)
    echo -e "\e[1;36m ... generate self-signed certificate\e[0m";
    openssl x509 -in /etc/nginx/certs/$HOSTNAME.csr -out /etc/nginx/certs/$HOSTNAME.crt -req -signkey /etc/nginx/certs/$HOSTNAME.key -days 365 
    chmod 600 /etc/nginx/certs/$HOSTNAME.key
    echo -e "\e[1;32m - nginx_certificates finished\e[0m";
    /usr/bin/logger 'nginx_certificates() finished' -t 'CyberChef-20250121';
}

copy_build_2_host() {
    /usr/bin/logger 'copy_build_2_host()' -t 'CyberChef-20250121';
    echo -e "\e[1;32m-------------------------------------------\e[0m";
    echo -e "\e[1;32m - copy_build_2_host()\e[0m";
    cp -r $BUILD_LOCATION/* /mnt/build/ ;
    echo -e "\e[1;32m - copy_build_2_host() finished\e[0m";
    /usr/bin/logger 'copy_build_2_host() finished' -t 'CyberChef-20250121';
}

start_services() {
    /usr/bin/logger 'start_services' -t 'CyberChef-20250121';
    echo -e "\e[1;32m-------------------------------------------\e[0m";
    echo -e "\e[1;32m - start_services()\e[0m";
    # Load new/changed systemd-unitfiles
    systemctl daemon-reload;
    systemctl restart nginx.service;
    echo -e "\e[1;36m ... Checking core daemons for CyberChef......\e[0m";
    if systemctl is-active --quiet nginx.service;
    then
        /usr/bin/logger 'nginx.service started successfully' -t 'CyberChef-20250121';
        echo -e "\e[1;36m ... nginx.service started successfully\e[0m";
    else
        /usr/bin/logger 'nginx.service FAILED!' -t 'CyberChef-20250121';
        echo -e "\e[1;31m ... nginx.service FAILED! check logs and certificates\e[0m";
    fi
    echo -e "\e[1;32m - start_services() finished\e[0m";
    /usr/bin/logger 'start_services finished' -t 'CyberChef-20250121';
}

##################################################################################################################
## Main                                                                                                          #
##################################################################################################################

main() {
    echo -e "\e[1;32m-------------------------------------------\e[0m";
    echo -e "\e[1;32m - Build Environment main()\e[0m";
    /usr/bin/logger 'Build Environment main()' -t 'CyberChef-20250121';
    BUILD_LOCATION="/opt/CyberChef/build/prod";
    # NGINX and certificates
    # Create and Install certificates
    CERTIFICATE_ORG="CyberChef"
    # Local information
    CERTIFICATE_COUNTRY="DK"
    CA_CERTIFICATE_STATE="Denmark"
    CERTIFICATE_LOCALITY="Copenhagen"
    ORGUNIT="Security"
    # Alias to allow redirection, change to '' if no redirection
    shopt -s expand_aliases
    alias redir='> /dev/null 2>&1'
    #alias redir=''
  
    # installation
    install_prerequisites;
    obtain_cyberchef;
    # To test the build immediately install and configure NGINX with certificates (uncomment below)
#    install_nginx;
#    nginx_certificates;
#    configure_nginx;
    install_cyberchef;
    copy_build_2_host;
    sleep 30;
    echo -e "\e[1;32m - Build Environment main() finished\e[0m";
    echo -e "\e[1;31m - Powering off in 30 seconds!\e[0m";
    echo -e "\e[1;32m-------------------------------------------\e[0m";
    /usr/bin/logger 'Build Environment main() finished' -t 'CyberChef-20250121';
    systemctl poweroff;
}

main;

exit 0;
