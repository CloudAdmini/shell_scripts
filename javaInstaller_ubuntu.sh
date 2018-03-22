wget --no-check-certificate -c --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u161-b12/2f38c3b165be4555a1fa6e98c45e0808/jdk-8u161-linux-x64.tar.gz
wget https://raw.githubusercontent.com/CloudAdmini/shell_scripts/master/java-installer.sh
chmod +x java-installer.sh
./java-installer.sh jdk-*.tar.gz >> java-output
rm -rf jdk-*.tar.gz java-installer.sh
