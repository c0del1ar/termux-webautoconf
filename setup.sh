#!/usr/bin/bash

source vars.sh
source func.sh

echo -e "$info Hello, setting up your server.."

printf "$quest Do you wanna install phpmyadmin? (y/N): "
read phpmyadmin_is

printf "$quest Do you wanna install mysql? (y/N): "
read mysql_is

echo -e "$info Installing dependencies.."

pkg i php apache2 php-apache -y

if [[ `echo "$phpmyadmin_is" | tr '[:upper:]' '[:lower:]'` == "y" ]]
then
	is_phpmyadmin=0
	pkg i phpmyadmin -y
fi

if [[ `echo "$mysql_is" | tr '[:upper:]' '[:lower:]'` == "y" ]]
then
	is_mariadb=0
	pkg i mariadb -y
fi

# apache configuration
echo -e "$info configuring httpd.conf"
cnf=$PREFIX/etc/apache2/httpd.conf
edit_content '#' '' 66 "$cnf"
edit_content '.*' "#$(get_content 67 "$cnf")" 67 "$cnf"
edit_content '#' '' 504 "$cnf"
edit_content 'denied' 'granted' 230 "$cnf"
add_content 'LoadModule php_module libexec/apache2/libphp.so \
Addhandler php-script .php 
' 180 "$cnf"
edit_content '\\' '' 180 "$cnf"

if ! is_storage
then
	echo -e "$warn Required storage permission"
	termux-setup-storage
fi
	
cnf=$PREFIX/etc/apache2/extra/httpd-vhosts.conf
printf "$quest Where (path) your website will running? (~/myweb): "
read mypath

if [ ! $mypath == '' ]
then
	webpath=$(path_parse "$mypath")
else
	webpath="$HOME/myweb"
fi

if [ ! -d "$webpath" ]
then
	mkdir -p $webpath
fi

edit_content '".*"' "\"$webpath\"" 25 $cnf
edit_content 'dummy.*' 'localhost' 26 $cnf

touch $PREFIX/etc/apache2/extra/php_module.conf

# phpmyadmin configuration
if [ $is_phpmyadmin ]
then
	echo -e "$info configuring phpmyadmin.."
	edit_content '".*"' "\"$PREFIX\/share\/phpmyadmin\"" 34 $cnf
	edit_content 'dummy.*' '0\.0\.0\.0' 35 $cnf
	cnf=$PREFIX/etc/phpmyadmin/config.inc.php
	edit_content 'localhost' 'localhost:3306' 30 $cnf
fi

# mysql and mariadb configuration
if [ $is_mariadb ]
then
	echo -e "$info configuring mariadb connection.."
	printf "$quest Your username for mysql: "
	read usrname
	printf "$quest Password for $usrname: "
	read -s passwd
	echo -e "$warn Running mariadb server.."
	mariadbd &
	sleep 5
	echo
	echo | mariadb -u root -p -h localhost -e "CREATE USER '$usrname'@'localhost'
IDENTIFIED BY '$passwd';
GRANT ALL PRIVILEGES ON * . * TO '$usrname'@'localhost';
FLUSH PRIVILEGES;"
	killall mariadbd
	echo
fi

echo -e "$info It's done!"
echo -e "$warn Test httpd."
httpd -t

echo -e "$info Run apache server : ${W}httpd${reset} or ${W}apachectl${reset}"
echo -e "$info Run mariadb server : ${W}mariadbd${reset}"
echo -e "$info This configuration is based on this tutorial:
https://blog.d4rk5idehacker.or.id/2022/06/membuat-web-server-apache-php-mysql-di.html"