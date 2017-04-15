FROM ubuntu:16.04

ARG branch=master
ARG version
ENV imgDir /var/spool/cloudkeeper/images/

LABEL application="cloudkeeper" \
      description="A tool for synchronizing appliances between AppDB and CMFs" \
      maintainer="kimle@cesnet.cz" \
      version=${version} \
      branch=${branch}

SHELL ["/bin/bash", "-c"]

# update + dependencies
RUN apt-get update && \
    apt-get --assume-yes upgrade && \
    apt-get --assume-yes install ruby qemu-utils curl nginx file

# EGI trust anchors
RUN set -o pipefail && \
    curl -s https://dist.eugridpma.info/distribution/igtf/current/GPG-KEY-EUGridPMA-RPM-3 | apt-key add - && \
    echo $'#### EGI Trust Anchor Distribution ####\n\
deb http://repository.egi.eu/sw/production/cas/1/current egi-igtf core' > /etc/apt/sources.list.d/egi.list && \
    apt-get update && \
    apt-get --assume-yes install ca-policy-egi-core

# cloudkeeper
RUN gem install cloudkeeper -v ${version} --no-document

# env
RUN mkdir -p ${imgDir} /var/run/cloudkeeper/ /var/log/cloudkeeper/ /var/lock/cloudkeeper/

VOLUME ${imgDir}

EXPOSE 7300-7400

ENTRYPOINT ["cloudkeeper"]
