FROM gradle:8.5-jdk17 AS builder

WORKDIR /app

COPY . .

RUN gradle clean build -x test

# Stage 2: Create the final image

FROM eclipse-temurin:17-jdk-alpine

WORKDIR /app

COPY --from=builder /app/build/libs/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]