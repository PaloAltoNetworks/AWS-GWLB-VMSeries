#!/bin/bash
while true; do
if ping -c 10 8.8.8.8 &> /dev/null
then
	echo "Outbound access avaiable."
	break
else
	echo "Waiting for Outbound access..."
	sleep 20
fi
done
sudo apt-get update &&
sudo apt-get install -y apache2 php7.0 &&
sudo apt-get install -y libapache2-mod-php7. &&
sudo rm -f /var/www/html/index.html &&
sudo wget -O /var/www/html/index.php https://raw.githubusercontent.com/wwce/Scripts/master/showheaders.php &&
sudo dd if=/dev/zero of=100M count=10240 bs=10240 &&
sudo service apache2 restart &&
sudo echo "Web Server Ready"
