# SBoot-Cities-Service
Simple Spring Boot project to show cities data

This is a FORK of https://github.com/cf-platform-eng/spring-boot-cities - in time I will do a pull request!

This projects is a Spring Boot Application which uses a @RestController class to expose JPA repository methods over a cities db as restful endpoints.

The application uses Flyway to construct and populate the initial 'city' database table, alternatively this can be hibernate, just uncomment the properties in the application.properties.

This application retriees data feom the table and exposes it as HATEOS JSON e,g,

http://........./cities/search/nameContains?q=WASH

will fetch cities with WASH in the name. In adition, you can add page= and size=.
