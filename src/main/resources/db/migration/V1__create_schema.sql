DROP TABLE IF EXISTS city;

create table city (
	id bigint not null auto_increment,
	county varchar(255),
	latitude varchar(255),
	longitude varchar(255),
	name varchar(255),
	postal_code varchar(255),
	state_code varchar(255),
	primary key (id)
);