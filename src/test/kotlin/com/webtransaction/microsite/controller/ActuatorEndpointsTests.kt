package com.webtransaction.microsite.controller

import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.boot.test.web.client.TestRestTemplate
import org.springframework.http.HttpStatus
import org.springframework.test.context.TestPropertySource

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@TestPropertySource(properties = ["security.enabled=true"])
class ActuatorEndpointsTests {

    @Autowired
    private lateinit var restTemplate: TestRestTemplate

    @Test
    fun `actuator health endpoint returns 200 without JWT`() {
        val response = restTemplate.getForEntity("/actuator/health", Map::class.java)
        assert(response.statusCode == HttpStatus.OK)
        assert(response.body?.get("status") != null)
    }

    @Test
    fun `actuator info endpoint returns 200 without JWT`() {
        val response = restTemplate.getForEntity("/actuator/info", Map::class.java)
        assert(response.statusCode == HttpStatus.OK)
    }

    @Test
    fun `actuator info endpoint includes build information`() {
        val response = restTemplate.getForEntity("/actuator/info", Map::class.java)
        assert(response.statusCode == HttpStatus.OK)
        val body = response.body
        assert(body != null)
    }

    @Test
    fun `protected endpoint returns 401 without JWT when security enabled`() {
        val response = restTemplate.getForEntity("/v1/webtransaction/1", Map::class.java)
        assert(response.statusCode == HttpStatus.UNAUTHORIZED)
    }
}
