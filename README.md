# SBoot-Cities-Service
This microservice runs on a local machine or on Cloud Foundry. Note: This is a FORK of https://github.com/cf-platform-eng/spring-boot-cities! Thanks to help and tips from my team, Dave Syer and Scott Frederick in this and other branches :)

This is a very simple Spring Boot project which demonstrates, that with only small a footprint of code its possible to a create complex a webservice which exposes CRUD operations as restful endpoints on data in a database.   

###Running locally!
Assuming you have access to a database server (e.g. MySQL, PostGres) or even have one running on your local machine, this microservice will run immediately on your desktop (within eclipse, standalone etc). Just create an empty database and amend the application.yml file to point to that db.

###Cloud Foundry!
Because Spring Boot is opinionated, it automatically binds this app to the correct datasources within your Cloud Foundry space. Hence you just need to create a Service Instance of your preferred db in the space you will be pushing your application. For convenience two shell scripts have been written to do a build and configure of the service instance for you and deploy to cloud foundry. The app will auto-populate data in the table of the db provisioned by Cloud Foundry - see below.

If you've never heard of Cloud Foundry - use it! This app is very simple to construct, as soon as you deploy it to Cloud Foundry your entire support infrastructure, app server, libraries etc are configured loaded and deployed within 2 minutes - push this application to our trial instance of cloud foundry at run.pivotal.io. This si classic DevOps separation of concerns yet both in harmony together.

###Usage!
When you run this app locally or on CF you can access its features using several RESTful endpoints. Note - thisis only a SMALL sample of the endpoints, this app exposes AHTEOS endpoints. e.g. when running locally:
* <a href="http://localhost:8080/cities" target="_blank">http://localhost:8080/cities</a> - returns a single page JSON listing cities (20 cities in a page)
* <a href="http://localhost:8080/cities?page=2&size=5&sort=false" target="_blank">http://localhost:8080/cities?page=2&size=5&sort=false</a> - returns only FIVE results from the SECOND page
* <a href="http://localhost:8080/cities/search/name?q=ADJUNTAS" target="_blank">http://localhost:8080/cities/search/name?q=ADJUNTAS</a> - returns a list of cities named ADJUNTAS
* <a href="http://localhost:8080/cities/search/nameContains?q=WASH&size=3" target="_blank">http://localhost:8080/cities/search/nameContains?q=WASH&size=3</a> - returns the first three results of the search to find any cities with a name contianng the word "WASH" (case insensitive search)
* <a href="http://localhost:8080/health" target="_blank">http://localhost:8080/health</a> - This returns the current health of the app, it is provided by Spring Boot Actuator. This and all other actuator endpoints that actuator provides are available immediately.

###Achitecture!
This app is very simple, it is ultimately driven by three classes and some properties and thats it.
* SBootCitiesAplication.java - simple class which alows you to run this class as a regular java app. Spring Boot will automaticaly configure and deploy tomcat even though you launch a regular java app. 
* City.java - This class uses JPA to bind to a database table called city. The table is where city data is held, this class maps java fields to the column names and enables Spring Data to dynamically construct instances of the class when it fetches data from the database.
* CityRepository.java - This "interface" declares both restful endpoints as well as defines SQL operations required. Spring Boot and Spring Web automatically register typical DB endpoints for CRUD operations without the need to edit a web.xml or any other configuration files. Spring also "automagically" builds the right SQL queries to search, update, insert and retirve data from the database by automatically interpreting method names into real logic. This class also returns results as pages (i.e. 20 results at a time, but this can be tweaked using paramters to RESTFUL calls.
* WebController.java (optional) - This class isn't necessary, however it exposes a new REST endpoint 'cities_all' which lists all cities with no paging or size control options
* DataSourceConfig.java (optional) - This class isn't necessary, however it allows you to run this application locally on your Mac, desktop etc - it will bound your app to a local MySQL Server. You can use hibernate very easily instead, see the original project this is forked from.

###Can I get some metrics!
Spring Boot Actuator automatically exposes endpoints which allow you to consume useful information such as health, configprops, for more info check this out: https://spring.io/guides/gs/actuator-service/

###How is data loaded!
With Spring, and Spring Boot there are several ways to get an applicaton to initialise and load data automatically into a database on startup. This application uses flyway, but can also use Hibernate. For mor einfor check out this page: https://docs.spring.io/spring-boot/docs/current/reference/html/howto-database-initialization.html

Specifically, this app .... (to be completed)
....flyway or hibernate, choice is yours ...

###Wait, I want a GUI!
There is a separate application which can be used as a GUI to consume the data deleivred by this Microservice here: https://github.com/skazi-pivotal/spring-boot-cities-ui or feel free to write your own, using that as a guide.

###Tell me more
Spring Boot is designed to get you up and running quickly and it is opinioated, so explain:

* I have not needed to define a long list of libraries, in my build.gradle I add a dependency on Spring Boot and then dependencies on specific spring-boot starter projects
* I have not needed to configure endpoints in my web.xml or configure more detail about which endpoints exists, my CityRepository class automaticaly exposes these as endpoints because of the @RestRepository endpoints
* I have not needed to define any SQL queries, the methods I list in the repository class are automatically interpreted into queires because of the way I define them -> findByNameIgnoreCase (findBy<field in my entityy><type of find>)
* I have not needed to build a mapping config file between java and the db - this is handled by a few simple annotations e.g. @Entity
* I have not needed to hard code db parameters. When running locally, these are "injected" at runtime using the DataSourceConfig class (it is labelled with a specific @Profile), or just injected by Boot immediatelty when running in Pivotal Cloud Foundry. This can be tweaked to add db pooling etc (https://spring.io/blog/2015/04/27/binding-to-data-services-with-spring-boot-in-cloud-foundry)
* I have not needed to write any code to locate or parse properties files, Spring Boot just knows where to read it. (https://docs.spring.io/spring-boot/docs/current/reference/html/boot-features-profiles.html)

Do Check out the following URLs:
* https://spring.io/guides
* https://spring.io/guides/gs/rest-service/
* https://spring.io/guides/gs/accessing-data-jpa/
* http://cloud.spring.io/spring-cloud-connectors/spring-cloud-spring-service-connector.html
* http://cloud.spring.io/spring-cloud-connectors/spring-cloud-connectors.html
* https://spring.io/blog/2015/04/27/binding-to-data-services-with-spring-boot-in-cloud-foundry
* http://docs.spring.io/spring-data/data-commons/docs/1.6.1.RELEASE/reference/html/repositories.html
* https://docs.spring.io/spring-boot/docs/current/reference/html/boot-features-profiles.html
