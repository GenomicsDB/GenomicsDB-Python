#!/bin/bash

# The MIT License (MIT)
# Copyright (c) 2024 dātma, inc™
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

set -e

# Install Dependencies
sudo apt-get update
sudo apt-get -y install azure-cli

# Install Azurite
sudo npm install -g azurite
which azurite
echo "azurite version = $(azurite --version)"

AZURITE_DIR=$GITHUB_WORKSPACE/azurite
mkdir -p $AZURITE_DIR
pushd $AZURITE_DIR

# Generate certificates
openssl req -newkey rsa:2048 -x509 -nodes -keyout key.pem -new -out cert.pem -sha256 -days 365 -addext "subjectAltName=IP:127.0.0.1" -subj "/C=CO/ST=ST/L=LO/O=OR/OU=OU/CN=CN"
sudo cp $AZURITE_DIR/cert.pem /usr/local/share/ca-certificates/ca-certificates.crt
sudo update-ca-certificates

# Start azurite
azurite --silent --skipApiVersionCheck --loose --location $AZURITE_DIR --cert cert.pem --key key.pem &> /dev/null &

# Env to run tests
export AZURE_STORAGE_ACCOUNT=devstoreaccount1
export AZURE_STORAGE_KEY=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==
export AZURE_STORAGE_SERVICE_ENDPOINT="https://127.0.0.1:10000/devstoreaccount1"
export REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

# Create container called test as TileDB expects the container to be already created
AZURE_CONNECTION_STRING="DefaultEndpointsProtocol=https;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=https://127.0.0.1:10000/devstoreaccount1;QueueEndpoint=https://127.0.0.1:10001/devstoreaccount1;"
az storage container create -n test --connection-string $AZURE_CONNECTION_STRING

# Setup examples workspace on azurite
tar xzvf $GITHUB_WORKSPACE/test/inputs/sanity.test.tgz -C oldstyle_dir
cd $GITHUB_WORKSPACE/examples
tar xzvf examples_ws.tgz
echo "Azure Storage Blob upload-batch..."
az storage blob upload-batch -d test/ws -s ws --connection-string $AZURE_CONNECTION_STRING
export WORKSPACE=az://test/ws
az storage blob upload-batch -d oldstyle_dir -s oldstyle_dir oldstyle-dir --connection-string $AZURE_CONNECTION_STRING
export  OLDSTYLE_DIR=az://oldstyle
echo "Azure Storage Blob upload-batch DONE"

popd
