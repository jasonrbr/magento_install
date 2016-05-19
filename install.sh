# user inputs
echo "enter apache config filename (without .conf)"
read apache_filename
apache_filename="$apache_filename.conf"
#echo "$apache_filename"

echo "enter magento installation directory"
read install_dir
#echo "$install_dir"


sudo apt-get update
sudo apt-get install lamp-server^ libcurl3 php7.0-curl php7.0-gd php7.0-mcrypt php-mbstring php-zip php-dom php-intl

sudo curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

#changing php memory limit sudo sed -i s/memory_limit.*$/memory_limit\ =\ 512M/ /etc/php/7.0/apache2/php.ini

# add apache conf file

sudo echo "<VirtualHost *:80>" > /etc/apache2/sites-available/$apache_filename
sudo echo "  DocumentRoot $install_dir" >> /etc/apache2/sites-available/$apache_filename
sudo echo "  <Directory $install_dir/>" >> /etc/apache2/sites-available/$apache_filename
sudo echo "    Options Indexes FollowSymLinks MultiViews" >> /etc/apache2/sites-available/$apache_filename
sudo echo "    AllowOverride All" >> /etc/apache2/sites-available/$apache_filename
sudo echo "  </Directory>" >> /etc/apache2/sites-available/$apache_filename
sudo echo "</VirtualHost>" >> /etc/apache2/sites-available/$apache_filename

## enable apache2 site
sudo a2ensite $apache_filename
#TODO: do this
sudo a2dissite 000-default.conf
# remove current site
echo "enter current http site conf name (with the extension)"
read victim_site

sudo a2dissite $victim_site

sudo a2enmod rewrite
sudo phpenmod mcrypt

echo "Enter database name"
read db_name

echo "Enter name of database user"
read db_user

echo "Enter password of database user"
read db_password

echo ""
echo "When prompted, enter mysql root user password"
#TODO: make the password check thing
#echo "confirm the above password"
#read db_password2
#if ($db_password == $db_password2) {
#  # do the db password thing again
#}

# create SQL tables & a user

sudo mysql -u root -p -e "CREATE DATABASE $db_name; CREATE USER $db_user@localhost IDENTIFIED BY '$db_password'; GRANT ALL PRIVILEGES ON $db_name.* TO $db_user@localhost IDENTIFIED BY '$db_password'; FLUSH PRIVILEGES;"
echo "Database created"

echo ""
# setup a magento user
echo "Enter the magento username"
read mage_user

sudo adduser $mage_user

echo "User created"

sudo usermod -g www-data $mage_user 
echo "User permissions set"

# install magento
echo ""
echo "Begin installation"

sudo git clone -b 2.0.6 https://github.com/magento/magento2.git $install_dir
cd $install_dir
sudo composer install
sudo chown -R $mage_user:www-data $install_dir
sudo chmod g+ws -R $install_dir
sudo chmod u+x $install_dir/bin/magento

sudo service apache2 restart

su $mage_user -c $install_dir/bin/magento setup:install --admin-firstname=Jon --admin-lastname=Smith --admin-email=admin@admin.com --admin-user=admin --admin-password='admin123' --base-url=http://127.0.0.1/ --backend-frontname=admin --db-host=localhost --db-name=$db_name --db-user=$db_user --db-password="$db_password" --timezone=America/Detroit
