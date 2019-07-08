#!/bin/bash

TMPDIR=$(mktemp -d)
ZIPFILE='/tmp/cicd-app-marketplace.zip'

cp azure/azuredeploy.json.nosecrets ${TMPDIR}/mainTemplate.json
cp azure/createUIDefinition.json ${TMPDIR}/
cp -r azure/nested ${TMPDIR}/

zip -r -D ${ZIPFILE} ${TMPDIR}

rm -rf ${TMPDIR}

echo
echo "Created ZIP file: ${ZIPFILE}"
