#!/bin/bash

### Make sure that you've set up the Admin account before proceding! ###
########################################################################

# Make sure you're in the proper directory if overleaf is running from ~/overleaf
cd $HOME/overleaf/

# Update the TeXlive packages
docker exec overleaf-sharelatex wget "https://mirror.ctan.org/systems/texlive/tlnet/update-tlmgr-latest.sh"
docker exec overleaf-sharelatex sh update-tlmgr-latest.sh

docker exec sharelatex tlmgr install scheme-full

docker commit overleaf-sharelatex sharelatex/sharelatex:with-texlive-full

# Uncomment the docker-compose.override.yml file
if grep -q -E "^#image: sharelatex/sharelatex:with-texlive-full" "$HOME/config/docker-compose.override.yml"; then
    sed -q -E "s/^#image: sharelatex/sharelatex:with-texlive-full$/image: sharelatex/sharelatex:with-texlive-full/"
fi

# Finalise the setup
bin/stop
bin/docker-compose -rm sharelatex
bin/up

## When you upgrade later, you need to re-comment the line in config/docker-compose.override.yml, delete the container, and do the above steps again.
