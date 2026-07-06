package com.webtransaction.microsite

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication
import org.springframework.data.jpa.repository.config.EnableJpaAuditing
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity

@SpringBootApplication
@EnableJpaAuditing
@EnableMethodSecurity(prePostEnabled = true)
class Application

fun main(args: Array<String>) {
    runApplication<Application>(*args)
}
