#!/bin/bash

cd /root
git clone https://github.com/elos-tech/kubernetes-cicd.git
cd kubernetes-cicd
#./scripts/bootstrap.sh "$@"

echo ./scripts/bootstrap.sh "$@" > /deploy.sh
chmod +x /deploy.sh
