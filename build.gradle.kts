import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

plugins {
    id("org.springframework.boot") version "3.3.12"
    id("io.spring.dependency-management") version "1.1.6"
    kotlin("jvm") version "1.9.23"
    kotlin("plugin.spring") version "1.9.23"
    kotlin("plugin.jpa") version "1.9.23"
    id("org.jlleitschuh.gradle.ktlint") version "12.1.0"
    id("io.gitlab.arturbosch.detekt") version "1.23.5"
    jacoco
}

group = "com.webtransaction"
version = "0.0.1-SNAPSHOT"

java {
    sourceCompatibility = JavaVersion.VERSION_17
}

repositories {
    mavenCentral()
}

dependencies {
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    implementation("org.springframework.boot:spring-boot-starter-validation")
    implementation("org.springframework.boot:spring-boot-starter-actuator")
    implementation("org.springframework.boot:spring-boot-starter-oauth2-resource-server")
    implementation("com.fasterxml.jackson.module:jackson-module-kotlin")
    implementation("org.jetbrains.kotlin:kotlin-reflect")
    implementation("io.hypersistence:hypersistence-utils-hibernate-63:3.7.3")
    runtimeOnly("org.postgresql:postgresql")
    testImplementation("org.springframework.boot:spring-boot-starter-test")
    testImplementation("org.springframework.security:spring-security-test")
    testImplementation("com.h2database:h2")
    testImplementation("io.mockk:mockk:1.13.10")
    testImplementation("com.ninja-squad:springmockk:4.0.2")
    testImplementation("org.jetbrains.kotlin:kotlin-test-junit5")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}

kotlin {
    compilerOptions {
        freeCompilerArgs.addAll("-Xjsr305=strict")
    }
}

tasks.withType<KotlinCompile> {
    kotlinOptions {
        freeCompilerArgs += "-Xjsr305=strict"
        jvmTarget = "17"
    }
}

tasks.withType<Test> {
    useJUnitPlatform()
}

ktlint {
    version.set("1.1.1")
    android.set(false)
    outputToConsole.set(true)
}

detekt {
    buildUponDefaultConfig = true
    config.setFrom(files("detekt.yml"))
}

tasks.jacocoTestReport {
    dependsOn(tasks.test)
    reports {
        xml.required.set(true)
        html.required.set(true)
    }
}

tasks.jacocoTestCoverageVerification {
    dependsOn(tasks.jacocoTestReport)
    violationRules {
        rule {
            limit {
                minimum = "0.95".toBigDecimal()
                counter = "INSTRUCTION"
            }
        }
        rule {
            limit {
                minimum = "0.95".toBigDecimal()
                counter = "LINE"
            }
        }
        rule {
            limit {
                minimum = "0.95".toBigDecimal()
                counter = "METHOD"
            }
        }
        rule {
            limit {
                minimum = "0.95".toBigDecimal()
                counter = "CLASS"
            }
        }
    }
}

tasks.named("check") {
    dependsOn(tasks.jacocoTestCoverageVerification)
}

tasks.named("build") {
    dependsOn(tasks.named("ktlintCheck"))
    dependsOn(tasks.named("detekt"))
}

springBoot {
    buildInfo {
        properties {
            additional.set(
                mapOf(
                    "git.branch" to (System.getenv("GIT_BRANCH") ?: "unknown"),
                    "git.commit" to (System.getenv("GIT_COMMIT") ?: "unknown")
                )
            )
        }
    }
}
