#!/bin/bash

source ./scripts/config
source ./scripts/functions

function usage {
  cat <<EOF
Usage: $(basename $0) <option>

Options:
  create_rg
  delete_rg
  create_cluster
  delete_cluster
  create_acr
  delete_acr
  setup_credentials

EOF
}

case $1 in
  create_rg)
    azure_create_rg;;
  delete_rg)
    azure_delete_rg;;
  create_cluster)
    azure_create_cluster;;
  delete_cluster)
    azure_delete_cluster;;
  create_acr)
    azure_create_acr;;
  delete_acr)
    azure_delete_acr;;
  setup_credentials)
    azure_setup_credentials;;
  *)
    usage;;
esac
