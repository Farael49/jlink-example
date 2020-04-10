#FROM ubuntu:latest
#RUN addgroup --system spring && adduser --system spring --ingroup spring
FROM alpine:3.11.5
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring
ARG JAR_FILE=target/*.jar
ARG RUNTIME_FOLDER=custom-jre
COPY ${JAR_FILE} app.jar
COPY ${RUNTIME_FOLDER} /jre
CMD ["sh", "/jre/bin/java","-jar","app.jar"]