#!/bin/bash
# Program Name: script_easy_deploy.sh
# Author name: Wenhao Fang
# Date Created: Oct 3rd 2023
# Date updated: Oct 3rd 2023
# Description of the script:
#   Sets up EC2 to deploy django app using user data.
#   No .env file.
#   No database connection setup.

## Updates Linux package
update_package() {
    echo -e "$(date +'%Y-%m-%d %R') Update Linux package starts..."
    DEBIAN_FRONTEND=noninteractive apt-get -y update # update the package on Linux system.
    # DEBIAN_FRONTEND=noninteractive apt-get -y upgrade # downloads and installs the updates for each outdated package and dependency
    echo -e "$(date +'%Y-%m-%d %R') Updating Linux package completed.\n"
}

## Establish virtual environment
setup_venv() {
    echo -e "$(date +'%Y-%m-%d %R') Install virtual environment package starts..."
    DEBIAN_FRONTEND=noninteractive apt-get -y install python3-venv # Install pip package
    # DEBIAN_FRONTEND=noninteractive apt-get -y install virtualenv # Install pip package
    echo -e "$(date +'%Y-%m-%d %R') Install virtual environment package completed.\n"

    echo -e "$(date +'%Y-%m-%d %R') Create Virtual environment starts..."
    rm -rf /home/ubuntu/env          # remove existing venv
    python3 -m venv /home/ubuntu/env # Creates virtual environment
    echo -e "$(date +'%Y-%m-%d %R') Create Virtual environment completed.\n"
}

## Download codes from github
load_code() {

    P_REPO_NAME=$1
    P_GITHUB_URL=$2

    echo -e "$(date +'%Y-%m-%d %R') Download codes from github starts..."
    rm -rf /home/ubuntu/${P_REPO_NAME} # remove the exsting directory
    cd /home/ubuntu
    git clone $P_GITHUB_URL # clone codes from github
    echo -e "$(date +'%Y-%m-%d %R') Download codes from github completed.\n"
}

## Update packages within venv
update_venv_package() {

    P_REPO_NAME=$1
    P_PROJECT_NAME=$2

    echo -e "$(date +'%Y-%m-%d %R') Update venv packages starts..."
    source /home/ubuntu/env/bin/activate # activate venv

    pip install -r /home/ubuntu/${P_REPO_NAME}/requirements.txt
    echo -e "$(date +'%Y-%m-%d %R') Update venv packages completed.\n"

    # logging package list
    echo -e "\n$(date +'%Y-%m-%d %R') Pip list:" >>/home/ubuntu/setup_log
    pip list >>/home/ubuntu/setup_log

    # Migrate App
    echo -e "$(date +'%Y-%m-%d %R') Migrate App starts..."
    python3 /home/ubuntu/${P_REPO_NAME}/${P_PROJECT_NAME}/manage.py makemigrations
    python3 /home/ubuntu/${P_REPO_NAME}/${P_PROJECT_NAME}/manage.py migrate
    deactivate
    echo -e "$(date +'%Y-%m-%d %R') Migrate App starts completed.\n"
}

## Install and configure Gunicorn
setup_gunicorn() {

    P_REPO_NAME=$1
    P_PROJECT_NAME=$2

    # Configuration gunicorn.socket
    socket_conf=/etc/systemd/system/gunicorn.socket

    cat >$socket_conf <<SOCK
[Unit]
Description=gunicorn socket

[Socket]
ListenStream=/run/gunicorn.sock

[Install]
WantedBy=sockets.target
SOCK
    echo -e "$(date +'%Y-%m-%d %R') gunicorn.socket created."

    # Configuration gunicorn.service
    service_conf=/etc/systemd/system/gunicorn.service

    cat >$service_conf <<SERVICE
[Unit]
Description=gunicorn daemon
Requires=gunicorn.socket
After=network.target

[Service]
User=root
Group=www-data 
WorkingDirectory=/home/ubuntu/${P_REPO_NAME}/${P_PROJECT_NAME}
ExecStart=/home/ubuntu/env/bin/gunicorn \
    --access-logfile - \
    --workers 3 \
    --bind unix:/run/gunicorn.sock \
    ${P_PROJECT_NAME}.wsgi:application

[Install]
WantedBy=multi-user.target
SERVICE
    echo -e "$(date +'%Y-%m-%d %R') gunicorn.socket created."

    # Apply gunicorn configuration
    echo -e "$(date +'%Y-%m-%d %R') gunicorn restart.\n"
    systemctl daemon-reload          # reload daemon
    systemctl start gunicorn.socket  # Start gunicorn
    systemctl enable gunicorn.socket # enable on boots
    systemctl restart gunicorn       # restart gunicorn

    # logging gunicorn status
    echo -e "$(date +'%Y-%m-%d %R') gunicorn.socket status:" >>/home/ubuntu/setup_log
    systemctl status gunicorn.socket >>/home/ubuntu/setup_log
}

## Install and configure Nginx
setup_nginx() {

    local P_REPO_NAME=$1
    local P_PROJECT_NAME=$2
    local P_HOST_IP=$3

    # create conf file
    echo -e "$(date +'%Y-%m-%d %R') Create conf file."
    django_conf=/etc/nginx/sites-available/django.conf
    cat >$django_conf <<DJANGO_CONF
server {
listen 80;
server_name ${P_HOST_IP};
location = /favicon.ico { access_log off; log_not_found off; }
location /static/ {
    root /home/ubuntu/${P_REPO_NAME}/${P_PROJECT_NAME};
}

location /media/ {
    root /home/ubuntu/${P_REPO_NAME}/${P_PROJECT_NAME};
}

location / {
    include proxy_params;
    proxy_pass http://unix:/run/gunicorn.sock;
}
}
DJANGO_CONF

    #  Creat link in sites-enabled directory
    echo -e "$(date +'%Y-%m-%d %R') Create link in sites-enabled."
    ln -sf /etc/nginx/sites-available/django.conf /etc/nginx/sites-enabled

    # restart nginx
    echo -e "$(date +'%Y-%m-%d %R') Nginx restart."
    systemctl restart nginx

    # logging nginx status
    echo -e "\n$(date +'%Y-%m-%d %R') Nginx syntax:" >>/home/ubuntu/setup_log
    nginx -t >>/home/ubuntu/setup_log

    echo -e "\n$(date +'%Y-%m-%d %R') Nginx status:" >>/home/ubuntu/setup_log
    systemctl daemon-reload # reload daemon
    systemctl status nginx >>/home/ubuntu/setup_log
}

## Reload Nginx
reload_nginx() {
    # relaod nginx
    systemctl daemon-reload # reload daemon
    systemctl reload nginx  # reload nginx

    # logging nginx status
    echo -e "\n$(date +'%Y-%m-%d %R') Nginx reload syntax:" >>/home/ubuntu/setup_log
    nginx -t >>/home/ubuntu/setup_log

    echo -e "\n$(date +'%Y-%m-%d %R') Nginx reload status:" >>/home/ubuntu/setup_log
    systemctl status nginx >>/home/ubuntu/setup_log
}

## Install and configure Supervisor
setup_supervisor() {

    P_REPO_NAME=$1
    P_PROJECT_NAME=$2

    echo -e "$(date +'%Y-%m-%d %R') Create gunicorn.conf."
    supervisor_gunicorn=/etc/supervisor/conf.d/gunicorn.conf # create configuration file
    cat >$supervisor_gunicorn <<SUP_GUN
[program:gunicorn]
    directory=/home/ubuntu/${P_REPO_NAME}/${P_PROJECT_NAME}
    command=/home/ubuntu/env/bin/gunicorn --workers 3 --bind unix:/run/gunicorn.sock  ${P_PROJECT_NAME}.wsgi:application
    autostart=true
    autorestart=true
    stderr_logfile=/var/log/gunicorn/gunicorn.err.log
    stdout_logfile=/var/log/gunicorn/gunicorn.out.log

[group:guni]
    programs:gunicorn
SUP_GUN

    # Apply configuration.
    echo -e "$(date +'%Y-%m-%d %R') Reload supervisor."
    supervisorctl reread # tell supervisor read configuration file >> /home/ubuntu/setup_log
    supervisorctl update # update supervisor configuration
    systemctl daemon-reload
    supervisorctl reload # Restarted supervisord

    # logging supervisor status
    sleep 5
    echo -e "\n$(date +'%Y-%m-%d %R') Supervisor status:" >>/home/ubuntu/setup_log
    supervisorctl status >>/home/ubuntu/setup_log
}

## Reload Supervisor
reload_supervisor() {
    # relaod supervisor
    systemctl daemon-reload     # reload daemon
    systemctl reload supervisor # reload supervisor

    # logging supervisor status
    sleep 5
    echo -e "\n$(date +'%Y-%m-%d %R') Supervisor status:" >>/home/ubuntu/setup_log
    supervisorctl status >>/home/ubuntu/setup_log
}

## Configure script for restart
config_cloud_restart() {

    echo -e "$(date +'%Y-%m-%d %R') Create cloud config for restart script."
    cloud_config=/etc/cloud/cloud.cfg.d/cloud-config.cfg # create cloud configuration file
    cat >$cloud_config <<CLOUD_CONFIG
#cloud-config
cloud_final_modules:
- [scripts-user, always]
CLOUD_CONFIG
}

# test
# P_REPO_NAME=Repo4DjangoEasyDeploy
# P_PROJECT_NAME=SimpleDjango
# P_GITHUB_URL=https://github.com/simonangel-fong/Repo4DjangoEasyDeploy.git
# P_HOST_IP="$(dig +short myip.opendns.com @resolver1.opendns.com)"

# production
P_REPO_NAME=py_repo_name
P_PROJECT_NAME=py_project_name
P_GITHUB_URL=py_github_url
P_HOST_IP="$(dig +short myip.opendns.com @resolver1.opendns.com)"

## Download codes from github
load_code $P_REPO_NAME $P_GITHUB_URL

## Install packages within venv
update_venv_package $P_REPO_NAME $P_PROJECT_NAME

## Install and configure Gunicorn
setup_gunicorn $P_REPO_NAME $P_PROJECT_NAME

## Install and configure Nginx
setup_nginx $P_REPO_NAME $P_PROJECT_NAME $P_HOST_IP

## Install and configure Supervisor
setup_supervisor $P_REPO_NAME $P_PROJECT_NAME

## Create cloud config, the script will be run each restart.
config_cloud_restart
