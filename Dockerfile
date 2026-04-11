# ==========================================
# STAGE 1: Build the Java App using Maven
# ==========================================
FROM maven:3.9.6-eclipse-temurin-17 AS builder
WORKDIR /app

# Copy the pom.xml and source code
COPY pom.xml .
COPY src ./src

# Compile the code and package it into a .jar file (skipping tests to save time)
RUN mvn clean package -DskipTests

# ==========================================
# STAGE 2: Run the App on a lightweight Java environment
# ==========================================
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Copy ONLY the compiled .jar file from the builder stage above
COPY --from=builder /app/target/*.jar app.jar

# Expose the standard web port
EXPOSE 8080

# Start the application
ENTRYPOINT ["java", "-jar", "app.jar"]