#!/bin/bash

cd /root
git clone https://github.com/elos-tech/kubernetes-cicd.git
cd kubernetes-cicd
echo "./scripts/bootstrap.sh $@" > /deploy.sh
./scripts/bootstrap.sh "$@"
