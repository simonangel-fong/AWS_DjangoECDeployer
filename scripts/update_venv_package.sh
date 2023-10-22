#!/usr/bin/env bash

source ~/env/bin/activate # activate venv
echo "activate" >> ~/log
pip install -r /home/ubuntu/EC-Django-Deploy/requirements.txt
echo "requirements" >> ~/log
deactivate
