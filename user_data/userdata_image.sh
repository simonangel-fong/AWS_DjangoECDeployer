#!/bin/bash
# Program Name: userdata_image.sh
# Author name: Wenhao Fang
# Date Created: Oct 21th 2023
# Date Created: Jan 10th 2024
# Description of the script:
#   user data script to create Golden Image

# Check if the log folder exists, and create it if not
if [ ! -d "/home/ubuntu/log" ]; then
    mkdir -p "/home/ubuntu/log"
fi

# Remove the old log file if it exists
if [ -f "/home/ubuntu/log/AMI.log" ]; then
    rm "/home/ubuntu/log/AMI.log"
fi

# Create a new log file
touch "/home/ubuntu/log/AMI.log"

# Log start CICD BeforeInstall
echo -e "$(date +'%Y-%m-%d %H:%M:%S') Image configuration starting..." >>"/home/ubuntu/log/AMI.log"

###########################################################
## Update Linux
###########################################################
# update the package on Linux system.
DEBIAN_FRONTEND=noninteractive apt-get -y update &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') OS - Update packages." >>"/home/ubuntu/log/AMI.log" ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: OS - Update packages." >>"/home/ubuntu/log/AMI.log"

###########################################################
## Upgrade Linux
###########################################################
# upgrade the package on Linux system.
DEBIAN_FRONTEND=noninteractive apt-get -y upgrade &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') OS - Upgrade packages." ">>/home/ubuntu/log/AMI.log" ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: OS - Upgrade packages." ">>/home/ubuntu/log/AMI.log"

###########################################################
## Install required package
## Install required package
###########################################################

# install nginx
apt-get install -y nginx &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Package - Install nginx." >>"/home/ubuntu/log/AMI.log" ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Package - Install nginx." >>"/home/ubuntu/log/AMI.log"

# install supervisor
apt-get install -y supervisor &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Package - Install supervisor." >>"/home/ubuntu/log/AMI.log" ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Package - Install supervisor." >>"/home/ubuntu/log/AMI.log"

## Install python3-venv package
apt-get install -y python3-venv &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Package - Install python3-venv." >>"/home/ubuntu/log/AMI.log" ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Package - Install python3-venv." >>"/home/ubuntu/log/AMI.log"

## Install wget package
apt-get install -y wget &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Package - Install wget." >>"/home/ubuntu/log/AMI.log" ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Package - Install wget." >>"/home/ubuntu/log/AMI.log"

## Install ruby-full package
apt-get install -y ruby-full &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Package - Install ruby-full." >>"/home/ubuntu/log/AMI.log" ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Package - Install ruby-full." >>"/home/ubuntu/log/AMI.log"

###########################################################
## Install CodeDeploy
###########################################################
# download codedeploy on the EC2
wget -P /home/ubuntu/ https://aws-codedeploy-us-east-1.s3.amazonaws.com/latest/install &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') CodeDeploy - Download codedeploy." >>"/home/ubuntu/log/AMI.log" ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: CodeDeploy - Download codedeploy." >>"/home/ubuntu/log/AMI.log"

# change permission of the install file
chmod +x /home/ubuntu/install
# install and log the output to the tmp/logfile.file
/home/ubuntu/install auto >/tmp/logfile &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') CodeDeploy - Install codedeploy." >>"/home/ubuntu/log/AMI.log" ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: CodeDeploy - Install codedeploy." >>"/home/ubuntu/log/AMI.log"

# log finish deployment
echo -e "$(date +'%Y-%m-%d %H:%M:%S') Image configuration completed." >>"/home/ubuntu/log/AMI.log"
echo -e " " >>"/home/ubuntu/log/AMI.log"
