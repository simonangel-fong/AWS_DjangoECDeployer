#!/bin/bash
# Program Name: userdata_image.sh
# Author name: Wenhao Fang
# Date Created: Oct 21th 2023
# Date Created: Jan 10th 2024
# Description of the script:
#   user data script to create Golden Image

# create log file for creation of golden image
sudo rm -f /home/ubuntu/AMI.log
sudo touch /home/ubuntu/AMI.log

# log start image configuration
echo -e "$(date +'%Y-%m-%d %H:%M:%S') Image configuration starting..." >>/home/ubuntu/AMI.log

###########################################################
## Update Linux
###########################################################
# update the package on Linux system.
sudo DEBIAN_FRONTEND=noninteractive apt-get -y update &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Update OS packages." >>/home/ubuntu/AMI.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Update OS packages." >>/home/ubuntu/AMI.log

###########################################################
## Upgrade Linux
###########################################################
# upgrade the package on Linux system.
sudo DEBIAN_FRONTEND=noninteractive apt-get -y upgrade &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Upgrade OS packages." >>/home/ubuntu/AMI.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Upgrade OS packages." >>/home/ubuntu/AMI.log

###########################################################
## Install CodeDeploy
###########################################################
# install ruby-full package
sudo apt install -y ruby-full &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') CodeDeploy - install ruby-full package." >>/home/ubuntu/AMI.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: CodeDeploy - install ruby-full package." >>/home/ubuntu/AMI.log

# install wget utility
sudo apt install -y wget &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') CodeDeploy - install wget utility." >>/home/ubuntu/AMI.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: CodeDeploy - install wget utility." >>/home/ubuntu/AMI.log

# download codedeploy on the EC2
wget -P /home/ubuntu/ https://aws-codedeploy-us-east-1.s3.amazonaws.com/latest/install &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') CodeDeploy - download codedeploy." >>/home/ubuntu/AMI.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: CodeDeploy - download codedeploy." >>/home/ubuntu/AMI.log

# change permission of the install file
sudo chmod +x /home/ubuntu/install
# install and log the output to the tmp/logfile.file
sudo /home/ubuntu/install auto >/tmp/logfile &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') CodeDeploy - install codedeploy." >>/home/ubuntu/AMI.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: CodeDeploy - install codedeploy." >>/home/ubuntu/AMI.log

###########################################################
## Install packages
###########################################################
# install nginx
sudo apt-get install -y nginx &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Install nginx package." >>/home/ubuntu/AMI.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Install nginx package." >>/home/ubuntu/AMI.log

# install supervisor
sudo apt-get install -y supervisor &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Install supervisor package." >>/home/ubuntu/AMI.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Install supervisor package." >>/home/ubuntu/AMI.log

## Install python3-venv package
sudo apt-get install -y python3-venv &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Install python3-venv package." >>/home/ubuntu/AMI.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Install python3-venv package." >>/home/ubuntu/AMI.log

###########################################################
## Establish virtual environment
###########################################################
# # remove existing venv
rm -rf /home/ubuntu/env &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') VENV - Remove existing venv dir." >>/home/ubuntu/AMI.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: VENV - Remove existing venv dir." >>/home/ubuntu/AMI.log

# Creates virtual environment
python3 -m venv /home/ubuntu/env &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') VENV - Create virtual environment." >>/home/ubuntu/AMI.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: VENV - Create virtual environment." >>/home/ubuntu/AMI.log

###########################################################
## Install gunicorn package within venv
###########################################################
# activate venv
source /home/ubuntu/env/bin/activate

# install gunicorn
pip install gunicorn &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') VENV - Install gunicorn package within venv." >>/home/ubuntu/AMI.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: VENV - Install gunicorn package within venv." >>/home/ubuntu/AMI.log

# deactivate venv
deactivate

# log finish deployment
echo -e "$(date +'%Y-%m-%d %H:%M:%S') Image configuration completed." >>/home/ubuntu/AMI.log
