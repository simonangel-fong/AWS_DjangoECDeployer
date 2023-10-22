# AWS AMI Note

- [AWS AMI Note](#aws-ami-note)
  - [AMI Setting](#ami-setting)
  - [Packages](#packages)
  - [Related Scrtipt](#related-scrtipt)
    - [`clean_existing.sh`](#clean_existingsh)
    - [`update_venv_package.sh`](#update_venv_packagesh)
    - [`setup_gunicorn.sh`](#setup_gunicornsh)
    - [`setup_nginx.sh`](#setup_nginxsh)
    - [`setup_supervisor.sh`](#setup_supervisorsh)

---

## AMI Setting

- Template: `Ubuntu_GP_Template`
- Key paire: `EC_Deploy`
- Security Groups: `HTTP_SSH`
- Resource tags: `project:EC Deploy`

---

## Packages

- AMI Configuration

```sh
#!/bin/bash
#Program Name: AMI_Configure.sh
#Author name: Wenhao Fang
#Date Created: Oct 22nd 2023
#Description of the script:
#   Update package
#   Install package: gunicorn, nginx, supervisor
#   Create python virtual environment

###########################################################
## Update Linux
###########################################################
echo -e "$(date +'%Y-%m-%d %R') Update Linux package starts..."
sudo DEBIAN_FRONTEND=noninteractive apt-get -y update # update the package on Linux system.
echo -e "$(date +'%Y-%m-%d %R') Updating Linux package completed.\n"


###########################################################
## Establish virtual environment
###########################################################

## Install venv package
echo -e "$(date +'%Y-%m-%d %R') Install virtual environment package starts..."
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install python3-venv # Install pip package
echo -e "$(date +'%Y-%m-%d %R') Install virtual environment package completed.\n"

## Create virtual environment
echo -e "$(date +'%Y-%m-%d %R') Create Virtual environment starts..."
sudo rm -rf /home/ubuntu/env          # remove existing venv
python3 -m venv /home/ubuntu/env # Creates virtual environment
echo -e "$(date +'%Y-%m-%d %R') Create Virtual environment completed.\n"


###########################################################
## Install gunicorn in venv
###########################################################

echo -e "$(date +'%Y-%m-%d %R') Install gunicorn starts..."
source /home/ubuntu/env/bin/activate # activate venv
pip install gunicorn                 # install gunicorn
deactivate                           # deactivate venv
echo -e "$(date +'%Y-%m-%d %R') Install gunicorn completed.\n"


###########################################################
## Install package: nginx
###########################################################

# Install nginx
echo -e "$(date +'%Y-%m-%d %R') Install nginx starts."
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install nginx # install nginx
echo -e "$(date +'%Y-%m-%d %R') Install nginx completed.\n"

# overwrites user
echo -e "$(date +'%Y-%m-%d %R') Overwrite nginx.conf."
nginx_conf=/etc/nginx/nginx.conf
sed -i '1cuser root;' $nginx_conf


###########################################################
## Install package: supervisor
###########################################################
# Install supervisor
echo -e "$(date +'%Y-%m-%d %R') Install supervisor starts."
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install supervisor # install supervisor
echo -e "$(date +'%Y-%m-%d %R') Install supervisor completed.\n"
sudo mkdir -p /var/log/gunicorn # create directory for logging


###########################################################
## Finish
###########################################################
echo -e "$(date +'%Y-%m-%d %R') AMI configuration completed.\n"

```

---

## Related Scrtipt

### `clean_existing.sh`

```sh
#!/bin/bash
#Program Name: clean_existing.sh
#Author name: Wenhao Fang
#Date Created: Oct 21th 2023
#Description of the script: Clean up existing files

sudo rm -rf /home/ubuntu/EC-Django-Deploy/*
```

---

### `update_venv_package.sh`

```sh

#!/bin/bash
#Program Name: update_venv_package.sh
#Author name: Wenhao Fang
#Date Created: Oct 21th 2023
#Description of the script:
#   Update python package in virtual environment.

source ~/env/bin/activate # activate venv
pip install -r /home/ubuntu/EC-Django-Deploy/requirements.txt
deactivate # deactivate venv

```

---

### `setup_gunicorn.sh`

```sh
#!/bin/bash
#Program Name: setup_gunicorn.sh
#Author name: Wenhao Fang
#Date Created: Oct 21th 2023
#Description of the script:
#   Install gunicorn in VEnv
#   Create gunicorn.socket and gunicorn.service

source ~/env/bin/activate # activate venv
pip install gunicorn      # install gunicorn
deactivate                # deactivate venv

###########################################################
## Configuration gunicorn
## Configuration gunicorn.socket
###########################################################
socket_conf=/etc/systemd/system/gunicorn.socket

sudo bash -c "sudo cat >$socket_conf <<SOCK
[Unit]
Description=gunicorn socket

[Socket]
ListenStream=/run/gunicorn.sock

[Install]
WantedBy=sockets.target
SOCK"

###########################################################
## Configuration gunicorn.service
###########################################################
service_conf=/etc/systemd/system/gunicorn.service

sudo bash -c "sudo cat >$service_conf <<SERVICE
[Unit]
Description=gunicorn daemon
Requires=gunicorn.socket
After=network.target

[Service]
User=root
Group=www-data
WorkingDirectory=/home/ubuntu/EC-Django-Deploy/CraftyCoders
ExecStart=/home/ubuntu/env/bin/gunicorn \
    --access-logfile - \
    --workers 3 \
    --bind unix:/run/gunicorn.sock \
    EC-Django-Deploy.wsgi:application

[Install]
WantedBy=multi-user.target
SERVICE"

###########################################################
## Apply gunicorn configuration
###########################################################
sudo systemctl daemon-reload          # reload daemon
sudo systemctl start gunicorn.socket  # Start gunicorn
sudo systemctl enable gunicorn.socket # enable on boots
sudo systemctl restart gunicorn       # restart gunicorn

```

---

### `setup_nginx.sh`

```sh
#!/bin/bash
#Program Name: setup_nginx.sh
#Author name: Wenhao Fang
#Date Created: Oct 21th 2023
#Description of the script:
#   Install nginx package
#   Create nginx.conf and django.conf

###########################################################
## Configuration nginx
###########################################################

# create conf file
django_conf=/etc/nginx/sites-available/django.conf
sudo bash -c "cat >$django_conf <<DJANGO_CONF
server {
listen 80;
server_name arguswatcher.net www.arguswatcher.net;
location = /favicon.ico { access_log off; log_not_found off; }
location /static/ {
    root /home/ubuntu/EC-Django-Deploy/CraftyCoders;
}

location /media/ {
    root /home/ubuntu/EC-Django-Deploy/CraftyCoders;
}

location / {
    include proxy_params;
    proxy_pass http://unix:/run/gunicorn.sock;
}
}
DJANGO_CONF"

#  Creat link in sites-enabled directory
sudo ln -sf /etc/nginx/sites-available/django.conf /etc/nginx/sites-enabled

# restart nginx
sudo nginx -t
sudo systemctl restart nginx

```

### `setup_supervisor.sh`

```sh
#!/bin/bash
#Program Name: setup_supervisor.sh
#Author name: Wenhao Fang
#Date Created: Oct 21th 2023
#Description of the script:
#   Install supervisor package
#   Create gunicorn.conf and django.conf

###########################################################
## Configuration supervisor
###########################################################
supervisor_gunicorn=/etc/supervisor/conf.d/gunicorn.conf # create configuration file
sudo bash -c "cat >$supervisor_gunicorn <<SUP_GUN
[program:gunicorn]
    directory=/home/ubuntu/EC-Django-Deploy/CraftyCoders
    command=/home/ubuntu/env/bin/gunicorn --workers 3 --bind unix:/run/gunicorn.sock  CraftyCoders.wsgi:application
    autostart=true
    autorestart=true
    stderr_logfile=/var/log/gunicorn/gunicorn.err.log
    stdout_logfile=/var/log/gunicorn/gunicorn.out.log

[group:guni]
    programs:gunicorn
SUP_GUN"

sudo systemctl daemon-reload
sudo supervisorctl reread # tell supervisor read configuration file
sudo supervisorctl update # update supervisor configuration
sudo supervisorctl reload # Restarted supervisord

```

---

[TOP](#aws-ami-note)
