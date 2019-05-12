#!/bin/bash    

#EC2 user data script to run again on startup
rm /var/lib/cloud/instances/*/sem/config_scripts_user

#Update packages
apt-get update -y;

#Software installation
apt-get update -y;
apt-get install apt-transport-https -y;
apt-get install ca-certificates -y;
apt-get install curl -y;
apt-get install vim -y;
apt-get install software-properties-common -y ;

#Nginx installation
cd /tmp/ && wget http://nginx.org/keys/nginx_signing.key;
apt-key add nginx_signing.key;
sh -c "echo 'deb http://nginx.org/packages/mainline/ubuntu/ '$(lsb_release -cs)' nginx' > /etc/apt/sources.list.d/Nginx.list";
mkdir -p /var/www/html ;
apt-get update;
apt-get install nginx;
service nginx restart;

#Mysql installation
echo "mysql-server-5.7 mysql-server/root_password password root" | debconf-set-selections ;
echo "mysql-server-5.7 mysql-server/root_password_again password root" | debconf-set-selections ;
apt-get -y install mysql-server-core-5.7 mysql-server-5.7 mysql-client-5.7 ;
/etc/init.d/mysql start;

#Php-Fpm installation
LC_ALL=en_US.UTF-8 add-apt-repository ppa:ondrej/php ;
apt-get update ;
apt-get install -y php7.2-fpm php7.2-mysql ;
apt-get install -y php7.2-common php7.2-gd php7.2-curl php7.2-intl php7.2-xsl php7.2-soap php7.2-json php7.2-opcache ;
apt-get install -y php7.2-mbstring php7.2-zip php7.2-tidy php7.2-bcmath php7.2-iconv php7.2-imagick php7.2-dev php7.2-xmlrpc php7.2-xml ;
apt-get update ;
mkdir /var/run/php ;
update-rc.d php-fpm defaults
/etc/init.d/php7.2-fpm start;

#Changes in configuration files
truncate -s0 /etc/nginx/conf.d/default.conf ;

cat << EOF > /etc/nginx/conf.d/default.conf
server {
   listen 80;
   server_name default;

   root /var/www/html/;
   index index.php index.html index.htm index.nginx-debian.html;

        location ~ \.php$ {
        expires off;
        fastcgi_read_timeout 600;
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
        fastcgi_pass unix:/var/run/php/php7.2-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        }
}
EOF

sed -i '2 {s/nginx/www-data/g}' /etc/nginx/nginx.conf ;
sed -i '36 {s/run\/php\/php7.2-fpm.sock/var\/run\/php\/php7.2-fpm.sock/g}' /etc/php/7.2/fpm/pool.d/www.conf;

#Create info.php
cat << EOF > /var/www/html/info.php;
<?php
echo phpinfo();
php?>
EOF

# Set directory permission
chown -R www-data: /var/www/html ;

#Service restart
/etc/init.d/nginx restart ;
/etc/init.d/php7.2-fpm restart
