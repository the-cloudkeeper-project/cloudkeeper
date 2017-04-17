FROM ubuntu:16.04

ARG branch=master
ARG version

ENV name="cloudkeeper"
ENV spoolDir="/var/spool/${name}"
ENV imgDir="${spoolDir}/images" \
    runDir="/var/run/${name}" \
    logDir="/var/log/${name}" \
    lockDir="/var/lock/${name}" \
    nginxLogDir="/var/log/nginx" \
    nginxLibDir="/var/lib/nginx"

LABEL application=${name} \
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
RUN gem install ${name} -v "${version}" --no-document

# env
RUN useradd --system --shell /bin/false --home ${spoolDir} --create-home ${name} && \
    usermod -L ${name} && \
    mkdir -p ${imgDir} ${runDir} ${logDir} ${lockDir} && \
    chown -R ${name}:${name} ${spoolDir} ${runDir} ${logDir} ${lockDir} ${nginxLogDir} ${nginxLibDir}

VOLUME ${imgDir}

EXPOSE 7300-7400

USER ${name}

ENTRYPOINT ["cloudkeeper"]
