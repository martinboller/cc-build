#! /bin/bash

#####################################################################
#                                                                   #
# Author:       Martin Boller                                       #
#                                                                   #
# Email:        martin                                              #
# Last Update:  2022-01-07                                          #
# Version:      2.00                                                #
#                                                                   #
# Changes:      Kicks off installation in Vagrant env               #
#                                                                   #
#                                                                   #
#####################################################################

bootstrap_locale() {
  /usr/bin/logger 'bootstrap_locale()' -t 'CyberChef-bootstrap';
  echo -e "\e[32mbootstrap_locale()\e[0m";
  echo -e "\e[36m - configure locale (default:C.UTF-8)\e[0m";
  export DEBIAN_FRONTEND=noninteractive;
  sh -c "cat << EOF  > /etc/default/locale
# /etc/default/locale
LANG=C.UTF-8
LANGUAGE=C.UTF-8
LC_ALL=C.UTF-8
EOF";
  update-locale > /dev/null 2>&1;
  echo -e "\e[32mbootstrap_locale() finished\e[0m";
  /usr/bin/logger 'bootstrap_locale() finished' -t 'CyberChef-bootstrap';
}

bootstrap_timezone() {
  /usr/bin/logger 'bootstrap_timezone()' -t 'CyberChef-bootstrap';
  echo -e "\e[32mbootstrap_timezone()\e[0m";
  echo -e "\e[36m - set timezone to Etc/UTC\e[0m";
  export DEBIAN_FRONTEND=noninteractive;
  rm /etc/localtime > /dev/null 2>&1;
  echo 'Etc/UTC' > /etc/timezone > /dev/null 2>&1;
  dpkg-reconfigure -f noninteractive tzdata > /dev/null 2>&1;
  echo -e "\e[32mbootstrap_timezone() finished\e[0m";
  /usr/bin/logger 'bootstrap_timezone() finished' -t 'CyberChef-bootstrap';
}

bootstrap_prerequisites() {
  /usr/bin/logger 'bootstrap_prerequisites()' -t 'CyberChef-bootstrap';
  echo -e "\e[32mbootstrap_prerequisites()\e[0m";
  # Install prerequisites and useful tools
  export DEBIAN_FRONTEND=noninteractive;
  echo -e "\e[1;36m ... removing unneeded packages\e[0m";
  apt-get -y -qq remove postfix* memcached > /dev/null 2>&1;
  sync;
  echo -e "\e[1;36m ... apt cleanup\e[0m";
  apt-get -qq update > /dev/null 2>&1;
  apt-get -y -qq full-upgrade > /dev/null 2>&1;
  apt-get -y -qq --purge autoremove > /dev/null 2>&1;
  apt-get -qq autoclean;
  sync;
  /usr/bin/logger 'install_updates()' -t 'CyberChef-bootstrap';
  echo -e "\e[1;36m ... cleaning nameservers in interfaces file\e[0m";
  sed -i '/dns-nameserver/d' /etc/network/interfaces > /dev/null 2>&1;
  # copy relevant scripts
  echo -e "\e[1;36m ... copying installation scripts\e[0m";
  /bin/cp /tmp/installfiles/*.sh /root/ > /dev/null 2>&1;
  chmod 744 /root/*.sh > /dev/null 2>&1;
  echo -e "\e[32mbootstrap_prerequisites() finished\e[0m";
  /usr/bin/logger 'bootstrap_prerequisites() finished' -t 'CyberChef-bootstrap';
}

bootstrap_install_public_ssh_key() {
  /usr/bin/logger 'bootstrap_install_public_ssh_key()' -t 'CyberChef-bootstrap';
  echo -e "\e[32mbootstrap_install_public_ssh_key()\e[0m";
  # Echo add SSH public key for root logon
  export DEBIAN_FRONTEND=noninteractive;
  mkdir /root/.ssh > /dev/null 2>&1;
  echo -e "\e[1;36m ... adding public key to authorized_keys\e[0m";
  echo $myPublicSSHKey | tee -a /root/.ssh/authorized_keys > /dev/null 2>&1;
  echo -e "\e[1;36m ... setting permissions\e[0m";
  chmod 700 /root/.ssh > /dev/null 2>&1;
  chmod 600 /root/.ssh/authorized_keys > /dev/null 2>&1;
  echo -e "\e[32mbootstrap_install_public_ssh_key() finished\e[0m";
  /usr/bin/logger 'bootstrap_install_public_ssh_key() finished' -t 'CyberChef-bootstrap';
}

##################################################################################################################
## Main                                                                                                          #
##################################################################################################################

main() {
    /usr/bin/logger 'Bootstrap main()' -t 'CyberChef-bootstrap';
    # Core elements, always installs
    #prepare_files;
    ## Change the public key below to be yours, and don't allow me root access using my lab key.
    ## Which will happen if you leave the key below in the script.
    readonly myPublicSSHKey="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIHJYsxpawSLfmIAZTPWdWe2xLAH758JjNs5/Z2pPWYm"
    /usr/bin/logger '!!!!! Main routine starting' -t 'CyberChef-bootstrap';
    bootstrap_install_public_ssh_key;
    bootstrap_prerequisites;
    #bootstrap_locale;
    #bootstrap_timezone;
    # copy relevant scripts
    /bin/cp /tmp/installfiles/*.sh /root/ > /dev/null 2>&1;
    chmod +x /root/*.sh > /dev/null 2>&1;
    apt-get -y -qq install --fix-policy > /dev/null 2>&1;
    # NAT Network adapter weirdness, so give it a kick.
    ifdown eth0 > /dev/null 2>&1; ifup eth0 > /dev/null 2>&1;
    
    if [ "$HOSTNAME" = "charpentier" ];
    then
      echo -e "\e[1;31mInstalling buildserver $HOSTNAME and building production CyberChef Build\e[0m";
      /root/build_cyberchef.sh;
    fi
    
    if [ "$HOSTNAME" = "cyberchef" ];
    then
      echo -e "\e[1;31mInstalling CyberChef Virtual Webserver $HOSTNAME\e[0m";
      /root/cc-install.sh;
    fi
    /usr/bin/logger 'Bootstrap main() finished' -t 'CyberChef-bootstrap';
    /usr/bin/logger 'installation finished (Main routine finished)' -t 'CyberChef-bootstrap';
}

main;

exit 0
