#!/bin/bash
#Program Name: start_app.sh
#Author name: Wenhao Fang
#Date Created: Oct 21th 2023
#Description of the script: Start app

cd ~
source env/bin/activate

###########################################################
## Django Migrate
###########################################################

python3 manage.py makemigrations # django make migrations
python3 manage.py migrate        # django migrate
python3 manage.py collectstatic

sudo service gunicorn restart
sudo service nginx restart

deactivate # deactivate venv
