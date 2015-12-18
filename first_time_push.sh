# This push will be slow because we are inserting about 40k city records into the db on initialisation
./gradlew build
cf delete -f cities
cf delete-service -f MyDB
cf create-service p-mysql 100mb-dev MyDB
cf push -b java_buildpack_offline
