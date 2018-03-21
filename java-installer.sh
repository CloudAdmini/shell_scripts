#!/bin/bash

# Start of the script
echo
echo Ubuntu Java Installer
echo

# Check what options were provided
JDK_ARCHIVE=""
OPTS=`getopt -q -o '' -l -- "$@"`
while true; do
   case "$1" in
      -- ) shift; break ;;
      -* ) echo "Unrecognized option $1"
           echo
           exit 1;;
      * ) JDK_ARCHIVE=$1; break ;;
   esac
done

# Check if the script is running with root permissions
if [ `id -u` -ne 0 ]; then
   echo "The script must be run as root! (you can use sudo)"
   exit 1
fi


#   Is the file containing JDK?
#   Also obtain JDK version using the occassion
JDK_VERSION=`tar -tf $JDK_ARCHIVE | egrep '^[^/]+/$' | head -c -2` 2>> /dev/null
if [[ $JDK_VERSION != "jdk"* ]]; then
   echo "FAILED"
   echo
   echo "The provided archive does not contain JDK: $JDK_ARCHIVE"
   echo
   echo "Please provide valid JDK archive from Oracle Website"
   echo $ORACLE_DOWNLOAD_LINK
   echo
   exit 1
fi
echo "OK"


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

# Verify and exit installation
echo -n "Verifying Java installation... "
JAVA_CHECK=`java -version 2>&1`
if [[ "$JAVA_CHECK" == *"Java(TM) SE Runtime Environment"* ]]; then
   echo "OK"
   echo
   echo "Java is successfully installed!"
   echo
   java -version
   echo
   exit 0
else
   echo "FAILED"
   echo
   echo "Java installation failed!"
   echo
   exit 1
fi
