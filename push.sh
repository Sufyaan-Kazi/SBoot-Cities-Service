#!/bin/bash 
set -e 

cf target
./gradlew build 
cf push -b java_buildpack_offline
