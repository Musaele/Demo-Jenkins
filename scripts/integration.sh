#!/bin/bash -eux

deveolper_apps=$(curl -k -H "Authorization: Bearer $access_token" "https://apigee.googleapis.com/v1/organizations/$org/developers/$developer/apps/$app")

client_id=$(jq -r .credentials[].consumerKey <<< "${deveolper_apps}" )
echo "client_id at script: '$client_id'"


client_secret=$(jq -r .credentials[].consumerSecret <<< "${deveolper_apps}" )
echo "client_secret at script: '$client_secret'"

cd $WORKSPACE/test/integration && npm install -g newman && npm install -g newman-reporter-htmlextra && newman run $Newman_Target_Collection --env-var client_id=$client_id --env-var client_secret=$client_secret -r cli,htmlextra --reporter-htmlextra-export ./reports/Newman_Integration_Tests_Report_${BUILD_NUMBER}.html --insecure

# my_client_id = sh(
  # returnStdout: true, 
  # script: 'id'
# )

# my_client_secret = sh(
  # returnStdout: true, 
  # script: 'secret'
# )