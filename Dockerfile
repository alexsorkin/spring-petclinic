####################### BUILDER STEP ##################################
FROM java:jdk-8-alpine-glibc as builder

LABEL AUTHOR="Alex Sorkin alexander.sorkin@gmail.com"

ARG MIRROR_REPO_URL
ARG MYSQL_URL

# Build dummy karaf profile
WORKDIR /build
COPY ./src ./src
COPY ./pom.xml ./
COPY ./settings.xml ./

RUN mkdir -p ${MAVEN_CONFIG} && \
    echo MIRROR_REPO_URL=${MIRROR_REPO_URL} && \
    if [ "x${MIRROR_REPO_URL}" != "x" ]; then \
      cat ./settings.xml|sed "s#{{ MIRROR_REPO_URL }}#${MIRROR_REPO_URL}#g" > ${MAVEN_CONFIG}/settings.xml \
    ;fi && \
    echo MYSQL_URL=${MYSQL_URL} && \
    if [ "x${MYSQL_URL}" != "x" ]; then \
      cat ./src/main/resources/application-mysql.properties|sed "s#{{ MYSQL_URL }}#${MYSQL_URL}#g" > ./src/main/resources/application.properties \
    ;fi

# Build Engine Distribution
RUN mvn install -DskipTests -Dmaven.test.skip=true


####################### DEPLOYMENT ####################################
FROM java:jre-8-alpine-glibc

# Copy Engine Distribution
COPY --from=builder /build/target/spring-petclinic-2.0.0.BUILD-SNAPSHOT.jar /software/petclinic.jar

EXPOSE 8080

ENTRYPOINT ["/bin/tini", "--"]
CMD ["java","-Djava.security.egd=file:/dev/./urandom", "-jar", "/software/petclinic.jar"]
