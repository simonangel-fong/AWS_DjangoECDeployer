#!/bin/bash
#Program Name: setup_supervisor.sh
#Author name: Wenhao Fang
#Date Created: Oct 21th 2023
#Description of the script: 
#   Install supervisor package
#   Create gunicorn.conf and django.conf

###########################################################
## Configuration supervisor
###########################################################
sudo apt-get install -y supervisor # install supervisor

sudo mkdir -p /var/log/gunicorn # create directory for logging

supervisor_gunicorn=/etc/supervisor/conf.d/gunicorn.conf # create configuration file
sudo bash -c "cat >$supervisor_gunicorn <<SUP_GUN
[program:gunicorn]
    directory=/home/ubuntu/AWS_EC2_ECDjangoDeploy/CraftyCoders
    command=/home/ubuntu/env/bin/gunicorn --workers 3 --bind unix:/run/gunicorn.sock  CraftyCoders.wsgi:application
    autostart=true
    autorestart=true
    stderr_logfile=/var/log/gunicorn/gunicorn.err.log
    stdout_logfile=/var/log/gunicorn/gunicorn.out.log

[group:guni]
    programs:gunicorn
SUP_GUN"

sudo systemctl daemon-reload
sudo supervisorctl reread # tell supervisor read configuration file
sudo supervisorctl update # update supervisor configuration
sudo supervisorctl reload # Restarted supervisord

