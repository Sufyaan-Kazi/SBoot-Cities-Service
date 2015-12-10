package io.pivotal.fe.demos.config;

import javax.sql.DataSource;

import org.springframework.cloud.app.ApplicationInstanceInfo;
import org.springframework.cloud.config.java.AbstractCloudConfig;
import org.springframework.cloud.config.java.ServiceScan;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;

@Configuration
@Profile("cloud")
public class CloudConfig extends AbstractCloudConfig {
    @Bean
    public DataSource dataSource() {
        return connectionFactory().dataSource();
    }
}

//return connectionFactory().dataSource("SufMySQL2");
