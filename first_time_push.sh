#!/bin/bash 

echo_msg()
{
  echo ""
  echo "************** ${1} **************"
}

build()
{
  echo_msg "Building application"
  ./gradlew build -x test
}

cf_app_delete()
{
  EXISTS=`cf apps | grep -c ${1}`
  if [ $EXISTS -ne 0 ]
  then
    cf delete -f ${1}
  fi
}

cf_service_delete()
{
  #Were we supplied an App name?
  if [ ! -z "${2}" ]
  then
    EXISTS=`cf services | grep ${1} | grep -c ${2} `
    if [ $EXISTS -ne 0 ]
    then
      cf unbind-service ${1} ${2}
    fi
  fi

  #Delete the Service Instance
  EXISTS=`cf services | grep -c ${1}`
  if [ $EXISTS -ne 0 ]
  then
    cf delete-service -f ${1}
  fi
}

clean_cf()
{
  echo_msg "Removing previous deployment (if necessary!)"
  cf_app_delete $APPNAME
  cf_service_delete $DBSERVICE $APPNAME
  cf_service_delete $DISCOVERY $APPNAME
}

push()
{
  clean_cf
  echo_msg "Pushing to PCF, it will be slow because we are initialising the database as well"
  cf create-service p-mysql 100mb-dev $DBSERVICE
  cf create-service p-service-registry standard $DISCOVERY
  cf push -b java_buildpack_offline --no-start --no-route
  echo_msg "Setting environment for SCS"
  cf set-env $APPNAME CF_TARGET $CF_TARGET

  # Sleep for service registry
  max=12
  for ((i=1; i<=$max; ++i )) ; do
    echo "Pausing to allow Service Discovery to Initialise.....$i/$max"
    sleep 5
  done

  # Carry on pushing
  echo_msg "Pushing App: $APPNAME!"
  cf push -b java_buildpack_offline
}

main()
{
  APPNAME=cities
  DBSERVICE=MyDB
  DISCOVERY=ServiceReg

  build 

  # Work out the CF_TARGET
  CF_TARGET=`cf target | grep "API" | cut -d" " -f5| xargs`
  PWS=`echo $CF_TARGET | grep -c "run.pivotal.io"`
  if [ $PWS -ne 0 ]
  then
    echo_msg "This won't run on PWS, please use another environment"
    exit 1
  fi

  push
}

check_cli_installed()
{
  #Is the CF CLI installed?
  echo_msg "Targeting the following CF Environment, org and space"
  cf target
  if [ $? -ne 0 ]
  then
    echo_msg "!! ERROR: Please install the CF CLI !!!!!!"
    exit $?
  fi
}

check_cli_installed
main
