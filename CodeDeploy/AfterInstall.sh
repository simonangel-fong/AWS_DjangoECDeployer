#!/bin/bash
# Program Name: AfterInstall.sh
# Author name: Wenhao Fang
# Date Created: Jan 10th 2024
# Date Created: Jan 10th 2024
# Repo: AWS_EC2_ECDjangoDeploy
# Project: EC_Django_Deployer
# Description of the script:
#   script of after installation

# create log file
sudo rm -rf /home/ubuntu/Deploy_AfterInstall.log
sudo touch /home/ubuntu/Deploy_AfterInstall.log

# log start cicd AfterInstall
sudo echo -e "/n$(date +'%Y-%m-%d %H:%M:%S') CodeDeploy AfterInstall starting..." >>/home/ubuntu/Deploy_AfterInstall.log

###########################################################
## Install gunicorn package within venv
###########################################################
# Creates virtual environment
python3 -m venv /home/ubuntu/env &&
    sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') VENV - Create virtual environment." >>/home/ubuntu/Deploy_AfterInstall.log ||
    sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: VENV - Create virtual environment." >>/home/ubuntu/Deploy_AfterInstall.log

# activate venv
source /home/ubuntu/env/bin/activate

# install gunicorn
pip install gunicorn &&
    sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') VENV - Install gunicorn package within venv." >>/home/ubuntu/Deploy_AfterInstall.log ||
    sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: VENV - Install gunicorn package within venv." >>/home/ubuntu/Deploy_AfterInstall.log

# deactivate venv
deactivate

###########################################################
## Update project dependencies
###########################################################
source /home/ubuntu/env/bin/activate
pip install -r /home/ubuntu/Django_Simple_CRUD/requirements.txt &&
    sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') Pip - Install project dependencies." >>/home/ubuntu/Deploy_AfterInstall.log ||
    sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Pip - Install project dependencies." >>/home/ubuntu/Deploy_AfterInstall.log
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
    sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') Gunicorn - Create gunicorn.socket." >>/home/ubuntu/Deploy_AfterInstall.log ||
    sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Gunicorn - Create gunicorn.socket." >>/home/ubuntu/Deploy_AfterInstall.log

sudo bash -c "sudo cat >/etc/systemd/system/gunicorn.service <<SERVICE
[Unit]
Description=gunicorn daemon
Requires=gunicorn.socket
After=network.target

[Service]
User=root
Group=www-data 
WorkingDirectory=/home/ubuntu/AWS_EC2_ECDjangoDeploy/EC_Django_Deployer
ExecStart=/home/ubuntu/env/bin/gunicorn \
    --access-logfile - \
    --workers 3 \
    --bind unix:/run/gunicorn.sock \
    AWS_EC2_ECDjangoDeploy.wsgi:application

[Install]
WantedBy=multi-user.target
SERVICE" &&
    sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') Gunicorn - Create gunicorn.service." >>/home/ubuntu/Deploy_AfterInstall.log ||
    sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Gunicorn - Create gunicorn.service." >>/home/ubuntu/Deploy_AfterInstall.log

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
    sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') Nginx - overwrites user." >>/home/ubuntu/Deploy_AfterInstall.log ||
    sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Nginx - overwrites user." >>/home/ubuntu/Deploy_AfterInstall.log

# create conf file
sudo bash -c "cat >/etc/nginx/sites-available/django.conf <<DJANGO_CONF
server {
listen 80;
server_name $(curl -s https://api.ipify.org);
location = /favicon.ico { access_log off; log_not_found off; }
location /static/ {
    root /home/ubuntu/AWS_EC2_ECDjangoDeploy/EC_Django_Deployer
}

location /media/ {
    root /home/ubuntu/AWS_EC2_ECDjangoDeploy/EC_Django_Deployer
}

location / {
    include proxy_params;
    proxy_pass http://unix:/run/gunicorn.sock;
}
}
DJANGO_CONF" &&
    sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') Nginx - create conf filer." >>/home/ubuntu/Deploy_AfterInstall.log ||
    sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Nginx - create conf filer." >>/home/ubuntu/Deploy_AfterInstall.log

#  Creat link in sites-enabled directory
sudo ln -sf /etc/nginx/sites-available/django.conf /etc/nginx/sites-enabled &&
    sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') Nginx - Creat link in sites-enabledr." >>/home/ubuntu/Deploy_AfterInstall.log ||
    sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Nginx - Creat link in sites-enabledr." >>/home/ubuntu/Deploy_AfterInstall.log

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
    directory=/home/ubuntu/AWS_EC2_ECDjangoDeploy/EC_Django_Deployer
    command=/home/ubuntu/env/bin/gunicorn --workers 3 --bind unix:/run/gunicorn.sock  EC_Django_Deployer.wsgi:application
    autostart=true
    autorestart=true
    stderr_logfile=/var/log/gunicorn/gunicorn.err.log
    stdout_logfile=/var/log/gunicorn/gunicorn.out.log

[group:guni]
    programs:gunicorn
SUP_GUN" &&
    sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') Supervisor - create directory for logging." >>/home/ubuntu/Deploy_AfterInstall.log ||
    sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Supervisor - create directory for logging." >>/home/ubuntu/Deploy_AfterInstall.log

sudo systemctl daemon-reload
sudo supervisorctl reread # tell supervisor read configuration file
sudo supervisorctl update # update supervisor configuration
sudo supervisorctl reload # Restarted supervisord

###########################################################
## Django Migrate
###########################################################
# django make migrations
python3 manage.py makemigrations &&
    sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') Django - make migrations." >>/home/ubuntu/Deploy_AfterInstall.log ||
    sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Django - make migrations." >>/home/ubuntu/Deploy_AfterInstall.log

# django migrate
python3 manage.py migrate &&
    sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') Django - migrate." >>/home/ubuntu/Deploy_AfterInstall.log ||
    sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Django - migrate." >>/home/ubuntu/Deploy_AfterInstall.log

# django collect static files
python3 manage.py collectstatic &&
    sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') Django - collect static files." >>/home/ubuntu/Deploy_AfterInstall.log ||
    sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Django - collect static files." >>/home/ubuntu/Deploy_AfterInstall.log

# restart gunicorn
sudo service gunicorn restart &&
    sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') Gunicorn - restart service." >>/home/ubuntu/Deploy_AfterInstall.log ||
    sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Gunicorn - restart service." >>/home/ubuntu/Deploy_AfterInstall.log

# restart nginx
sudo service nginx restart &&
    sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') Nginx - restart service." >>/home/ubuntu/Deploy_AfterInstall.log ||
    sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Nginx - restart service." >>/home/ubuntu/Deploy_AfterInstall.log

# log finish deployment
sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') CodeDeploy AfterInstall completed." >>/home/ubuntu/Deploy_AfterInstall.log
