#!/bin/bash
#Program Name: update_venv_package.sh
#Author name: Wenhao Fang
#Date Created: Oct 21th 2023
#Description of the script:
#   Update python package in virtual environment.

source ~/env/bin/activate # activate venv
pip install -r /home/ubuntu/EC-Django-Deploy/requirements.txt
deactivate # deactivate venv
