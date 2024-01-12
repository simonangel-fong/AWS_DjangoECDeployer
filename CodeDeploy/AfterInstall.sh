#!/bin/bash
# Program Name: AfterInstall.sh
# Author name: Wenhao Fang
# Date Created: Jan 10th 2024
# Date Created: Jan 10th 2024
# Repo: AWS_ECDjangoDeployer
# Project: EC_Django_Deployer
# Description of the script:
#   script of after installation

# Log start CICD AfterInstall
echo -e "$(date +'%Y-%m-%d %H:%M:%S') CodeDeploy AfterInstall starting..." >>"/home/ubuntu/log/deploy.log"

###########################################################
## Creates virtual environment
###########################################################
python3 -m venv /home/ubuntu/env &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') VENV - Create virtual environment." >>"/home/ubuntu/log/deploy.log" ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: VENV - Create virtual environment." >>"/home/ubuntu/log/deploy.log"

###########################################################
## Install gunicorn package within venv
###########################################################
source /home/ubuntu/env/bin/activate
pip install gunicorn &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Gunicorn - Install gunicorn." >>/home/ubuntu/log/deploy.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Gunicorn - Install gunicorn." >>/home/ubuntu/log/deploy.log
deactivate

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
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Skip: Pip - Install project dependencies." >>/home/ubuntu/log/deploy.log
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
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Gunicorn - Create gunicorn.socket." >>"/home/ubuntu/log/deploy.log" ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Gunicorn - Create gunicorn.socket." >>"/home/ubuntu/log/deploy.log"

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
sudo systemctl daemon-reload          # reload daemon
sudo systemctl start gunicorn.socket  # Start gunicorn
sudo systemctl enable gunicorn.socket # enable on boots
sudo systemctl restart gunicorn       # restart gunicorn

###########################################################
## Configuration nginx
###########################################################

# overwrites user
sudo sed -i '1cuser root;' /etc/nginx/nginx.conf &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Nginx - overwrites user." >>"/home/ubuntu/log/deploy.log" ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Nginx - overwrites user." >>"/home/ubuntu/log/deploy.log"

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
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Nginx - create conf filer." >>"/home/ubuntu/log/deploy.log" ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Nginx - create conf filer." >>"/home/ubuntu/log/deploy.log"

#  Creat link in sites-enabled directory
ln -sf /etc/nginx/sites-available/django.conf /etc/nginx/sites-enabled &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Nginx - Creat link in sites-enabledr." >>"/home/ubuntu/log/deploy.log" ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Nginx - Creat link in sites-enabledr." >>"/home/ubuntu/log/deploy.log"

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
    directory=/home/ubuntu/AWS_ECDjangoDeployer/EC_Django_Deployer
    command=/home/ubuntu/env/bin/gunicorn --workers 3 --bind unix:/run/gunicorn.sock  EC_Django_Deployer.wsgi:application
    autostart=true
    autorestart=true
    stderr_logfile=/var/log/gunicorn/gunicorn.err.log
    stdout_logfile=/var/log/gunicorn/gunicorn.out.log

[group:guni]
    programs:gunicorn
SUP_GUN" &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Supervisor - create directory for logging." >>"/home/ubuntu/log/deploy.log" ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Supervisor - create directory for logging." >>"/home/ubuntu/log/deploy.log"

sudo systemctl daemon-reload
sudo supervisorctl reread # tell supervisor read configuration file
sudo supervisorctl update # update supervisor configuration
sudo supervisorctl reload # Restarted supervisord

# log finish deployment
echo -e "$(date +'%Y-%m-%d %H:%M:%S') CodeDeploy AfterInstall completed." >>"/home/ubuntu/log/deploy.log"
echo -e " " >>"/home/ubuntu/log/deploy.log"
