#!/bin/bash
#Program Name: ApplicationStart.sh
#Author name: Wenhao Fang
# Date Created: Jan 10th 2024
# Date Created: Jan 10th 2024
# Repo: AWS_EC2_ECDjangoDeploy
# Project: EC_Django_Deployer
# Description of the script:
#   script of ApplicationStart

# create ApplicationStart log/

# start logging
sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') CodeDeploy ApplicationStart starting..." >>/home/ubuntu/log/deploy.log

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

deactivate # deactivate venv

###########################################################
## restart services
###########################################################
# restart gunicorn
sudo service gunicorn restart &&
    sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') Gunicorn - restart service." >>/home/ubuntu/log/deploy.log ||
    sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Gunicorn - restart service." >>/home/ubuntu/log/deploy.log

# restart nginx
sudo service nginx restart &&
    sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') Nginx - restart service." >>/home/ubuntu/log/deploy.log ||
    sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Nginx - restart service." >>/home/ubuntu/log/deploy.log

# complate logging
sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') ApplicationStart completed." >>/home/ubuntu/log/deploy.log
sudo echo -e " " >>/home/ubuntu/log/deploy.log
