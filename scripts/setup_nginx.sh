#!/bin/bash

###########################################################
## Configuration nginx
###########################################################
sudo apt-get install nginx # install nginx

# overwrites user
nginx_conf=/etc/nginx/nginx.conf
sudo sed -i '1cuser root;' $nginx_conf

# create conf file
django_conf=/etc/nginx/sites-available/django.conf
sudo bash -c "cat >$django_conf <<DJANGO_CONF
server {
listen 80;
server_name 54.167.248.70 EC-Django-Deploy.net www.EC-Django-Deploy.net;
location = /favicon.ico { access_log off; log_not_found off; }
location /static/ {
    root /home/ubuntu/EC-Django-Deploy;
}

location /media/ {
    root /home/ubuntu/EC-Django-Deploy;
}

location / {
    include proxy_params;
    proxy_pass http://unix:/run/gunicorn.sock;
}
}
DJANGO_CONF"

#  Creat link in sites-enabled directory
sudo ln -sf /etc/nginx/sites-available/django.conf /etc/nginx/sites-enabled

# restart nginx
sudo nginx -t
sudo systemctl restart nginx
# read -p "Press Enter to continue..."
