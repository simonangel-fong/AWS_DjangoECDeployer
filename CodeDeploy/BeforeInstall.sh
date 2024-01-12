#!/bin/bash
# Program Name: BeforeInstall.sh
# Author name: Wenhao Fang
# Date Created: Jan 10th 2024
# Date Created: Jan 10th 2024
# Repo: AWS_ECDjangoDeployer
# Project: EC_Django_Deployer
# Description of the script:
#   script of BeforeInstall

# Check if the log folder exists, and create it if not
if [ ! -d "/home/ubuntu/log" ]; then
    mkdir -p "/home/ubuntu/log"
fi

# Remove the old log file if it exists
if [ -f "/home/ubuntu/log/deploy.log" ]; then
    rm "/home/ubuntu/log/deploy.log"
fi

# Create a new log file
sudo touch "/home/ubuntu/log/deploy.log"

# Log start CICD BeforeInstall
echo -e "$(date +'%Y-%m-%d %H:%M:%S') CodeDeploy BeforeInstall starting..." >>"/home/ubuntu/log/deploy.log"

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

# log complete cicd BeforeInstall
echo -e "$(date +'%Y-%m-%d %H:%M:%S') CodeDeploy BeforeInstall completed.\n" >>"/home/ubuntu/log/deploy.log"
echo -e " " >>"/home/ubuntu/log/deploy.log"
