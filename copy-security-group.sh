#!/bin/bash

source_group=$1
source_region=$2
target_group=$3
target_region=$4

if [[ -z $source_group || -z $source_region || -z $target_group || -z $target_region ]]; then
    echo 'Usage ./copy.sh $source_group $source_region $target_group $target_region'
    exit -1
fi

aws --region $source_region ec2 describe-security-groups --group-id $source_group > sg.json
ingress=`cat sg.json | jq -c '.SecurityGroups[] | .IpPermissions'`
egress=`cat sg.json | jq -c '.SecurityGroups[] | .IpPermissionsEgress'`

aws ec2 authorize-security-group-ingress --region $target_region --group-id $target_group --ip-permissions $ingress
aws ec2 authorize-security-group-egress --region $target_region --group-id $target_group --ip-permissions $egress

rm -rf sg.json
