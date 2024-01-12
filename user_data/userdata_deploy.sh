#!/bin/bash
# Program Name: userdata_deploy.sh
# Author name: Wenhao Fang
# Date Created: Oct 21th 2023
# Date Created: Jan 10th 2024
# Repo: AWS_ECDjangoDeployer
# Project: EC_Django_Deployer
# Description of the script:
#   user data script to deploy a django project

# Check if the log folder exists, and create it if not
if [ ! -d "/home/ubuntu/log" ]; then
    mkdir -p "/home/ubuntu/log"
fi

# Remove the old log file if it exists
if [ -f "/home/ubuntu/log/deploy.log" ]; then
    rm -f "/home/ubuntu/log/deploy.log"
fi

# Create a new log file
touch "/home/ubuntu/log/deploy.log"

# Log start CICD BeforeInstall
echo -e "$(date +'%Y-%m-%d %H:%M:%S') Deployment starting..." >>"/home/ubuntu/log/deploy.log"

###########################################################
## Clear existing dir and files
###########################################################
# Check if the env folder exists
if [ -d "/home/ubuntu/env" ]; then
    # Remove the existing env folder and its contents
    rm -rf "/home/ubuntu/env" &&
        echo -e "$(date +'%Y-%m-%d %H:%M:%S') Remove existing env." >>"/home/ubuntu/log/deploy.log" ||
        echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Remove existing env." >>"/home/ubuntu/log/deploy.log"
else
    # Log a message if the env folder doesn't exist
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') No existing env to remove." >>"/home/ubuntu/log/deploy.log"
fi

# Check if the AWS_ECDjangoDeployer folder exists
if [ -d "/home/ubuntu/AWS_ECDjangoDeployer" ]; then
    # Remove the existing AWS_ECDjangoDeployer folder
    rm -rf "/home/ubuntu/AWS_ECDjangoDeployer" &&
        echo -e "$(date +'%Y-%m-%d %H:%M:%S') Remove existing repo." >>"/home/ubuntu/log/deploy.log" ||
        echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Remove existing repo." >>"/home/ubuntu/log/deploy.log"
else
    # Log a message if the AWS_ECDjangoDeployer folder doesn't exist
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') No existing repo to remove." >>"/home/ubuntu/log/deploy.log"
fi

###########################################################
## Clone github repo
###########################################################
# create dir for github repo
mkdir /home/ubuntu/AWS_ECDjangoDeployer/

# clone github repo
git clone https://github.com/simonangel-fong/AWS_ECDjangoDeployer.git /home/ubuntu/AWS_ECDjangoDeployer &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Git - Clone github repo." >>/home/ubuntu/log/deploy.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Git - Clone github repo." >>/home/ubuntu/log/deploy.log

###########################################################
## Install gunicorn package within venv
###########################################################
# Creates virtual environment
python3 -m venv /home/ubuntu/env &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') VENV - Create virtual environment." >>"/home/ubuntu/log/deploy.log" ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: VENV - Create virtual environment." >>"/home/ubuntu/log/deploy.log"

###########################################################
## Update project dependencies
###########################################################
# Check if requirements.txt exists
if [ -f "/home/ubuntu/AWS_ECDjangoDeployer/requirements.txt" ]; then
    source /home/ubuntu/env/bin/activate
    pip install -r /home/ubuntu/AWS_ECDjangoDeployer/requirements.txt &&
        echo -e "$(date +'%Y-%m-%d %H:%M:%S') Pip - Install project dependencies." >>/home/ubuntu/log/deploy.log ||
        echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Pip - Install project dependencies." >>/home/ubuntu/log/deploy.log
    deactivate
else
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Pip - No dependency to be installed." >>/home/ubuntu/log/deploy.log
fi

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
    sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') Gunicorn - Create gunicorn.socket." >>"/home/ubuntu/log/deploy.log" ||
    sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Gunicorn - Create gunicorn.socket." >>"/home/ubuntu/log/deploy.log"

sudo bash -c "sudo cat >/etc/systemd/system/gunicorn.service <<SERVICE
[Unit]
Description=gunicorn daemon
Requires=gunicorn.socket
After=network.target

[Service]
User=root
Group=www-data 
WorkingDirectory=/home/ubuntu/AWS_ECDjangoDeployer/EC_Django_Deployer
ExecStart=/home/ubuntu/env/bin/gunicorn \
    --access-logfile - \
    --workers 3 \
    --bind unix:/run/gunicorn.sock \
    EC_Django_Deployer.wsgi:application

[Install]
WantedBy=multi-user.target
SERVICE" &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Gunicorn - Create gunicorn.service." >>"/home/ubuntu/log/deploy.log" ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Gunicorn - Create gunicorn.service." >>"/home/ubuntu/log/deploy.log"

###########################################################
## Apply gunicorn configuration
###########################################################
systemctl daemon-reload          # reload daemon
systemctl start gunicorn.socket  # Start gunicorn
systemctl enable gunicorn.socket # enable on boots
systemctl restart gunicorn       # restart gunicorn

###########################################################
## Configuration nginx
###########################################################

# overwrites user
sed -i '1cuser root;' /etc/nginx/nginx.conf &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Nginx - overwrites user." >>/home/ubuntu/log/deploy.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Nginx - overwrites user." >>/home/ubuntu/log/deploy.log

# create conf file
sudo bash -c "cat >/etc/nginx/sites-available/django.conf <<DJANGO_CONF
server {
listen 80;
server_name $(curl -s https://api.ipify.org);
location = /favicon.ico { access_log off; log_not_found off; }
location /static/ {
    root /home/ubuntu/AWS_ECDjangoDeployer/EC_Django_Deployer;
}

location /media/ {
    root /home/ubuntu/AWS_ECDjangoDeployer/EC_Django_Deployer;
}

location / {
    include proxy_params;
    proxy_pass http://unix:/run/gunicorn.sock;
}
}
DJANGO_CONF" &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Nginx - create conf filer." >>/home/ubuntu/log/deploy.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Nginx - create conf filer." >>/home/ubuntu/log/deploy.log

#  Creat link in sites-enabled directory
ln -sf /etc/nginx/sites-available/django.conf /etc/nginx/sites-enabled &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Nginx - Creat link in sites-enabledr." >>/home/ubuntu/log/deploy.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Nginx - Creat link in sites-enabledr." >>/home/ubuntu/log/deploy.log

# restart nginx
nginx -t
systemctl restart nginx

###########################################################
## Configuration supervisor
###########################################################
# create directory for logging
mkdir -p /var/log/gunicorn
# create configuration file
sudo bash -c "cat >/etc/supervisor/conf.d/gunicorn.conf  <<SUP_GUN
[program:gunicorn]
    directory=/home/ubuntu/AWS_ECDjangoDeployer/EC_Django_Deployer
    command=/home/ubuntu/env/bin/gunicorn --workers 3 --bind unix:/run/gunicorn.sock  EC_Django_Deployer.wsgi:application
    autostart=true
    autorestart=true
    stderr_logfile=/var/log/gunicorn/gunicorn.err.log
    stdout_logfile=/var/log/gunicorn/gunicorn.out.log

[group:guni]
    programs:gunicorn
SUP_GUN" &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Supervisor - create directory for logging." >>/home/ubuntu/log/deploy.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Supervisor - create directory for logging." >>/home/ubuntu/log/deploy.log

systemctl daemon-reload
supervisorctl reread # tell supervisor read configuration file
supervisorctl update # update supervisor configuration
supervisorctl reload # Restarted supervisord

###########################################################
## Django Migrate
###########################################################
source /home/ubuntu/env/bin/activate
# django make migrations
python3 /home/ubuntu/AWS_ECDjangoDeployer/EC_Django_Deployer/manage.py makemigrations &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Django - make migrations." >>/home/ubuntu/log/deploy.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Django - make migrations." >>/home/ubuntu/log/deploy.log

# django migrate
python3 /home/ubuntu/AWS_ECDjangoDeployer/EC_Django_Deployer/manage.py migrate &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Django - migrate." >>/home/ubuntu/log/deploy.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Django - migrate." >>/home/ubuntu/log/deploy.log

# # django collect static files
# python3 /home/ubuntu/AWS_ECDjangoDeployer/EC_Django_Deployer/manage.py collectstatic &&
#     echo -e "$(date +'%Y-%m-%d %H:%M:%S') Django - collect static files." >>/home/ubuntu/log/deploy.log ||
#     echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Django - collect static files." >>/home/ubuntu/log/deploy.log
# deactivate

# restart gunicorn
service gunicorn restart &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Gunicorn - restart service." >>/home/ubuntu/log/deploy.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Gunicorn - restart service." >>/home/ubuntu/log/deploy.log

# restart nginx
service nginx restart &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Nginx - restart service." >>/home/ubuntu/log/deploy.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Nginx - restart service." >>/home/ubuntu/log/deploy.log

# log finish deployment
echo -e "$(date +'%Y-%m-%d %H:%M:%S') Deployment completed." >>/home/ubuntu/log/deploy.log

# troubleshooting
