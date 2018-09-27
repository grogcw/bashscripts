#!/bin/bash

### EXECUTE THIS SCRIPT AS ROOT ###
### EXECUTE THIS SCRIPT AS ROOT ###
### EXECUTE THIS SCRIPT AS ROOT ###

### IF YOU WANT TO REMOVE CLOUD-INIT COPY PASTE THIS WITHOT THE # AT THE BEGGINING ###
# echo 'datasource_list: [ None ]' | sudo -s tee /etc/cloud/cloud.cfg.d/90_dpkg.cfg
# apt purge cloud-init
# rm -rf /etc/cloud/; sudo rm -rf /var/lib/cloud/

### PUSH DEFAULT REPOSITORIES ###

cat << 'EOL' >> /etc/apt/sources.list

#deb cdrom:[Ubuntu 18.04 LTS _Bionic Beaver_ - Release amd64 (20180426)]/ bionic main restricted

# See http://help.ubuntu.com/community/UpgradeNotes for how to upgrade to
# newer versions of the distribution.
deb http://in.archive.ubuntu.com/ubuntu/ bionic main restricted
# deb-src http://in.archive.ubuntu.com/ubuntu/ bionic main restricted

## Major bug fix updates produced after the final release of the
## distribution.
deb http://in.archive.ubuntu.com/ubuntu/ bionic-updates main restricted
# deb-src http://in.archive.ubuntu.com/ubuntu/ bionic-updates main restricted

## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu
## team. Also, please note that software in universe WILL NOT receive any
## review or updates from the Ubuntu security team.
deb http://in.archive.ubuntu.com/ubuntu/ bionic universe
# deb-src http://in.archive.ubuntu.com/ubuntu/ bionic universe
deb http://in.archive.ubuntu.com/ubuntu/ bionic-updates universe
# deb-src http://in.archive.ubuntu.com/ubuntu/ bionic-updates universe

## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu
## team, and may not be under a free licence. Please satisfy yourself as to
## your rights to use the software. Also, please note that software in
## multiverse WILL NOT receive any review or updates from the Ubuntu
## security team.
deb http://in.archive.ubuntu.com/ubuntu/ bionic multiverse
# deb-src http://in.archive.ubuntu.com/ubuntu/ bionic multiverse
deb http://in.archive.ubuntu.com/ubuntu/ bionic-updates multiverse
# deb-src http://in.archive.ubuntu.com/ubuntu/ bionic-updates multiverse

## N.B. software from this repository may not have been tested as
## extensively as that contained in the main release, although it includes
## newer versions of some applications which may provide useful features.
## Also, please note that software in backports WILL NOT receive any review
## or updates from the Ubuntu security team.
deb http://in.archive.ubuntu.com/ubuntu/ bionic-backports main restricted universe multiverse
# deb-src http://in.archive.ubuntu.com/ubuntu/ bionic-backports main restricted universe multiverse

## Uncomment the following two lines to add software from Canonical's
## 'partner' repository.
## This software is not part of Ubuntu, but is offered by Canonical and the
## respective vendors as a service to Ubuntu users.
# deb http://archive.canonical.com/ubuntu bionic partner
# deb-src http://archive.canonical.com/ubuntu bionic partner

deb http://security.ubuntu.com/ubuntu bionic-security main restricted
# deb-src http://security.ubuntu.com/ubuntu bionic-security main restricted
deb http://security.ubuntu.com/ubuntu bionic-security universe
# deb-src http://security.ubuntu.com/ubuntu bionic-security universe
deb http://security.ubuntu.com/ubuntu bionic-security multiverse
# deb-src http://security.ubuntu.com/ubuntu bionic-security multiverse

deb https://download.webmin.com/download/repository sarge contrib

EOL

### WEBMIN ###
wget http://www.webmin.com/jcameron-key.asc
apt-key add jcameron-key.asc
rm jcameron-key.asc

### UPDATE APT FOR UPCOMING EVENTS ###
apt update

### UPGRADE EXISTING PACKAGES ###
apt upgrade

### RECONFIGURE LOCALES ###
apt install language-pack-fr -qy
locale-gen fr_FR.UTF-8
dpkg-reconfigure locales

### INSTALL CERTBOT ###
apt install software-properties-common
add-apt-repository ppa:certbot/certbot
apt update

### INSTALL SERVERS & DEFAULT PACKAGES ###
apt install build-essential git autotools-dev autoconf libtool gettext gawk gperf \
  antlr3 libantlr3c-dev libconfuse-dev libunistring-dev libsqlite3-dev \
  libavcodec-dev libavformat-dev libavfilter-dev libswscale-dev libavutil-dev \
  libasound2-dev libmxml-dev libgcrypt11-dev libavahi-client-dev zlib1g-dev \
  libevent-dev libplist-dev libsodium-dev libjson-c-dev libwebsockets-dev \
  apache2 php7.2-fpm mysql-server postgresql perl libnet-ssleay-perl openssl \
  libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions python \
  gnutls-bin gnutls-dev libprotobuf-c-dev libcurl4-gnutls-dev \
  libsodium-dev libwebsockets-dev libpulse-dev libapache2-mod-perl2 \
  libapache2-mod-scgi php7.2-dev php7.2-xml php-dev php-pear libmcrypt-dev \
  icecast2 liquidsoap gcc make autoconf libc-dev pkg-config libmcrypt-dev \
  wget unzip php7.2-mysql libapache2-mod-php7.2 php7.2-mbstring php7.2-curl \
  perl libnet-ssleay-perl openssl libauthen-pam-perl libpam-runtime libio-pty-perl \
  apt-transport-https apt-show-versions python webmin parted rename locate \
  php7.2-zip php7.2-gd htop mc screen unzip git zsh samba samba-client ntfs-3g -qy

### INSTALL PHP 7.2 MCRYPT ###
pecl install mcrypt-1.0.1

bash -c "echo extension=/usr/lib/php/20170718/mcrypt.so > /etc/php/7.2/cli/conf.d/mcrypt.ini"
bash -c "echo extension=/usr/lib/php/20170718/mcrypt.so > /etc/php/7.2/apache2/conf.d/mcrypt.ini"

### ENABLE ALL MODS ###
a2enmod access_compat alias auth_basic authn_core authn_file authz_core authz_groupfile authz_host authz_user autoindex cgi deflate dir env filter headers mime mpm_prefork negotiation perl php7.2 proxy proxy_fcgi proxy_http reqtimeout rewrite scgi setenvif socache_shmcb ssl status

### RESTART WEBSERVICES ###
echo "Restarting Mysql"
$(systemctl restart mysql)
echo "Restarting PHP7.2-FPM"
$(systemctl restart php7.2-fpm)
echo "Apache2"
$(systemctl restart apache2)

touch /var/www/html/phpinfo.php
cat << 'EOL' >> /var/www/html/phpinfo.php

<?php

// Affiche toutes les informations, comme le ferait INFO_ALL
phpinfo();

// Affiche uniquement le module d'information.
// phpinfo(8) fournirait les mêmes informations.
phpinfo(INFO_MODULES);

?>

EOL

### INSTALL OHMYZSH ###

sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

mkdir ~/.oh-my-zsh/custom/themes/
touch ~/.oh-my-zsh/custom/themes/robbyrussell.zsh-theme

FILE="~/.oh-my-zsh/custom/themes/robbyrussell.zsh-theme"

cat << 'EOL' >> ~/.oh-my-zsh/custom/themes/robbyrussell.zsh-theme

local ret_status="%(?:%{$fg_bold[green]%}➜ :%{$fg_bold[red]%}➜ )"
PROMPT='%(!.%{%F{white}%}.)$USER@%{$fg[white]%}%M %{$fg_bold[red]%}➜ %{$fg_bold[green]%}%p %{$fg[cyan]%}%c %{$fg_bold[blue]%}$(git_prompt_info)%{$fg_bold[blue]%}% %{$reset_color%}'

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[blue]%}git:(%{$fg[red]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[blue]%}) %{$fg[yellow]%}✗"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[blue]%})"

EOL


### DOWNLOAD GOGS ###
$(cd /root)
$(wget https://dl.gogs.io/0.11.66/gogs_0.11.66_linux_amd64.tar.gz)
$(tar -zxf gogs_0.11.66_linux_amd64.tar.gz)
rm gogs_0.11.66_linux_amd64.tar.gz

### GIT CLONE & INSTALL FORKED DAAPD ###
$(git clone https://github.com/ejurgensen/forked-daapd.git)
echo "------------------------------------------------------------------"
echo ""
echo "In order to compile forked-daapd, please type the following : "
echo ""
echo "cd forked-daapd"
echo "autoreconf -i"
echo "./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --with-pulseaudio --with-libwebsockets --enable-chromecast"
echo "make"
echo "make install"
echo "cd .."
echo "------------------------------------------------------------------"
