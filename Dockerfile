FROM ubuntu:14.04

ENV AGENT_DIR  /opt/buildAgent
ENV NODE_VERSION 8.5.0


RUN  apt-get update \
  && apt-get upgrade -y \
	&& apt-get install -y --no-install-recommends \
		apt-transport-https lxc iptables aufs-tools ca-certificates curl wget software-properties-common language-pack-en \
  && add-apt-repository ppa:ansible/ansible \
  && apt-get install -y  unzip iptables lxc fontconfig libffi-dev  git libssl-dev python-pip ansible  postgresql-client-9.3 \
	&& rm -rf /var/lib/apt/lists/*

RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

RUN apt-get update \
  && apt-get install -y nodejs yarn \
	&& rm -rf /var/lib/apt/lists/*
# RUN apt-get update && apt-get install yarn

# Fix locale.
ENV LANG en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
RUN locale-gen en_US && update-locale LANG=en_US.UTF-8 LC_CTYPE=en_US.UTF-8

# grab gosu for easy step-down from root
RUN gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
RUN curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.6/gosu-$(dpkg --print-architecture)" \
	&& curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/1.6/gosu-$(dpkg --print-architecture).asc" \
	&& gpg --verify /usr/local/bin/gosu.asc \
	&& rm /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu

# Install java-8-oracle
RUN echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections \
	&& echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections \
	&& add-apt-repository -y ppa:webupd8team/java \
	&& apt-get update \
  && apt-get install -y --no-install-recommends \
     oracle-java8-installer ca-certificates-java \
     imagemagick ghostscript \
     libcairo2-dev libjpeg-dev libpango1.0-dev libgif-dev build-essential g++ \
  && rm -rf /var/lib/apt/lists/* /var/cache/oracle-jdk8-installer/*.tar.gz /usr/lib/jvm/java-8-oracle/src.zip /usr/lib/jvm/java-8-oracle/javafx-src.zip \
      /usr/lib/jvm/java-8-oracle/jre/lib/security/cacerts \
  && ln -s /etc/ssl/certs/java/cacerts /usr/lib/jvm/java-8-oracle/jre/lib/security/cacerts \
  && update-ca-certificates

# Install docker
RUN wget -O /usr/local/bin/docker https://get.docker.com/builds/Linux/x86_64/docker-1.10.1 && chmod +x /usr/local/bin/docker

RUN groupadd docker && adduser --disabled-password --gecos "" teamcity \
	&& sed -i -e "s/%sudo.*$/%sudo ALL=(ALL:ALL) NOPASSWD:ALL/" /etc/sudoers \
	&& usermod -a -G docker,sudo teamcity

# Install jq (from github, repo contains ancient version)
RUN curl -o /usr/local/bin/jq -SL https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 \ 
	&& chmod +x /usr/local/bin/jq

# Install nodejs (from official node dockerfile)


RUN pip install --upgrade awscli
#RUN pip install --upgrade pyopenssl pyasn1 ndg-httpsclient httpie awscli docker-compose==1.6.0

# Install the magic wrapper.
ADD wrapdocker /usr/local/bin/wrapdocker

ADD docker-entrypoint.sh /docker-entrypoint.sh

RUN chown -R teamcity /home/teamcity

ENTRYPOINT ["/docker-entrypoint.sh"]

VOLUME /var/lib/docker
VOLUME /opt/buildAgent


RUN apt-get update \
  && apt-get install -y librsvg2-bin \
	&& rm -rf /var/lib/apt/lists/*
EXPOSE 9090
