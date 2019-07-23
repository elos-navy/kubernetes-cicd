#!/bin/bash

if [ ! -d 'azure' ]; then
  echo 'Error: Script should be executed from root directory of kubernetes-cicd repo!'
  echo 'Proper usage: ./scripts/aks/create_marketplace_package.sh'
  exit 1
fi

TMPDIR=$(mktemp -d)
ZIPFILE='/tmp/cicd-app-marketplace.zip'

cp azure/azuredeploy.json.nosecrets ${TMPDIR}/mainTemplate.json
cp azure/createUIDefinition.json ${TMPDIR}/
cp -r azure/nested ${TMPDIR}/

cd ${TMPDIR}
zip -r -D ${ZIPFILE} .
cd

rm -rf ${TMPDIR}

echo
echo "Created ZIP file: ${ZIPFILE}"
