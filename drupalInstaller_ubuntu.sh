#!/bin/bash 

# Making the Gui promt of mysql instalation non interactive
export DEBIAN_FRONTEND="noninteractive"
apt-get install -y debconf debconf-utils

# Provide the password on debconf-set-selections
debconf-set-selections <<< "mysql-server mysql-server/root_password password root"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password root"

apt-get install -y mysql-server mysql-client mysql-common
echo "Creating a database for drupal"
mysql -uroot -proot -e "DROP DATABASE IF EXISTS drupal;"
mysql -uroot -proot -e "CREATE DATABASE IF NOT EXISTS drupal;"

# Install all php package require for Drupal (eg :Apache2, Mysql server ,  Php7.0 ...)
echo "Downloading package for Drupal instalation"
echo "Installing Debian/Ubuntu packages..."
apt-get install -y apache2 apache2-bin apache2-data
apt-get install -y curl
apt-get install -y drush
apt-get install -y php7.0
apt-get install -y php7.0-mysql php7.0-xml
apt-get install -y php7.0-gd php7.0-mbstring
apt-get install -y libapache2-mod-php snmp
apt-get install -y libsnmp-dev php7.0-cli
apt-get install -y php7.0-curl php-mcrypt

#The following command will replace a line so that the server can access the index.php from root location
sed -i '/DirectoryIndex index.html index.cgi index.pl index.php index.xhtml index.htm/c\DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm' /etc/apache2/mods-available/dir.conf

#The following comman will set allow_url_fopen to Off in php.ini file
#sed editor is used for editing the file
echo " Modifying the php.ini file"
sed -i 's/allow_url_fopen\s*=.*/allow_url_fopen=Off/g' /etc/php/7.0/apache2/php.ini
sed -i 's/expose_php\s*=.*/expose_php=Off/g' /etc/php/7.0/apache2/php.ini

#it will add the servername name and override all permission in the virtual host
sed -i '/#ServerName www.example.com/c\\t ServerName  localhost' /etc/apache2/sites-available/000-default.conf
sed -i '13 a \\t <Directory /var/www/html/drupal>' /etc/apache2/sites-available/000-default.conf
sed -i '14 a \\t\t	AllowOverride All' /etc/apache2/sites-available/000-default.conf
sed -i '15 a \\t\t	Order allow,deny' /etc/apache2/sites-available/000-default.conf
sed -i '16 a \\t\t	Allow from all' /etc/apache2/sites-available/000-default.conf
sed -i '17 a \\t </Directory>' /etc/apache2/sites-available/000-default.conf

#setting apache url rewrite mode
echo "Setting up the Apache mod_rewrite for Drupal clean urls..."
a2enmod rewrite

#following command will download Drupal
drush -y dl --destination="/var/www/html" --drupal-project-rename="drupal"

chmod 777 -R /var/www/html/drupal/
echo "Creating new setting.php file for drupal and providing permissions"
cp /var/www/html/drupal/sites/default/default.settings.php /var/www/html/drupal/sites/default/settings.php 1>> /dev/null
mkdir /var/www/html/drupal/sites/default/files 1>> /dev/null

#restart the apache server
echo "Restarting the apache server"
systemctl restart apache2
systemctl enable apache2

# Pre-install db and site
cd /var/www/html/drupal/sites/default/
drush -y si --db-url=mysql://root:root@127.0.0.1/drupal  --account-name="dr7user" --account-pass="pa$$w0rd!" --account-mail="drupal@example.com"


echo "Instalation complete"
echo "Your database name = drupal"
echo "Your database username:password = root:root"
echo "Your drupal account username:password = dr7user:pa$$w0rd!"

echo "Access the url at = localhost/drupal"
echo "Enjoy coding"
