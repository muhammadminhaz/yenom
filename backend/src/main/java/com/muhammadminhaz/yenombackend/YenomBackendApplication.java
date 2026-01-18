package com.muhammadminhaz.yenombackend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;

@SpringBootApplication
@EnableCaching
public class YenomBackendApplication {

    public static void main(String[] args) {
        SpringApplication.run(YenomBackendApplication.class, args);
    }

}
