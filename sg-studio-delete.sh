IFS='
'

DOMAIN_ID=`aws sagemaker list-domains | jq '.Domains[0].DomainId' -r`

if [ "null" = "$DOMAIN_ID" ]; then
    echo "Domain not available anymore!"
    exit
fi

APPS=`aws sagemaker list-apps --domain-id-equals $DOMAIN_ID | jq '.Apps[] | select(.Status == "InService")' -c -r`
for app in $APPS; do
    APP_NAME=`echo $app | jq '.AppName' -r`
    APP_TYPE=`echo $app | jq '.AppType' -r`
    USER_PROFILE_NAME=`echo $app | jq '.UserProfileName' -r`

    echo "Deleting $APP_NAME ($APP_TYPE)"
    aws sagemaker delete-app --domain-id $DOMAIN_ID --app-name $APP_NAME --app-type $APP_TYPE --user-profile-name $USER_PROFILE_NAME
done

while true; do
    echo "Waiting the applications to be deleted... $DOMAIN_ID"
    pending=`aws sagemaker list-apps --domain-id-equals $DOMAIN_ID | jq '.Apps[].Status' -r | grep 'Deleted'`
    if [ -z "$pending" ]; then
        echo 'Deleting apps...'
        sleep 1
    else
        echo 'All applications are deleted!'
        break
    fi
done

USER_PROFILES=`aws sagemaker list-user-profiles --domain-id-equals $DOMAIN_ID | jq '.UserProfiles[].UserProfileName' -c -r`
for user in $USER_PROFILES; do
    echo "Deleting $user"
    aws sagemaker delete-user-profile --domain-id $DOMAIN_ID --user-profile-name $user
done

echo "Deleting $DOMAIN_ID"
aws sagemaker delete-domain --domain-id $DOMAIN_ID