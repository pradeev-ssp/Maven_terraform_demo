package com.example;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
@RestController
public class Application {

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }

    // This tells the server to return this message when someone visits the home page
    @GetMapping("/")
    public String hello() {
        return "Hello from Jenkins, Terraform, and AWS! The CI/CD Pipeline is a SUCCESS!";
    }
}