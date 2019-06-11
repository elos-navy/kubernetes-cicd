#!/bin/bash

{
  cd /root
  git clone https://github.com/elos-tech/kubernetes-cicd.git 
  cd kubernetes-cicd

  # Just for troubleshooting.
  echo ./scripts/aks/bootstrap.sh "$@" > /deploy.sh
  chmod +x /deploy.sh

  echo EMPTY > /http_application_routing_zone
} &> /dev/null

sudo -u root ./scripts/aks/bootstrap.sh "$@" &> /deployment.log

# Stdout should go to ARM deployment output. This is the only output
# of this script!
cat /http_application_routing_zone
