package io.pivotal.fe.demos;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

@SpringBootApplication
public class SBootCitiesServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(SBootCitiesServiceApplication.class, args);
    }
}
