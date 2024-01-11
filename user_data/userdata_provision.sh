#!/bin/bash
# Program Name: userdata_provision.sh
# Author name: Wenhao Fang
# Date Created: Oct 21th 2023
# Date Created: Jan 10th 2024
# Repo: AWS_EC2_ECDjangoDeploy
# Project: EC_Django_Deployer
# Description of the script:
#   user data script to deploy a django project

# Create provision.log
sudo rm -f /home/ubuntu/provision.log
touch /home/ubuntu/provision.log

###########################################################
## Clone github repo
###########################################################
# remove existings github repo dir
sudo rm -rf /home/ubuntu/AWS_EC2_ECDjangoDeploy/
# create dir for github repo
mkdir /home/ubuntu/AWS_EC2_ECDjangoDeploy/

# clone github repo
git clone https://github.com/simonangel-fong/AWS_EC2_ECDjangoDeploy.git /home/ubuntu/AWS_EC2_ECDjangoDeploy &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Git - Clone github repo." >>/home/ubuntu/provision.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Git - Clone github repo." >>/home/ubuntu/provision.log

###########################################################
## Update project dependencies
###########################################################
source /home/ubuntu/env/bin/activate
pip install -r /home/ubuntu/AWS_EC2_ECDjangoDeploy/requirements.txt &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Pip - Install project dependencies." >>/home/ubuntu/provision.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Pip - Install project dependencies." >>/home/ubuntu/provision.log
deactivate

###########################################################
## Configuration gunicorn
###########################################################

sudo bash -c "sudo cat >/etc/systemd/system/gunicorn.socket <<SOCK
[Unit]
Description=gunicorn socket

[Socket]
ListenStream=/run/gunicorn.sock

[Install]
WantedBy=sockets.target
SOCK" &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Gunicorn - Create gunicorn.socket." >>/home/ubuntu/provision.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Gunicorn - Create gunicorn.socket." >>/home/ubuntu/provision.log

sudo bash -c "sudo cat >/etc/systemd/system/gunicorn.service <<SERVICE
[Unit]
Description=gunicorn daemon
Requires=gunicorn.socket
After=network.target

[Service]
User=root
Group=www-data 
WorkingDirectory=/home/ubuntu/EC_Django_Deployer
ExecStart=/home/ubuntu/env/bin/gunicorn \
    --access-logfile - \
    --workers 3 \
    --bind unix:/run/gunicorn.sock \
    EC_Django_Deployer.wsgi:application

[Install]
WantedBy=multi-user.target
SERVICE" &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Gunicorn - Create gunicorn.service." >>/home/ubuntu/provision.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Gunicorn - Create gunicorn.service." >>/home/ubuntu/provision.log

###########################################################
## Apply gunicorn configuration
###########################################################
sudo systemctl daemon-reload          # reload daemon
sudo systemctl start gunicorn.socket  # Start gunicorn
sudo systemctl enable gunicorn.socket # enable on boots
sudo systemctl restart gunicorn       # restart gunicorn

###########################################################
## Configuration nginx
###########################################################

# overwrites user
sudo sed -i '1cuser root;' /etc/nginx/nginx.conf &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Nginx - overwrites user." >>/home/ubuntu/provision.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Nginx - overwrites user." >>/home/ubuntu/provision.log

# create conf file
sudo bash -c "cat >/etc/nginx/sites-available/django.conf <<DJANGO_CONF
server {
listen 80;
server_name $(curl -s https://api.ipify.org);
location = /favicon.ico { access_log off; log_not_found off; }
location /static/ {
    root /home/ubuntu/AWS_EC2_ECDjangoDeploy/demoDjango;
}

location /media/ {
    root /home/ubuntu/AWS_EC2_ECDjangoDeploy/demoDjango;
}

location / {
    include proxy_params;
    proxy_pass http://unix:/run/gunicorn.sock;
}
}
DJANGO_CONF" &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Nginx - create conf filer." >>/home/ubuntu/provision.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Nginx - create conf filer." >>/home/ubuntu/provision.log

#  Creat link in sites-enabled directory
sudo ln -sf /etc/nginx/sites-available/django.conf /etc/nginx/sites-enabled &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Nginx - Creat link in sites-enabledr." >>/home/ubuntu/provision.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Nginx - Creat link in sites-enabledr." >>/home/ubuntu/provision.log

# restart nginx
sudo nginx -t
sudo systemctl restart nginx

###########################################################
## Configuration supervisor
###########################################################
# create directory for logging
sudo mkdir -p /var/log/gunicorn
# create configuration file
sudo bash -c "cat >/etc/supervisor/conf.d/gunicorn.conf  <<SUP_GUN
[program:gunicorn]
    directory=/home/ubuntu/AWS_EC2_ECDjangoDeploy/demoDjango
    command=/home/ubuntu/env/bin/gunicorn --workers 3 --bind unix:/run/gunicorn.sock  demoDjango.wsgi:application
    autostart=true
    autorestart=true
    stderr_logfile=/var/log/gunicorn/gunicorn.err.log
    stdout_logfile=/var/log/gunicorn/gunicorn.out.log

[group:guni]
    programs:gunicorn
SUP_GUN" &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Supervisor - create directory for logging." >>/home/ubuntu/provision.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Supervisor - create directory for logging." >>/home/ubuntu/provision.log

sudo systemctl daemon-reload
sudo supervisorctl reread # tell supervisor read configuration file
sudo supervisorctl update # update supervisor configuration
sudo supervisorctl reload # Restarted supervisord

###########################################################
## Django Migrate
###########################################################
# django make migrations
python3 manage.py makemigrations &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Django - make migrations." >>/home/ubuntu/provision.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Django - make migrations." >>/home/ubuntu/provision.log

# django migrate
python3 manage.py migrate &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Django - migrate." >>/home/ubuntu/provision.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Django - migrate." >>/home/ubuntu/provision.log

# django collect static files
python3 manage.py collectstatic &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Django - collect static files." >>/home/ubuntu/provision.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Django - collect static files." >>/home/ubuntu/provision.log

# restart gunicorn
sudo service gunicorn restart &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Gunicorn - restart service." >>/home/ubuntu/provision.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Gunicorn - restart service." >>/home/ubuntu/provision.log

# restart nginx
sudo service nginx restart &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Nginx - restart service." >>/home/ubuntu/provision.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Nginx - restart service." >>/home/ubuntu/provision.log

# log finish deployment
echo -e "$(date +'%Y-%m-%d %H:%M:%S') Provision completed." >>/home/ubuntu/provision.log
