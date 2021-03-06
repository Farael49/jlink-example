FROM ubuntu:18.04
RUN addgroup --system spring && adduser --system spring --ingroup spring
USER spring:spring
ARG JAR_FILE=target/*.jar
ARG RUNTIME_FOLDER=custom-jre
COPY ${JAR_FILE} app.jar
COPY ${RUNTIME_FOLDER} /jre
ENTRYPOINT /jre/bin/java -jar app.jar