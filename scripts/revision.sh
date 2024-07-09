#!/bin/bash

ORG=$1
ProxyName=$2
ENV=$3
KEY_FILE=$4
WORKSPACE=$5

echo "ORG: $ORG"
echo "ProxyName: $ProxyName"
echo "ENV: $ENV"
echo "$KEY_FILE"


sudo yum update -y && sudo yum install -y curl python3
curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-468.0.0-linux-x86_64.tar.gz
tar -xf google-cloud-sdk-468.0.0-linux-x86_64.tar.gz
./google-cloud-sdk/install.sh

source google-cloud-sdk/completion.bash.inc
source google-cloud-sdk/path.bash.inc


gcloud init
gcloud version

# Check if the key file exists
if [ ! -f "$KEY_FILE" ]; then
  echo "Service account key file '$KEY_FILE' not found."
  exit 1
fi

# Get the access token from Apigee

gcloud auth activate-service-account --key-file="$KEY_FILE"
access_token=$(gcloud auth print-access-token)

# Check if access token retrieval was successful
if [ -z "$access_token" ]; then
  echo "Failed to obtain access token. Check your Apigee credentials and try again."
  exit 1
fi

# Print the access token
echo "Access Token: $access_token"
echo $access_token > $WORKSPACE/scripts/access_token.txt  
# Get stable_revision_number using access_token
revision_info=$(curl -H "Authorization: Bearer $access_token" "https://apigee.googleapis.com/v1/organizations/$ORG/environments/$ENV/apis/$ProxyName/deployments")

# Check if the curl command was successful
if [ $? -eq 0 ]; then
    # Extract the revision number using jq, handling the case where .deployments is null or empty
    stable_revision=$(echo "$revision_info" | jq -r ".deployments[0]?.revision // null")

    echo "Stable Revision: $stable_revision"
    echo $stable_revision > $WORKSPACE/scripts/stable_revision.txt
else
    # Handle the case where the curl command failed
    echo "Error: Failed to retrieve API deployments."
fi


 
