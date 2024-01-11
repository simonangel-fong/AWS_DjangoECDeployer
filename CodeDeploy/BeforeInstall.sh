#!/bin/bash
# Program Name: BeforeInstall.sh
# Author name: Wenhao Fang
# Date Created: Jan 10th 2024
# Date Created: Jan 10th 2024
# Repo: AWS_EC2_ECDjangoDeploy
# Project: EC_Django_Deployer
# Description of the script:
#   script of before installation

# Create the CICD log
sudo rm -rf Deploy_BeforeInstall.log
sudo touch /home/ubuntu/Deploy_BeforeInstall.log

# log start cicd BeforeInstall
sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') CodeDeploy BeforeInstall starting..." >>/home/ubuntu/Deploy_BeforeInstall.log

# remove the existing env, since each push might have different packages within env
sudo rm -rf /home/ubuntu/env &&
    sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') ENV - Remove existing env." >>/home/ubuntu/Deploy_BeforeInstall.log ||
    sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: ENV - Remove existing env." >>/home/ubuntu/Deploy_BeforeInstall.log

# remove the existing repo
sudo rm -rf /home/ubuntu/AWS_EC2_ECDjangoDeploy &&
    sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') ENV - Remove existing env." >>/home/ubuntu/Deploy_BeforeInstall.log ||
    sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: ENV - Remove existing env." >>/home/ubuntu/Deploy_BeforeInstall.log

# log complete cicd BeforeInstall
sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') CodeDeploy BeforeInstall completed." >>/home/ubuntu/Deploy_BeforeInstall.log
