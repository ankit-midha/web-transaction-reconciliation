package com.webtransaction.microsite.config

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.security.config.annotation.web.builders.HttpSecurity
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity
import org.springframework.security.config.http.SessionCreationPolicy
import org.springframework.security.oauth2.core.DelegatingOAuth2TokenValidator
import org.springframework.security.oauth2.core.OAuth2TokenValidator
import org.springframework.security.oauth2.jwt.Jwt
import org.springframework.security.oauth2.jwt.JwtDecoder
import org.springframework.security.oauth2.jwt.JwtDecoders
import org.springframework.security.oauth2.jwt.JwtValidators
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder
import org.springframework.security.web.SecurityFilterChain

@Configuration
@EnableWebSecurity
@ConditionalOnProperty(name = ["security.enabled"], havingValue = "true", matchIfMissing = true)
class SecurityConfiguration {

    @Bean
    fun securityFilterChain(http: HttpSecurity): SecurityFilterChain {
        http
            .authorizeHttpRequests { authorize ->
                authorize
                    .requestMatchers("/actuator/health", "/actuator/info").permitAll()
                    .requestMatchers("/v1/webtransaction/**").authenticated()
                    .anyRequest().authenticated()
            }
            .oauth2ResourceServer { oauth2 ->
                oauth2.jwt { }
            }
            .sessionManagement { session ->
                session.sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            }
            .csrf { csrf -> csrf.disable() }
        return http.build()
    }

    @Bean
    fun jwtDecoder(
        @org.springframework.beans.factory.annotation.Value("\${spring.security.oauth2.resourceserver.jwt.issuer-uri}")
        issuerUri: String,
        @org.springframework.beans.factory.annotation.Value("\${spring.security.oauth2.resourceserver.jwt.audiences}")
        audience: String
    ): JwtDecoder {
        val jwtDecoder = JwtDecoders.fromIssuerLocation<NimbusJwtDecoder>(issuerUri)
        val audienceValidator: OAuth2TokenValidator<Jwt> = AudienceValidator(audience)
        val withIssuer: OAuth2TokenValidator<Jwt> = JwtValidators.createDefaultWithIssuer(issuerUri)
        val validator: OAuth2TokenValidator<Jwt> = DelegatingOAuth2TokenValidator(withIssuer, audienceValidator)
        jwtDecoder.setJwtValidator(validator)
        return jwtDecoder
    }
}

class AudienceValidator(private val audience: String) : OAuth2TokenValidator<Jwt> {
    override fun validate(jwt: Jwt): org.springframework.security.oauth2.core.OAuth2TokenValidatorResult {
        val audiences = jwt.getClaimAsStringList("aud")
        return if (audiences != null && audiences.contains(audience)) {
            org.springframework.security.oauth2.core.OAuth2TokenValidatorResult.success()
        } else {
            org.springframework.security.oauth2.core.OAuth2TokenValidatorResult.failure(
                org.springframework.security.oauth2.core.OAuth2Error("invalid_token", "The required audience is missing", null)
            )
        }
    }
}
