#!/usr/bin/env bash

source ~/env/bin/activate # activate venv
pip install -r /home/ubuntu/EC-Django-Deploy/requirements.txt
deactivate # deactivate venv
