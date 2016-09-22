


#!/bin/bash 
#author by keanli
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=admin
export OS_AUTH_URL=http://10.0.194.100:10006/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2

case $1 in

nova)
     process_status=$($1 service-list  | awk -F '|' '{print  $3 $4 $7}' | grep down | awk '{print $2": "$1}')
if [[ $process_status=" " ]]; then
echo 0
else 
echo $process_status
fi
;; 

neutron)
     process_status=$($1 agent-list | awk -F '|' '{print $4 $7 $5 }' | grep xxx | awk '{print $1 ": "$2 }')
if [[ $process_status=" " ]]; then 
echo 0
else 
echo $process_status
fi 
;;

cinder)
     process_status=$($1 service-list | awk -F '|' '{print $2 $3 $6}' | grep down | awk '{print $2": "$1}' )
if [[ $process_status=" " ]]; then 
echo 0 
else 
    echo $process_status
fi 
;;
esac

