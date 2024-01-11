#!/bin/bash
# Program Name: userdata_image.sh
# Author name: Wenhao Fang
# Date Created: Oct 21th 2023
# Date Created: Jan 10th 2024
# Description of the script:
#   user data script to increase Golden Image

# create log file for creation of golden image
sudo rm -f /home/ubuntu/OSImage.log
sudo touch /home/ubuntu/OSImage.log

# log start image configuration
echo -e "$(date +'%Y-%m-%d %H:%M:%S') Image configuration starting..." >>/home/ubuntu/OSImage.log

###########################################################
## Update Linux
###########################################################
# update the package on Linux system.
sudo DEBIAN_FRONTEND=noninteractive apt-get -y update &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Update OS packages." >>/home/ubuntu/OSImage || .log
echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Update OS packages." >>/home/ubuntu/OSImage.log

###########################################################
## Upgrade Linux
###########################################################
# upgrade the package on Linux system.
sudo DEBIAN_FRONTEND=noninteractive apt-get -y upgrade &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Upgrade OS packages." >>/home/ubuntu/OSImage || .log
echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Upgrade OS packages." >>/home/ubuntu/OSImage.log

###########################################################
## Install packages
###########################################################
# install nginx
sudo apt-get install -y nginx &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Install nginx package." >>/home/ubuntu/OSImage || .log
echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Install nginx package." >>/home/ubuntu/OSImage.log

# install supervisor
sudo apt-get install -y supervisor &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Install supervisor package." >>/home/ubuntu/OSImage || .log
echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Install supervisor package." >>/home/ubuntu/OSImage.log

## Install python3-venv package
sudo apt-get install -y python3-venv &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Install python3-venv package." >>/home/ubuntu/OSImage || .log
echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Install python3-venv package." >>/home/ubuntu/OSImage.log

###########################################################
## Establish virtual environment
###########################################################
# # remove existing venv
rm -rf /home/ubuntu/env &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') VENV - Remove existing venv dir." >>/home/ubuntu/OSImage || .log
echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: VENV - Remove existing venv dir." >>/home/ubuntu/OSImage.log

# Creates virtual environment
python3 -m venv /home/ubuntu/env &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') VENV - Create virtual environment." >>/home/ubuntu/OSImage || .log
echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: VENV - Create virtual environment." >>/home/ubuntu/OSImage.log

###########################################################
## Install gunicorn package within venv
###########################################################
# activate venv
source /home/ubuntu/env/bin/activate

# install gunicorn
pip install gunicorn &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') VENV - Install gunicorn package within venv." >>/home/ubuntu/OSImage || .log
echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: VENV - Install gunicorn package within venv." >>/home/ubuntu/OSImage.log

# deactivate venv
deactivate

# log finish deployment
echo -e "$(date +'%Y-%m-%d %H:%M:%S') Image configuration completed." >>/home/ubuntu/OSImage.log
