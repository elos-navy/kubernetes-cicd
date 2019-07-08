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

# In case bootstrap script will fail, this script deployment should fail too.
# This will result in failed deployment in user portal.
if [ $? -ne 0 ]; then
  echo '_DEPLOYMENT_ERROR_'
  exit 1
fi

# Stdout should go to ARM deployment output. This must be the only output
# of this script! It's processed by ARM template creation process and used
# for providing application domain to output for user.
cat /http_application_routing_zone
