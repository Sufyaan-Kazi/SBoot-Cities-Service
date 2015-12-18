# SBoot-Cities-Service
This microservice runs on a local machine or on Cloud Foundry.

This is a very simple Spring Boot project to demonstrate how small a footprint of code is required to create a webserivce which does CRUD operations on data in a database. It expose several REST endpoints for doing CRUD operations on data within a database table.  

###Runnign locally!
Assuming you have access to a database server (e.g. MySQL) or one running on your local machine, this microservice will run immediately on your desktop, within eclipse, standlone etc. Just create an empty database and amend the application.yml file to point to that db.

###Cloud Foundry!
Because Spring Boot is opinionated, it automatically binds this app to the correct datasoruces within your Cloud Foundry space. Hence you just need to create a Service Instance of your preferred db in the space you will be pushing your application. For convenience two shell scripts have been written to do a build and configure of the service instance for you.

If you've never heard of Cloud Foundry - use it! This app is very simple to construct, as soon as you deploy it to Cloud Foundry your entire support infrastructure, app server, libraries etc are configured loaded and deployed within 2 minutes - push this application to our trial instance of cloud foundry at run.pivotal.io

###Usage!
When you run this app locally or on CF you can access it using several REStful endpoints. e.g. when running locally:
* http://localhost:8080/cities - returns a single page JSON listing cities (20 cities in a page)
* http://localhost:8080/cities?page=2&size=5&sort=fales - returns only FIVE results from the SECOND page
* http://localhost:8080/cities/search/name?q=ASJUNTAS - returns a list of cities named ADJUNTAS
* http://localhost:8080/cities/searc/nameContains?q=WASH&size=3 - returns the first three results of the search to find any cities with a name contianng the word "WASH" (case insensitive search)

###Achitecture!
This app is very simple:
* SBootCitiesAplication.java - simple class which alows you to run this class as a regular java app. Spring Boot will automaticaly configure and deploy tomcat even though you launch a regular java app.
* City.java - This class uses JPA to bind to a database table called city. The table is where city data is held, it;s very simple and this class maps java fields to the colun names.
* CityRepository.java - This "interface" declares both restful endpoints as well as define SQL operations. Spring Boot and Spring Web automatically register typical DB endpoints for CRUD operations without the need to edit web.xml or any other configuration. Spring also automagically builds the right SQL queries to search, update, insert and retirve data from the database by automatically interpreting method names into real logic. This class also returns results as pages (i.e. 20 results at a time, but this can be tweaked using paramters to RESTFUL calls.
* WebController.java (optional) - This class isn't necessary, however it exposes a new REST endpoint 'cities_all' which lists all cities with no paging or size control options
* DataSourceConfig.java (optional) - This class isn't necessary, however it allows you to run this application locally on your Mac, desktop etc - it will bound your app to a local MySQL Server. You can use hibernate very easily instead, see the original project this is forked from.

Note: This is a FORK of https://github.com/cf-platform-eng/spring-boot-cities - in time I will do a pull request!

###Can I get some metrics!
....actuator ...

###How is data loaded!
....flyway or hibernate, choice is yours ...

###Wait, I want a GUI!
There is a separate application which can be used as a GUI to consume the data deleivred by this Microservice here: https://github.com/skazi-pivotal/spring-boot-cities-ui or feel free to write your own, using that as a guide.

###Tell me more
Spring Boot is designed to get you up and running quickly and it is opinioated, so explain:

* I have not needed to define a long list of libraries, in my build.gradle I add a dependency on Spring Boot and then dependencies on specific spring-boot starter projects
* I have not needed to configure endpoints in my web.xml or configure more detail about which endpoints exists, my CityRepository class automaticaly exposes these as endpoints because of the @RestRepository endpoints
* I have not needed to define any SQL queries, the methods I list in the repository class are automatically interpreted into queires because of the way I define them -> findByNameIgnoreCase (findBy<field in my entityy><type of find>)
* I have not needed to build a mapping config file between java and the db - this is handled by a few simple annotations
* I have not needed to hard code db parameters. These are "injected" at runtime using the DataSoruceConfig class (it is labelled with a specific @Profile), or just injected by Boot immeidatelty when running in Pivotal Cloud Foundry.
* I have not needed to write nay code to locate or parse properties files, Spring Boot just knows where to read it.
