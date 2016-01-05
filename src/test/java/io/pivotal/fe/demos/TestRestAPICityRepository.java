package io.pivotal.fe.demos;

import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;

import java.util.LinkedHashMap;

import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.SpringApplicationConfiguration;
import org.springframework.boot.test.TestRestTemplate;
import org.springframework.boot.test.WebIntegrationTest;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.junit4.SpringJUnit4ClassRunner;
import org.springframework.web.client.RestTemplate;

/**
 * Test inspired by:
 * http://www.jayway.com/2014/07/04/integration-testing-a-spring-boot-
 * application/
 * https://docs.spring.io/spring-boot/docs/current/reference/html/boot-features-
 * testing.html
 * 
 * @author skazi
 */
@RunWith(SpringJUnit4ClassRunner.class)
@SpringApplicationConfiguration(classes = SBootCitiesServiceApplication.class)
//@WebAppConfiguration
@WebIntegrationTest({"server.port:0", "eureka.client.enabled:false"})
public class TestRestAPICityRepository {
	private static final Logger logger = LoggerFactory.getLogger(TestRestAPICityRepository.class);
	RestTemplate restTemplate = new TestRestTemplate();

	@Value("${local.server.port}")
	int port;

	private String url;
	
	@Before
	public void setup() {
		url = "http://localhost:" + port + "/cities";
	}
	
	@Test
	public void canFetchCities() {
		Object apiResponse = restTemplate.getForEntity(url,Object.class);
		assertNotNull(apiResponse);
	}
	
	@Test
	public void canFetchCitiesPaged() {
		Object apiResponse = restTemplate.getForEntity(url + "?page=0&size=2",Object.class);
		assertNotNull(apiResponse);
	}
}
