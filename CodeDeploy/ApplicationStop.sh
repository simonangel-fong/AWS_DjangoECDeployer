#!/bin/bash
#Program Name: ApplicationStop.sh
#Author name: Wenhao Fang
# Date Created: Jan 10th 2024
# Date Created: Jan 10th 2024
# Repo: AWS_EC2_ECDjangoDeploy
# Project: EC_Django_Deployer
# Description of the script:
#   script of ApplicationStop

sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') CodeDeploy ApplicationStop starting..." >>/home/ubuntu/log/deploy.log

sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') ApplicationStop completed." >>/home/ubuntu/log/deploy.log
sudo echo -e " " >>/home/ubuntu/log/deploy.log
