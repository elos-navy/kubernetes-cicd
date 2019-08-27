#!/bin/bash

# This wrapper is usefull for troubleshooting bootstrap script output
# and parameters (stored in /deploy.sh file). It also checks bootstrap
# script return value for errors.

{
  ORIG_PARAMS=$@
  GIT_BRANCH='master'

  # GIT branch parameter is needed to switch to correct branch after repo
  # is cloned so correct bootstrap script is executed.
  while [[ $# > 0 ]]
  do
    KEY="$1"
    shift
    case "$KEY" in
      --git_branch)
        GIT_BRANCH="$1"
        shift
        ;;
      *)
        shift
        ;;
    esac
  done

  cd /root
  git clone https://github.com/elos-tech/kubernetes-cicd.git
  git checkout $GIT_BRANCH
  cd kubernetes-cicd

  # Just for troubleshooting.
  echo ./scripts/aks/bootstrap.sh "$ORIG_PARAMS" > /deploy.sh
  chmod +x /deploy.sh

  echo EMPTY > /http_application_routing_zone
} &> /dev/null

sudo -u root ./scripts/aks/bootstrap.sh "$ORIG_PARAMS" &> /deployment.log

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
