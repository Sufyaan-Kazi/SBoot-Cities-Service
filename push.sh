#!/bin/bash 
#set -vx
#set -x

set -e

APPNAME=cities
DBSERVICE=MyDB
DISCOVERY=ServiceReg

abort()
{
    if [ "$?" = "0" ]
    then
	return
    else
      echo >&2 '
      ***************
      *** ABORTED ***
      ***************
      '
      echo "An error occurred on line $1. Exiting..." >&2
      exit 1
    fi
}

summary()
{
  echo_msg "Current Apps & Services in CF_SPACE"
  cf apps
  cf services
}

echo_msg()
{
  echo ""
  echo "************** ${1} **************"
}

build()
{
  echo_msg "Building application"
  ./gradlew build 
}

cf_service_delete()
{
  #Were we supplied an App name?
  if [ ! -z "${2}" ]
  then
    EXISTS=`cf services | grep ${1} | grep ${2} | wc -l | xargs`
    if [ $EXISTS -ne 0 ]
    then
      APP=`cf services | grep ${1} | grep ${2} | xargs | cut -d" " -f4`
      cf unbind-service ${APP} ${1}
    fi
  fi

  #Delete the Service Instance
  EXISTS=`cf services | grep ${1} | wc -l | xargs`
  if [ $EXISTS -ne 0 ]
  then
    cf delete-service -f ${1}
  fi
}

delete_previous_apps()
{
  APPS=`cf apps | grep $APPNAME | cut -d" " -f1`
  for app in ${APPS[@]}
  do
    cf delete -f -r $app
  done
  echo_msg "Removing Orphaned Routes"
  cf delete-orphaned-routes -f
}

clean_db()
{
  cf_service_delete $DBSERVICE $APPNAME
}

clean_eureka()
{
  cf_service_delete $DISCOVERY $APPNAME
}

create_service()
{
  service_created=0
  EXISTS=`cf services | grep ${1} | wc -l | xargs`
  if [ $EXISTS -eq 0 ]
  then
    cf create-service ${1} ${2} ${3}
    service_created=1
  fi
}

process_reset_args()
{
  echo_msg "Removing previous deployment (if necessary!)"
  if [[ "${RESET:-unset}" = "app"  || "${RESET:-unset}" = "all" ]]
  then
    delete_previous_apps
  fi

  if [ "${RESET:-unset}" = "eureka" ]
  then
    clean_eureka
  fi

  if [ "${RESET:-unset}" = "db" ]
  then
    clean_db
  fi

  if [[ "${RESET:-unset}" = "services" || "${RESET:-unset}" = "all" ]]
  then
    clean_db
    clean_eureka
  fi
}

get_old_route()
{
  echo_msg "Detecting Original Route"
  # Fetch current apps and
  # 1) Filter out ones with our app name
  # 2) Removing trailing spaces
  # 3) replace the space character in the separator between route names
  # 4) Grab the last part of string (i.e. just the routes of the apps)
  # 5) Split multiple routes into separate lines
  # 6) Remove the domain
  OLD_ROUTES=`cf apps | grep $SRC_APP_NAME | sed -e 's/[[:space:]]*$//' | sed "s/, /,/" | rev | cut -d" " -f1 | rev | tr , '\n' | cut -d "." -f1`
  for A_ROUTE in ${OLD_ROUTES[@]}
  do
    #if [[ $A_ROUTE != *$APPNAME* ]]; then
     #   continue
    #fi
    A_ROUTE=`echo $A_ROUTE | xargs`
    if ! [[ $A_ROUTE =~ [0-9] ]]; then
        OLD_ROUTE=$A_ROUTE
        break
      else
        OLD_ROUTE=""
    fi
  done
  echo "OLD ROUTE IS $OLD_ROUTE"
  if [[ ! "$OLD-ROUTE" || "$OLD_ROUTE" == "" ]]; then
    echo "Could not determine previous route!!"
    exit 1
  fi
}

map_new_routes()
{
  # Add non-unique route for future blue/green deployments
  if [ "$PROMOTE" != "true" ]
  then
    RANDOM_ROUTE=`cf app $APPNAME | grep urls | cut -d":" -f2 | sed "s/-$DATE//" |  cut -d"." -f1 | xargs`
    cf map-route $APPNAME $DOMAIN -n $RANDOM_ROUTE
    return 0
  fi

  # Alternately for app promotion
  cf map-route $APPNAME $DOMAIN -n $OLD_ROUTE
  echo_msg "Route mapped to old and new version of Application"
  cf apps

  echo "Temp sleep in script for demo purposes only........."
  sleep 10

  #Remove the old version
  echo_msg "Removing previous versions"
  APPS_TO_DELETE=`cf apps | grep $SRC_APP_NAME | cut -d" " -f1 | grep -v $APPNAME`
  for APP_TO_DELETE in ${APPS_TO_DELETE[@]}
  do
    cf delete -f $APP_TO_DELETE
  done
  echo_msg "Removing orphaned routes"
  cf delete-orphaned-routes -f
  cf apps
}

push()
{
  #Create Services
  echo_msg "Making initial (temporary) push to PCF"
  create_service p-mysql 100mb-dev $DBSERVICE
  create_service p-service-registry standard $DISCOVERY
  if [ $service_created -eq 1 ]
  then
    # Sleep for service registry
    max=12
    for ((i=1; i<=$max; ++i )) ; do
      echo "Pausing to allow Service Discovery to Initialise.....$i/$max"
      sleep 5
    done
  fi

  # Push App
  echo "Pushing $APPNAME"
  SRC_APP_NAME=$APPNAME
  DATE=`date "+%Y%m%d%H%M%S"`
  APPNAME=$APPNAME-$DATE
  DOMAIN=`cf target | grep "API" | cut -d" " -f5 | sed "s/[^.]*.//"`

  # Is this an app Promotion?
  if [ "$PROMOTE" == "true" ]
  then
    get_old_route
    cf push $APPNAME -b java_buildpack_offline
  else
    # Override the bind to Discovery service in the manifest temporarily
    TEMP_MANIFEST=`grep -v $DISCOVERY manifest.yml > $APPNAME.yml`
    #cat $APPNAME.yml
    cf push $APPNAME -b java_buildpack_offline --random-route -f $APPNAME.yml
    rm -f $APPNAME.yml

    echo_msg "Setting environment for SCS"
    cf set-env $APPNAME CF_TARGET $CF_TARGET

    # Carry on pushing
    echo_msg "Performing restage of PCF of app $APPNAME"
    cf bind-service $APPNAME $DISCOVERY
    cf restage $APPNAME
  fi

  map_new_routes
}

main()
{
  if [ "$SKIP_BUILD" != "true" ]
  then
    build
  fi

  # Work out the CF_TARGET
  CF_TARGET=`cf target | grep "API" | cut -d" " -f5| xargs`
  # Disable PWS until we write the small script to check the name of the java buildpack
  PWS=`echo $CF_TARGET | grep "run.pivotal.io" | wc -l`
  if [ $PWS -ne 0 ]
  then
    echo_msg "This won't run on PWS, please use another environment"
    exit 1
  fi

  process_reset_args

  if [ "$SKIP_PUSH" != "true" ]
  then
    push
  fi
}

check_cli_installed()
{
  #Is the CF CLI installed?
  echo_msg "Targeting the following CF Environment, org and space"
  cf target
  if [ $? -ne 0 ]
  then
    echo_msg "!!!!!! ERROR: You either don't have the CF CLI installed or you are not connected to an Org or Space !!!!!!"
    exit $?
  fi
}

usage ()
{
  echo 'Usage : Script -reset app (Will delete the previous app)'
  echo '               -reset service (Will delete all the previous services)'
  echo '               -reset eureka (Will delete only the previous Eureka service)'
  echo '               -reset db (Will delete only the previous DB service)'
  echo '               -reset all (Will delete all the previous apps and services)'
  echo '               -skipBuild (Skips the build phase)'
  echo '               -skipPush (Skips the push phase)'
  echo '               -promote (Performs a Blue/Green deployment - this overrides reset app, replacing it with reset services)'
  echo '               <NoArgs> (Completely rebuilds from scratch)'
  echo 'e.g. ./push.sh'
  echo '     ./push.sh -reset all'
  echo '     ./push.sh -reset all -skipBuild -skipPush'
  echo '     ./push.sh -promote'
  exit
}

trap 'abort $LINENO' 0
SECONDS=0

# Process input args
RESET="services"
while [ "$1" != "" ]; do
case $1 in
        -reset )       shift
                       RESET=$1
                       ;;
        -usage )       usage
                       ;;
        -? )           usage
                       ;;
        --help )       usage
                       ;;
        -skipBuild )   SKIP_BUILD=true
                       ;;
        -skipPush )    SKIP_PUSH=true
                       ;;
        -promote )     PROMOTE=true
                       ;;
    esac
    shift
done

if [[ -n $PROMOTE && "$PROMOTE" == "true" && -n $RESET ]]
then
  RESET=""
fi

# Do actual work
check_cli_installed
summary
main
summary

#trap : 0

echo_msg "Deployment Complete in $SECONDS seconds."
