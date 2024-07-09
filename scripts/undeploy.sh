#!/bin/bash -eux
my_stable_revision=$1
rev_num=$2
env_name=$3


echo "Current Revision: '$rev_num'"
echo "Current API Name: '$ProxyName'"
echo "Current ORG Name: '$org'"
echo "Current ENV Name: '$ENV'"
# echo $pre_rev
echo "Stable Revision: '$my_stable_revision'"


if [[ "${my_stable_revision}" -eq null ]];
then
	echo "WARNING: Test failed, undeploying and deleting revision $rev_num"

	curl -X DELETE --header "Authorization: Bearer $access_token" "https://apigee.googleapis.com/v1/organizations/$org/environments/$ENV/apis/$ProxyName/revisions/$rev_num/deployments"

	curl -X DELETE --header "Authorization: Bearer $access_token" "https://apigee.googleapis.com/v1/organizations/$org/apis/$ProxyName/revisions/$rev_num"
	
	curl -X DELETE --header "Authorization: Bearer $access_token" "https://apigee.googleapis.com/v1/organizations/$org/apis/$ProxyName"
else
echo "WARNING: Test failed, reverting from $rev_num to $my_stable_revision --- undeploying and deleting revision $rev_num"

curl -X DELETE --header "Authorization: Bearer $access_token" "https://apigee.googleapis.com/v1/organizations/$org/environments/$ENV/apis/$ProxyName/revisions/$rev_num/deployments"

curl -X DELETE --header "Authorization: Bearer $access_token" "https://apigee.googleapis.com/v1/organizations/$org/apis/$ProxyName/revisions/$rev_num"

curl -X POST --header "Content-Type: application/x-www-form-urlencoded" --header "Authorization: Bearer $access_token" "https://apigee.googleapis.com/v1/organizations/$org/environments/$ENV/apis/$ProxyName/revisions/$my_stable_revision/deployments"
fi
