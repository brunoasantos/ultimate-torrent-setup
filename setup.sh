#!/bin/bash
export TORRENT_INSTALL_USER=htpc
export TORRENT_DATA_DIR=/data/torrent
export TORRENT_APACHE_USER=htpc

# Install prereqs
echo "Installing pre-requisites..."
sudo apt-get update
sudo apt-get install -y git-core subversion build-essential automake libtool libcppunit-dev libcurl4-openssl-dev libsigc++-2.0-dev libncurses5-dev zip rar unrar apache2 apache2-utils php5 php5-curl php5-geoip python-cheetah mediainfo libav-tools zlib1g-dev libssl-dev screen

# Download setup files from github
echo "Downloading setup files from github..."
git clone https://github.com/brunoasantos/ultimate-torrent-setup.git ~/configs

echo "##############################"
echo "# -------- rTorrent -------- #"
echo "##############################"

# Intall xmlrpc from svn
echo "Installing xmlrpc..."
cd /usr/local/src
sudo svn checkout http://svn.code.sf.net/p/xmlrpc-c/code/advanced xmlrpc-c
cd xmlrpc-c
sudo ./configure
sudo make
sudo make install

# Instal libtorrent
echo "Installing libtorrent..."
cd /usr/local/src
sudo git clone https://github.com/rakshasa/libtorrent.git
cd libtorrent
sudo ./autogen.sh
sudo ./configure
sudo make
sudo make install

# Install rTorrent
echo "Installing rtorrent..."
cd /usr/local/src
sudo git clone https://github.com/rakshasa/rtorrent.git
cd rtorrent
sudo ./autogen.sh
sudo ./configure --with-xmlrpc-c
sudo make
sudo make install
sudo ldconfig

echo "Adding configurations for rTorrent..."

# Config directory for rTorrent
mkdir -p ~/.config/rtorrent

# Create directories where torrents will be stored
sudo mkdir -p /data/torrent/{complete/{movie/couchpotato,music,tv/sickbeard,game,book,software,other},download/{movie/couchpotato,music,tv/sickbeard,game,book,software,other},watch/{movie/couchpotato,music,tv/sickbeard,game,book,software,other}} Media/{Movies,'TV Shows'}

sudo chmod -R 777 /data

# Config files and boot script
mv ~/configs/rtorrent.rc ~/.config/rtorrent/
sudo mv ~/configs/rtorrent.conf /etc/init/


echo "##############################"
echo "# -------- ruTorrent ------- #"
echo "##############################"

# Install rutorrent
su
sudo chmod +x /usr/local/bin/update-rutorrent
sudo update-rutorrent

sed -i '' "s#$topDirectory*;#$topDirectory = '/data/';#/g" /var/www/rutorrent/conf/config.php
sed -i '' "s#$saveUploadedTorrents*#$saveUploadedTorrents = false;#/g" /var/www/rutorrent/conf/config.php

sed -i '' "s#$autowatch_interval*#$autowatch_interval = 5;#/g" /var/www/rutorrent/plugins/autotools/conf.php

sed -i '' "s#$downloadpath*#$downloadpath = 'http://127.0.0.1/public/share.php';#/g" /var/www/rutorrent/plugins/fileshare/conf.php

sed -i '' "s#$pathToExternals['ffmpeg']*#$pathToExternals['ffmpeg'] = '/usr/bin/avconv';#/g" /var/www/rutorrent/plugins/screenshots/conf.php

# Configure Apache
sudo mv ~/configs/apache-portal.conf /etc/apache2/sites-available/
sudo a2dissite 000-default.conf
sudo a2ensite apache-portal.conf

sed -i '' 's/CHANGEME/livinha/g' /etc/apache2/sites-available/apache-portal.conf

sudo a2enmod rewrite request headers proxy_http auth_form session_cookie session_crypto ssl

sudo mv ~/configs/site/* /var/www/
sudo mkdir /var/www/public
sudo ln -s /var/www/rutorrent/plugins/fileshare/share.php /var/www/public/
sudo chown -R www-data:www-data /var/www/*

sudo htpasswd -c /etc/apache2/passwd htpc
