FROM alpine as jre

LABEL AUTHOR="Alex Sorkin alexander.sorkin@gmail.com"

ENV JAVA_HOME=/usr/lib/jvm/java-1.8-openjdk/jre
ENV PATH=${PATH}:${JAVA_HOME}/bin

# Install common packages
RUN echo "ipv6" >> /etc/modules && \
    apk --no-cache --no-progress update && \
    apk --no-cache --no-progress add \
      bash openjdk8-jre-base openssl linux-pam ca-certificates \
      make wget curl bc tar gzip python2 && \
    export TINI_VERSION=`curl -s https://github.com/krallin/tini/releases/latest|grep -Eo "[[:digit:]]{1,2}"|xargs|sed 's/\ /./g'` && \
    echo "Tini Supervisor Version: ${TINI_VERSION}" && \
    curl -o /bin/tini -fsSL https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini-static-amd64 && \
    chmod +x /bin/tini

# Install glibc packages
ENV GLIBC_RELEASE_URL=https://github.com/sgerrand/alpine-pkg-glibc/releases

RUN curl -sSL -o /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
    export GLIBC_MAJOR=`curl -sS ${GLIBC_RELEASE_URL}/latest|grep -Eo "[[:digit:]]{1,2}"|head -2|xargs|sed "s#\ #.#g"` && \ 
    export GLIBC_MINOR=`curl -sS ${GLIBC_RELEASE_URL}/latest|grep -Eo "[[:digit:]]{1,2}"|head -3|tail -1|xargs echo r|sed "s#\ ##g"` && \
    export GLIBC_VERSION="${GLIBC_MAJOR}-${GLIBC_MINOR}" && \
    echo "Glibc Version: ${GLIBC_VERSION}" && \
    wget -q -O /tmp/glibc.apk ${GLIBC_RELEASE_URL}/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk && \
    wget -q -O /tmp/glibc-bin.apk ${GLIBC_RELEASE_URL}/download/${GLIBC_VERSION}/glibc-bin-${GLIBC_VERSION}.apk && \
    wget -q -O /tmp/glibc-i18n.apk ${GLIBC_RELEASE_URL}/download/${GLIBC_VERSION}/glibc-i18n-${GLIBC_VERSION}.apk && \
    apk --no-cache --no-progress add /tmp/glibc.apk /tmp/glibc-bin.apk /tmp/glibc-i18n.apk && \
    rm -rf /tmp/glibc.apk /tmp/glibc-bin.apk /tmp/glibc-i18n.apk

FROM jre as jdk

LABEL AUTHOR="Alex Sorkin alexander.sorkin@gmail.com"

ENV JAVA_HOME=/usr/lib/jvm/java-1.8-openjdk
ENV PATH=${PATH}:${JAVA_HOME}/bin

# Install openjdk package
RUN apk --no-cache --no-progress add \
      openjdk8

ARG MAVEN_VERSION=3.5.4
ARG USER_HOME_DIR="/root"
ARG BASE_URL=https://apache.osuosl.org/maven/maven-3/${MAVEN_VERSION}/binaries

RUN mkdir -p /usr/share/maven /usr/share/maven/ref \
  && curl -fsSL -o /tmp/apache-maven.tar.gz ${BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  && tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
  && rm -f /tmp/apache-maven.tar.gz \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"

FROM jre as archiva

LABEL AUTHOR="Alex Sorkin alexander.sorkin@gmail.com"

ARG ARCHIVA_VERSION=2.2.3
ARG ARCHIVA_DOWNLOAD_URL=http://apache.spd.co.il/archiva/${ARCHIVA_VERSION}/binaries/apache-archiva-${ARCHIVA_VERSION}-bin.tar.gz

ENV WRAPPER_BITS=64

RUN curl -sSL -o /tmp/apache-archiva.tar.gz $ARCHIVA_DOWNLOAD_URL && \
    tar -zxf /tmp/apache-archiva.tar.gz -C /tmp/ && \
    mv /tmp/apache-archiva-${ARCHIVA_VERSION} /usr/share/archiva && \
    mv /usr/share/archiva/bin/wrapper-linux-x86-64 /usr/share/archiva/bin/wrapper && \
    rm -rf /usr/share/archiva/bin/wrapper-* && \
    chown -R root.root /usr/share/archiva && \
    chmod 750 /usr/share/archiva/bin/* && \
    rm -rf /tmp/apache-archiva.tar.gz

EXPOSE 8080

ENTRYPOINT ["/bin/tini", "--"]
CMD ["/usr/share/archiva/bin/archiva", "console"]

