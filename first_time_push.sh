#!/bin/bash 
# This push will be slow because we are inserting about 40k city records into the db on initialisation
./gradlew build

echo ""
echo "******** Pushing to PCF *********"
cf delete -f cities
cf delete-service -f MyDB
cf delete-service -f ServiceReg
cf create-service p-mysql 100mb-dev MyDB
cf create-service p-service-registry standard ServiceReg
cf push -b java_buildpack_offline --no-start --no-route
echo ""
echo "Setting environment for SCS"
cf set-env cities CF_TARGET https://apps.emea-2.fe.gopivotal.com
echo ""

# Sleep for service registry
max=12
for ((i=1; i<=$max; ++i )) ;
 do
  echo "Pausing to allow Service Discovery to Initialise....."
  sleep 5
 done

# Carry on pushing
echo ""
echo "Pushing App!"
cf push -b java_buildpack_offline
