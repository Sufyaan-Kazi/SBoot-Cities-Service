# This push will be slow because we are inserting about 40k city records into the db on initialisation
first_time()
{
  cf target
  ./gradlew build -x test
  cf delete -f cities
  cf delete-service -f MyDB
  cf create-service p-mysql 100mb-dev MyDB
  cf push -b java_buildpack_offline
}

first_time
