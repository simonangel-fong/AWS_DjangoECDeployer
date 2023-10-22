#!/bin/bash
#Program Name: setup_env.sh
#Author name: Wenhao Fang
#Date Created: Oct 21th 2023
#Description of the script:
#   Clean existing env
#   Install pip package
#   Creates virtual environment

sudo rm -rf ~/env                    # remove existing venv
sudo apt-get install -y python3-venv # Install pip package
python3 -m venv ~/env                # Creates virtual environment
