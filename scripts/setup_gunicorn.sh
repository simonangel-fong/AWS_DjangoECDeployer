#!/bin/bash
#Program Name: setup_gunicorn.sh
#Author name: Wenhao Fang
#Date Created: Oct 21th 2023
#Description of the script: 
#   Install gunicorn in VEnv
#   Create gunicorn.socket and gunicorn.service

source ~/env/bin/activate # activate venv
pip install gunicorn      # install gunicorn
deactivate                # deactivate venv

###########################################################
## Configuration gunicorn
## Configuration gunicorn.socket
###########################################################
socket_conf=/etc/systemd/system/gunicorn.socket

sudo bash -c "sudo cat >$socket_conf <<SOCK
[Unit]
Description=gunicorn socket

[Socket]
ListenStream=/run/gunicorn.sock

[Install]
WantedBy=sockets.target
SOCK"

###########################################################
## Configuration gunicorn.service
###########################################################
service_conf=/etc/systemd/system/gunicorn.service

sudo bash -c "sudo cat >$service_conf <<SERVICE
[Unit]
Description=gunicorn daemon
Requires=gunicorn.socket
After=network.target

[Service]
User=root
Group=www-data 
WorkingDirectory=/home/ubuntu/AWS_EC2_ECDjangoDeploy/CraftyCoders
ExecStart=/home/ubuntu/env/bin/gunicorn \
    --access-logfile - \
    --workers 3 \
    --bind unix:/run/gunicorn.sock \
    CraftyCoders.wsgi:application

[Install]
WantedBy=multi-user.target
SERVICE"

###########################################################
## Apply gunicorn configuration
###########################################################
sudo systemctl daemon-reload          # reload daemon
sudo systemctl start gunicorn.socket  # Start gunicorn
sudo systemctl enable gunicorn.socket # enable on boots
sudo systemctl restart gunicorn       # restart gunicorn
