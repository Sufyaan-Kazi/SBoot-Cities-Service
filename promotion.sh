#!/bin/bash 
set -e 

abort()
{
    echo >&2 '
    ***************
    *** ABORTED ***
    ***************
    '
    echo "An error occurred. Exiting..." >&2
    exit 1
}

echo_msg()
{
  echo ""
  echo "************** ${1} **************"
}

SECONDS=0

trap 'abort' 0

echo_msg "Performing Build"
./gradlew build 
APPNAME=cities

cf target

echo_msg "Detecting Original Route"
OLD_ROUTES=`cf apps | grep $APPNAME | cut -d"," -f2 | cut -d"." -f1`
for A_ROUTE in ${OLD_ROUTES[@]}
do
  if [[ $A_ROUTE != *$APPNAME* ]]; then
      continue
  fi
  A_ROUTE=`echo $A_ROUTE | xargs`
  if ! [[ $A_ROUTE =~ [0-9] ]]; then
      OLD_ROUTE=$A_ROUTE
      break
    else
      OLD_ROUTE="" 
  fi
done
echo "OLD ROUTE IS $OLD_ROUTE"

DATE=`date "+%Y%m%d%H%M%S"`
APPNAME=$APPNAME-$DATE

#Push the new version
echo_msg "Pushing new App Version"
#If old route was blnak - need to create one by setting random_route - but 
#we will ignore this for now as this script is usally run in controlled manner where there will be a route
cf push $APPNAME -b java_buildpack_offline
DOMAIN=`cf target | grep "API" | cut -d" " -f5 | sed "s/[^.]*.//"`
cf map-route $APPNAME $DOMAIN -n $OLD_ROUTE
echo_msg "Route mapped to old and new version of Application"
cf apps

echo "Temp sleep in script for demo purposes only........."
sleep 10

#Remove the old version
echo_msg "Removing previous versions"
APPS_TO_DELETE=`cf apps | grep $OLD_ROUTE | cut -d" " -f1 | grep -v $APPNAME`
for APP_TO_DELETE in ${APPS_TO_DELETE[@]}
do
  cf delete -f $APP_TO_DELETE
done
echo_msg "Removing orphaned routes"
cf delete-orphaned-routes -f

trap : 0

echo_msg "Blue/Green Promotion Complete in $SECONDS seconds."
