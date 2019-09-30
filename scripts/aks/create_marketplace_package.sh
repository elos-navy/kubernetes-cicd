#!/bin/bash

if [ ! -d 'azure' ]; then
  echo 'Error: Script should be executed from root directory of kubernetes-cicd repo!'
  echo 'Proper usage: ./scripts/aks/create_marketplace_package.sh'
  exit 1
fi

set -x

TMPDIR=$(mktemp -d)
ZIPFILE='/tmp/cicd-app-marketplace.zip'

cp azure/azuredeploy.json.nosecrets ${TMPDIR}/mainTemplate.json
cp azure/createUiDefinition.json ${TMPDIR}/
cp -r azure/nested ${TMPDIR}/

cd ${TMPDIR}
zip -r -D ${ZIPFILE} .
cd -

rm -rf ${TMPDIR}

set +x

echo
echo "Created ZIP file: ${ZIPFILE}"
