cf target
./gradlew build -x test
cf push -b java_buildpack_offline
