#!/usr/bin/bash

apt purge apache2 mariadb -y
rm '/data/data/com.termux/files/usr/etc/apache2/extra' -fvr
