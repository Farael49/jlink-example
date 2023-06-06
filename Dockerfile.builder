#could use an openjdk alpine instead, but doing it manually can come handy
FROM alpine:3 as build
RUN wget https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.4.1%2B1/OpenJDK17U-jdk_x64_alpine-linux_hotspot_17.0.4.1_1.tar.gz
RUN mkdir -p /opt/jdk && tar -xzvf OpenJDK17U-jdk_x64_alpine-linux_hotspot_17.0.4.1_1.tar.gz -C /opt/jdk/
RUN mv /opt/jdk/jdk-17.0.4.1+1 /opt/jdk/jdk-17
ENV JAVA_HOME=/opt/jdk/jdk-17
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

FROM alpine:3
COPY --from=build /build/target/*.jar /app.jar
COPY --from=build /custom-jre /opt/jdk/
VOLUME /tmp
EXPOSE 8080
ENTRYPOINT /opt/jdk/bin/java $JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -jar /app.jar
