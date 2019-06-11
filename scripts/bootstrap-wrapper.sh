#!/bin/bash

cd /root
git clone https://github.com/elos-tech/kubernetes-cicd.git
cd kubernetes-cicd

# Just for troubleshooting.
echo ./scripts/bootstrap.sh "$@" > /deploy.sh
chmod +x /deploy.sh

sudo -u root ./scripts/bootstrap.sh "$@" > /deployment.log
