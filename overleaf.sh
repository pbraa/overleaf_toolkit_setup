#!/bin/bash

### Variables
## Install path
install_path="/opt/overleaf"  # Change this value to wherever you want to run Overleaf from.

## Servername
servername="Change this to your liking"

## IP address and port
listen_ip="0.0.0.0" # Change this if required
listen_port="80" # By default this port is set to port 80. Change if required for your environment.



# Making sure the directory is in place before proceding
if [ ! -d "$install_path" ]; then
    sudo mkdir "$install_path"
fi
sudo chown $USER:$USER $install_path


# Clone the overleaf toolkit
git clone https://github.com/overleaf/toolkit.git $install_path


# Initialise the install
cd $install_path
bin/init

# Modify config/overleaf.rc
echo "PATH=/usr/local/texlive/2023/bin/x86_64-linux:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" >> "$install_path/config/overleaf.rc"

if grep -q -E "^OVERLEAF_LISTEN_IP=.*" "config/overleaf.rc"; then
    sed -i -E "s/^OVERLEAF_LISTEN_IP=.*$/OVERLEAF_LISTEN_IP=\"$listen_ip\"/" "$install_path/config/overleaf.rc"
fi

if grep -q -E "^OVERLEAF_LISTEN_PORT=." "config/overleaf.rc"; then
    sed -i -E "s/^OVERLEAF_LISTEN_PORT=.*$/OVERLEAF_LISTEN_PORT=\"$listen_port\"/" "$install_path/config/overleaf.rc"
fi

# Change the name of the overleaf instance in variables.env
if grep -q -E "^OVERLEAF_APP_NAME=.*" "config/variables.env"; then
    sed -i -E "s/^OVERLEAF_APP_NAME=.*$/OVERLEAF_APP_NAME=\"$servername\"/" "$install_path/config/variables.env"
fi

# Create docker compose override file, instructions from https://ulysseszh.github.io/guide/2023/09/29/self-host-overleaf.html
cat <<EOF > "$install_path/config/docker-compose.override.yml"
---
version: '2.2'
services:
  mongo:
    restart: unless-stopped
    container_name: overleaf-mongo

  redis:
    restart: unless-stopped
    container_name: overleaf-redis

  sharelatex:
    restart: unless-stopped
    #image: sharelatex/sharelatex:with-texlive-full # will be uncommented later
    container_name: overleaf-sharelatex
    stop_grace_period: 10s # see https://github.com/overleaf/overleaf/issues/1156
EOF

# Start the Overleaf instance in the background
nohup bin/up &

# Wait for the Overleaf service to load
echo "Waiting for Overleaf to start..."
sleep 15  # Adjust this value based on how long Overleaf typically takes to start


# Prepare the admin account before proceding!
echo "Please access the Overleaf instance in your browser, create an admin account, then return here and press [Enter] to continue..."
read -p ""

# Update the TeXlive packages
docker exec overleaf-sharelatex wget "https://mirror.ctan.org/systems/texlive/tlnet/update-tlmgr-latest.sh"
docker exec overleaf-sharelatex sh update-tlmgr-latest.sh

docker exec overleaf-sharelatex tlmgr install scheme-full

docker commit overleaf-sharelatex sharelatex/sharelatex:with-texlive-full

# Uncomment the docker-compose.override.yml file
if grep -q -E "^#image: sharelatex/sharelatex:with-texlive-full" "$HOME/overleaf/config/docker-compose.override.yml"; then
    sed -i -E "s/^#image: sharelatex/sharelatex:with-texlive-full$/image: sharelatex/sharelatex:with-texlive-full/" $HOME/overleaf/config/docker-compose.override.yml
fi

# Finalise the setup
bin/stop
yes | bin/docker-compose rm sharelatex
nohup bin/up &

echo "Setup is complete. Overleaf is running with TeXlive full scheme."
