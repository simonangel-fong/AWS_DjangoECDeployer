#!/bin/bash
# Program Name: userdata_boto3.sh
# Author name: Wenhao Fang
# Date Created: Oct 21th 2023
# Date Created: Jan 10th 2024
# Description of the script:
#   user data script for boto3

# Create deploy.log
mkdir /home/ubuntu/log
touch /home/ubuntu/log/deploy.log

# starting log finish deployment
echo -e "$(date +'%Y-%m-%d %H:%M:%S') Deployment starting..." >>/home/ubuntu/log/deploy.log

###########################################################
## Clone github repo
###########################################################
# remove existings github repo dir
rm -rf /home/ubuntu/repo_name/
# create dir for github repo
mkdir /home/ubuntu/repo_name/

# clone github repo
git clone github_url /home/ubuntu/repo_name &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Git - Clone github repo." >>/home/ubuntu/log/deploy.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Git - Clone github repo." >>/home/ubuntu/log/deploy.log

###########################################################
## Creates virtual environment
###########################################################
python3 -m venv /home/ubuntu/env &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') VENV - Create virtual environment." >>"/home/ubuntu/log/deploy.log" ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: VENV - Create virtual environment." >>"/home/ubuntu/log/deploy.log"

###########################################################
## Install gunicorn package within venv
###########################################################
source /home/ubuntu/env/bin/activate
pip install gunicorn &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Gunicorn - Install gunicorn." >>/home/ubuntu/log/deploy.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Gunicorn - Install gunicorn." >>/home/ubuntu/log/deploy.log
deactivate

###########################################################
## Update project dependencies
###########################################################
# Check if requirements.txt exists
if [ -f "/home/ubuntu/repo_name/requirements.txt" ]; then
    source /home/ubuntu/env/bin/activate
    pip install -r /home/ubuntu/repo_name/requirements.txt &&
        echo -e "$(date +'%Y-%m-%d %H:%M:%S') Pip - Install project dependencies." >>/home/ubuntu/log/deploy.log ||
        echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Pip - Install project dependencies." >>/home/ubuntu/log/deploy.log
    deactivate
else
    echo -e "$DATE Skip: Pip - Install project dependencies." >>/home/ubuntu/log/deploy.log
fi

###########################################################
## Install gunicorn package within venv
###########################################################
source /home/ubuntu/env/bin/activate
pip install gunicorn &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Gunicorn - Install gunicorn." >>/home/ubuntu/log/deploy.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Gunicorn - Install gunicorn." >>/home/ubuntu/log/deploy.log
deactivate

###########################################################
## Configuration gunicorn
###########################################################

bash -c "cat >/etc/systemd/system/gunicorn.socket <<SOCK
[Unit]
Description=gunicorn socket

[Socket]
ListenStream=/run/gunicorn.sock

[Install]
WantedBy=sockets.target
SOCK" &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Gunicorn - Create gunicorn.socket." >>/home/ubuntu/log/deploy.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Gunicorn - Create gunicorn.socket." >>/home/ubuntu/log/deploy.log

bash -c "cat >/etc/systemd/system/gunicorn.service <<SERVICE
[Unit]
Description=gunicorn daemon
Requires=gunicorn.socket
After=network.target

[Service]
User=root
Group=www-data 
WorkingDirectory=/home/ubuntu/repo_name/project_name
ExecStart=/home/ubuntu/env/bin/gunicorn \
    --access-logfile - \
    --workers 3 \
    --bind unix:/run/gunicorn.sock \
    project_name.wsgi:application

[Install]
WantedBy=multi-user.target
SERVICE" &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Gunicorn - Create gunicorn.service." >>/home/ubuntu/log/deploy.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Gunicorn - Create gunicorn.service." >>/home/ubuntu/log/deploy.log

###########################################################
## Apply gunicorn configuration
###########################################################
systemctl daemon-reload          # reload daemon
systemctl start gunicorn.socket  # Start gunicorn
systemctl enable gunicorn.socket # enable on boots
systemctl restart gunicorn       # restart gunicorn

###########################################################
## Configuration nginx
###########################################################

# overwrites user
sed -i '1cuser root;' /etc/nginx/nginx.conf &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Nginx - overwrites user." >>/home/ubuntu/log/deploy.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Nginx - overwrites user." >>/home/ubuntu/log/deploy.log

# create conf file
bash -c "cat >/etc/nginx/sites-available/django.conf <<DJANGO_CONF
server {
listen 80;
server_name $(curl -s https://api.ipify.org) www.arguswatcher.net arguswatcher.net;
location = /favicon.ico { access_log off; log_not_found off; }
location /static/ {
    root /home/ubuntu/repo_name/project_name;
}

location /media/ {
    root /home/ubuntu/repo_name/project_name;
}

location / {
    include proxy_params;
    proxy_pass http://unix:/run/gunicorn.sock;
}
}
DJANGO_CONF" &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Nginx - create conf filer." >>/home/ubuntu/log/deploy.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Nginx - create conf filer." >>/home/ubuntu/log/deploy.log

#  Creat link in sites-enabled directory
ln -sf /etc/nginx/sites-available/django.conf /etc/nginx/sites-enabled &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Nginx - Creat link in sites-enabledr." >>/home/ubuntu/log/deploy.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Nginx - Creat link in sites-enabledr." >>/home/ubuntu/log/deploy.log

# restart nginx
nginx -t
systemctl restart nginx

###########################################################
## Configuration supervisor
###########################################################
# create directory for logging
mkdir -p /var/log/gunicorn
# create configuration file
bash -c "cat >/etc/supervisor/conf.d/gunicorn.conf  <<SUP_GUN
[program:gunicorn]
    directory=/home/ubuntu/repo_name/project_name
    command=/home/ubuntu/env/bin/gunicorn --workers 3 --bind unix:/run/gunicorn.sock  project_name.wsgi:application
    autostart=true
    autorestart=true
    stderr_logfile=/var/log/gunicorn/gunicorn.err.log
    stdout_logfile=/var/log/gunicorn/gunicorn.out.log

[group:guni]
    programs:gunicorn
SUP_GUN" &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Supervisor - create directory for logging." >>/home/ubuntu/log/deploy.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Supervisor - create directory for logging." >>/home/ubuntu/log/deploy.log

systemctl daemon-reload
supervisorctl reread # tell supervisor read configuration file
supervisorctl update # update supervisor configuration
supervisorctl reload # Restarted supervisord

###########################################################
## Django Migrate
###########################################################
source /home/ubuntu/env/bin/activate
# django make migrations
bash -c "python3 /home/ubuntu/repo_name/project_name/manage.py makemigrations" &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Django - make migrations." >>/home/ubuntu/log/deploy.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Django - make migrations." >>/home/ubuntu/log/deploy.log

# django migrate
python3 /home/ubuntu/repo_name/project_name/manage.py migrate &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Django - migrate." >>/home/ubuntu/log/deploy.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Django - migrate." >>/home/ubuntu/log/deploy.log

# django collect static files
python3 /home/ubuntu/repo_name/project_name/manage.py collectstatic &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Django - collect static files." >>/home/ubuntu/log/deploy.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Django - collect static files." >>/home/ubuntu/log/deploy.log
deactivate

# restart gunicorn
service gunicorn restart &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Gunicorn - restart service." >>/home/ubuntu/log/deploy.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Gunicorn - restart service." >>/home/ubuntu/log/deploy.log

# restart nginx
service nginx restart &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Nginx - restart service." >>/home/ubuntu/log/deploy.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Nginx - restart service." >>/home/ubuntu/log/deploy.log

# log finish deployment
echo -e "$(date +'%Y-%m-%d %H:%M:%S') Deployment completed." >>/home/ubuntu/log/deploy.log
