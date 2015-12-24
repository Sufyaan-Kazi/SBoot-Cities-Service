#!/bin/bash 
# This push will be slow because we are inserting about 40k city records into the db on initialisation
cf target
./gradlew build -x test
APPNAME=cities
DBSERVICE=MyDB
DISCOVERY=ServiceReg
echo ""
echo "******** Pushing to PCF *********"
cf delete -f $APPNAME
cf delete-service -f $DBSERVICE
cf unbind-service $APPNAME $DISCOVERY
cf delete-service -f $DISCOVERY
cf create-service p-mysql 100mb-dev $DBSERVICE
cf create-service p-service-registry standard $DISCOVERY
cf push -b java_buildpack_offline --no-start --no-route
echo ""
echo "Setting environment for SCS"
cf set-env $APPNAME CF_TARGET https://apps.emea-2.fe.gopivotal.com
echo ""

# Sleep for service registry
max=12
for ((i=1; i<=$max; ++i )) ;
 do
  echo "Pausing to allow Service Discovery to Initialise.....$i/$max"
  sleep 5
 done

# Carry on pushing
echo ""
echo "Pushing App: $APPNAME!"
cf push -b java_buildpack_offline
