#!/bin/bash

# Define variables
servername="Change this to your liking"
listen_ip="0.0.0.0" # Change this if required
listen_port="80" # By default this port is set to port 80. Change if required for your environment.


# Clone the overleaf toolkit
git clone https://github.com/overleaf/toolkit.git ./overleaf

# Initialise the install
cd overleaf/
bin/init

#modify config/overleaf.rc
echo "PATH=/usr/local/texlive/2023/bin/x86_64-linux:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" >> config/overleaf.rc

if grep -q -E "^OVERLEAF_LISTEN_IP=.*" "config/overleaf.rc"; then
    sed -i -E "s/^OVERLEAF_LISTEN_IP=.*$/OVERLEAF_LISTEN_IP=\"$listen_ip\"/" config/overleaf.rc
fi

if grep -q -E "^OVERLEAF_LISTEN_PORT=." "config/overleaf.rc"; then
    sed -i -E "s/^OVERLEAF_LISTEN_IP=.*$/OVERLEAF_LISTEN_IP=\"$listen_port\"/" config/overleaf.rc
fi

# Change the name of the overleaf instance in variables.env
if grep -q -E "^OVERLEAF_APP_NAME=.*" "config/variables.env"; then
    sed -i -E "s/^OVERLEAF_APP_NAME=.*$/OVERLEAF_APP_NAME=\"$servername\"/" config/variables.env
fi   

# Create docker compose override file, instructions from https://ulysseszh.github.io/guide/2023/09/29/self-host-overleaf.html
cat <<EOF > config/docker-compose.override.yml
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

bin/up


# When you see the overleaf-mongo logs start to crowd the screen, go to <host-IP>/launchpad and set up the admin account before moving on.
# The next steps are in overleaf2.sh. Hit CTRL+C to shut down the overleaf-sharelatex instance
