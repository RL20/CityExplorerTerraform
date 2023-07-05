#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status
set -x  # Print each command before executing it

# Redirect output to a log file
exec > >(tee -i /var/log/user-data.log)
exec 2>&1

# Install Chef
wget https://packages.chef.io/files/stable/chef-workstation/21.10.640/ubuntu/20.04/chef-workstation_21.10.640-1_amd64.deb
sudo apt-get install ./chef-workstation_21.10.640-1_amd64.deb -y
# Git Clone
git clone https://github.com/RL20/CityExplorerChef.git /home/ubuntu/CityExplorerChef

# Create Env File
cat <<EOT >> /home/ubuntu/.env
DB_HOST=${rds_url}
DB_USER=${rds_username}
DB_PASSWORD=${rds_password}
DB_NAME=city_explorer
API_KEY=${api_key}
EOT
#Run Chef
sudo chef-solo -c /home/ubuntu/CityExplorerChef/solo.rb -o role[city_explorer_app]

# Crontab is a linux utility that can run a script every x minutes
# We configure it to pull the chef repo every 10 minutes and then execute chef, to check for updates
(crontab -l 2>/dev/null; echo "*/10 * * * * /bin/bash -c 'sudo git pull https://github.com/RL20/CityExplorerChef.git && sudo chef-solo -c /home/ubuntu/CityExplorerChef/solo.rb -o role[city_explorer_app]") | crontab -

