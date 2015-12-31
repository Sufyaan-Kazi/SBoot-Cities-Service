#!/bin/bash 
set -e 
# set -vx

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
BASE_APP=$APPNAME

cf target
cf apps

echo_msg "Detecting Original Route"
# Fetch current apps and
# 1) Filter out ones with our app name
# 2) Removing trailing spaces
# 3) replace the space character in the separator between route names
# 4) Grab the last part of string (i.e. just the routes of the apps)
# 5) Split multiple routes into separate lines
# 6) Remove the domain
OLD_ROUTES=`cf apps | grep $APPNAME | sed -e 's/[[:space:]]*$//' | sed "s/, /,/" | rev | cut -d" " -f1 | rev | tr , '\n' | cut -d "." -f1`
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
if [ ! "$OLD-ROUTE" ]; then
  echo "Could not determine previous route!!"
  exit 1
fi

DATE=`date "+%Y%m%d%H%M%S"`
APPNAME=$APPNAME-$DATE

#Push the new version
echo_msg "Pushing new App Version"
cf push $APPNAME -b java_buildpack_offline
DOMAIN=`cf target | grep "API" | cut -d" " -f5 | sed "s/[^.]*.//"`
cf map-route $APPNAME $DOMAIN -n $OLD_ROUTE
echo_msg "Route mapped to old and new version of Application"
cf apps

echo "Temp sleep in script for demo purposes only........."
sleep 10

#Remove the old version
echo_msg "Removing previous versions"
APPS_TO_DELETE=`cf apps | grep $BASE_APP | cut -d" " -f1 | grep -v $APPNAME`
for APP_TO_DELETE in ${APPS_TO_DELETE[@]}
do
  cf delete -f $APP_TO_DELETE
done
echo_msg "Removing orphaned routes"
cf delete-orphaned-routes -f
cf apps

trap : 0

echo_msg "Blue/Green Promotion Complete in $SECONDS seconds."
