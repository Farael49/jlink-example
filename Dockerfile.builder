#could use an openjdk alpine instead, but doing it manually can come handy
FROM alpine:3.11.5 as build
RUN wget https://download.java.net/java/early_access/alpine/10/binaries/openjdk-15-ea+10_linux-x64-musl_bin.tar.gz
RUN mkdir -p /opt/jdk && tar -xzvf openjdk-15-ea+10_linux-x64-musl_bin.tar.gz -C /opt/jdk/
ENV JAVA_HOME=/opt/jdk/jdk-15
RUN $JAVA_HOME/bin/jlink --compress=2 --module-path $JAVA_HOME/jmods --add-modules java.base,java.logging,java.xml,java.sql,java.naming,java.desktop,java.management,java.instrument,java.security.jgss --output custom-jre

# fetch maven dependencies
WORKDIR /build
COPY pom.xml pom.xml
COPY mvnw mvnw
COPY .mvn .mvn
RUN sh mvnw -c dependency:go-offline

# build
COPY src src
RUN sh mvnw -c clean package

FROM alpine:3.11.5
COPY --from=build /build/target/*.jar /app.jar
COPY --from=build /custom-jre /opt/jdk/
VOLUME /tmp
EXPOSE 8080
ENTRYPOINT /opt/jdk/bin/java $JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -jar /app.jar