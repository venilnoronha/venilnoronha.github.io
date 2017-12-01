---
layout: post
title: "Kick start your own Spring Cloud Config Server with MongoDB"
date: 2017-11-04 10:38:00
image: '/assets/img/2017-11-04-kick-start-your-own-spring-cloud-config-server-with-mongodb/banner.jpg'
description: Learn how to start your own Spring Cloud Config Server instance backed with MongoDB.
category: 'distributed systems'
tags:
- open source
- software
- spring
- database
twitter_text: Kick start your own Spring Cloud Config Server with MongoDB.
introduction: Learn how to start your own Spring Cloud Config Server instance backed with MongoDB.
---

Spring Cloud Config Server MongoDB enables the seamless integration of the regular Spring Cloud Config Server with MongoDB to manage external properties for applications across all environments.

## A Simple Config Server

Bootstrapping a configuration server with Spring Cloud Config Server MongoDB is just a matter of the following three steps.

1\. Configure your `pom.xml`:

```xml
<dependencies>
    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-config-server-mongodb</artifactId>
        <version>0.0.2.BUILD-SNAPSHOT</version>
    </dependency>
</dependencies>
<repositories>
    <repository>
        <id>spring-snapshots</id>
        <name>Spring Snapshots</name>
        <url>https://repo.spring.io/libs-snapshot-local</url>
        <snapshots>
            <enabled>true</enabled>
        </snapshots>
    </repository>
    <repository>
        <id>ojo-snapshots</id>
        <name>OJO Snapshots</name>
        <url>https://oss.jfrog.org/artifactory/libs-snapshot</url>
        <snapshots>
            <enabled>true</enabled>
        </snapshots>
    </repository>
</repositories>
```

2\. Create a standard Spring Boot application with the `EnableMongoConfigServer` annotation:

```java
@SpringBootApplication
@EnableMongoConfigServer
public class Application {
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}
```

3\. Configure the application's `spring.data.mongodb.*` properties in `application.yml`:

```yaml
spring:
  data:
    mongodb:
      uri: mongodb://localhost/config-db
```

<br>

## Usage

We can now add configuration documents to MongoDB and access it via the REST API.

1\. Add configuration documents to MongoDB:

```js
    use config-db;

    db.gateway.insert({
      "label": "master",
      "profile": "prod",
      "source": {
        "user": {
          "maxConnections": NumberInt(8),
          "timeoutMs": NumberInt(3600)
        }
      }
    });
```

2\. Access it by invoking `http://localhost:8080/master/gateway-prod.properties`:

```properties
    user.maxConnections: 8
    user.timeoutMs: 3600
```

Spring Cloud Config Client-backed components can be configured to automatically load configuration from MongoDB by leveraging Spring Cloud Config Server MongoDB. See [here](https://github.com/spring-cloud/spring-cloud-config/tree/master/spring-cloud-config-sample) for an example!

-----

Like it? Give the project a [star](https://github.com/spring-cloud-incubator/spring-cloud-config-server-mongodb) on GitHub. You can also comment below. All feedback is welcome!
