#!/bin/bash

# Start of the Java installation
echo
echo Java Installation
echo

# Check if the script is running with root permissions
if [ `id -u` -ne 0 ]; then
   echo "The script must be run as root! (you can use sudo)"
   exit 1
fi

# Check what options were provided
JDK_link=$1
wget --no-check-certificate -c --header "Cookie: oraclelicense=accept-securebackup-cookie" $JDK_link &>> /dev/null
JDK_ARCHIVE=`ls jdk-*.tar.gz`

# Obtain JDK version using the occassion
JDK_VERSION=`tar -tf $JDK_ARCHIVE | egrep '^[^/]+/$' | head -c -2` 2>> /dev/null

# Begin Java installation

# Extract the archive
echo -n "Extracting the archive... "
JDK_LOCATION=/usr/local/java/$JDK_VERSION
mkdir -p /usr/local/java
tar -xf $JDK_ARCHIVE -C /usr/local/java
echo "OK"

# Update /etc/profile
echo -n "Updating /etc/profile ... "
cat >> /etc/profile <<EOF
JAVA_HOME=$JDK_LOCATION
JRE_HOME=$JDK_LOCATION/jre
PATH=$PATH:$JDK_LOCATION/bin:$JDK_LOCATION/jre/bin
export JAVA_HOME
export JRE_HOME
export PATH
EOF
echo "OK"

# Update system to use Oracle Java by default
echo -n "Updating system alternatives... "
update-alternatives --install "/usr/bin/java" "java" "$JDK_LOCATION/jre/bin/java" 1 >> /dev/null
update-alternatives --install "/usr/bin/javac" "javac" "$JDK_LOCATION/bin/javac" 1 >> /dev/null
update-alternatives --set java $JDK_LOCATION/jre/bin/java >> /dev/null
update-alternatives --set javac $JDK_LOCATION/bin/javac >> /dev/null
echo "OK"

# Verify installation
echo -n "Verifying Java installation... "
JAVA_CHECK=`java -version 2>&1`
if [[ "$JAVA_CHECK" == *"Java(TM) SE Runtime Environment"* ]]; then
   echo "OK"
   echo
   echo "Java is successfully installed!"
   echo
   JAVA_VERSION=`java -version  2>&1`
   echo  "Your Java Infos : "
   echo $JAVA_VERSION 
   echo

   # Remove archive file
   rm -rf jdk-*.tar.gz

else
   echo "FAILED"
   echo
   echo "Java installation failed!"
   echo
   exit 1
fi




# Start of the Apache and Drupal installation
echo
echo Apache and Drupal Installation
echo

# Making the Gui promt of mysql instalation non interactive
export DEBIAN_FRONTEND="noninteractive " 
apt-get install -y debconf debconf-utils &>> /dev/null

# Provide the password on debconf-set-selections
echo -n "Installing and setting up MySQL Database... "
debconf-set-selections <<< "mysql-server mysql-server/root_password password root" &>> /dev/null
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password root" &>> /dev/null
apt-get install -y mysql-server mysql-client mysql-common &>> /dev/null
echo "OK"

echo -n "Creating drupal Database... "
mysql -uroot -proot -e "DROP DATABASE IF EXISTS drupal;" &>> /dev/null
mysql -uroot -proot -e "CREATE DATABASE IF NOT EXISTS drupal;" &>> /dev/null
echo "OK"

# Install all php package require for Drupal (eg :Apache2, Mysql server ,  Php7.0 ...)
echo -n "Installing the required packages for drupal... "
apt-get install -y apache2 apache2-bin apache2-data &>> /dev/null
apt-get install -y curl &>> /dev/null
apt-get install -y drush &>> /dev/null
apt-get install -y php7.0 &>> /dev/null
apt-get install -y php7.0-mysql php7.0-xml &>> /dev/null
apt-get install -y php7.0-gd php7.0-mbstring &>> /dev/null
apt-get install -y libapache2-mod-php snmp &>> /dev/null
apt-get install -y libsnmp-dev php7.0-cli &>> /dev/null
apt-get install -y php7.0-curl php-mcrypt &>> /dev/null
echo "OK"

# It will add the servername name and override all permission in the virtual host
echo -n "Setting up Apache Server for drupal... "
sed -i '/#ServerName www.example.com/c\\t ServerName  localhost' /etc/apache2/sites-available/000-default.conf
sed -i '13 a \\t <Directory /var/www/html/drupal>' /etc/apache2/sites-available/000-default.conf
sed -i '14 a \\t\t	AllowOverride All' /etc/apache2/sites-available/000-default.conf
sed -i '15 a \\t\t	Order allow,deny' /etc/apache2/sites-available/000-default.conf
sed -i '16 a \\t\t	Allow from all' /etc/apache2/sites-available/000-default.conf
sed -i '17 a \\t </Directory>' /etc/apache2/sites-available/000-default.conf

# Setting apache url rewrite mode
a2enmod rewrite &>> /dev/null
echo "OK"

# Following command will download Drupal
echo -n "Downloading drupal packages to /var/www/html/drupal... "
drush -y dl --destination="/var/www/html" --drupal-project-rename="drupal" &>> /dev/null
cp /var/www/html/drupal/sites/default/default.settings.php /var/www/html/drupal/sites/default/settings.php &>> /dev/null
mkdir /var/www/html/drupal/sites/default/files &>> /dev/null
echo "OK"

# Restart the apache server
systemctl restart apache2 &>> /dev/null

# Pre-install db and site
echo -n "Setting up drupal site configuration... "
cd /var/www/html/drupal/sites/default/
drush -y si --db-url=mysql://root:root@127.0.0.1/drupal  --account-name="root" --account-pass="root" --account-mail="drupal@example.com" &>> /dev/null
echo "OK"

echo 
echo "Instalation complete"
echo "Your database name = drupal"
echo "Your drupal/DB username = root"
echo "Your drupal/DB password = root"
echo "Access the url at = localhost/drupal"
echo "Enjoy coding"
