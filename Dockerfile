# VERSION 1.10.9
# AUTHOR: Matthieu "Puckel_" Roisil
# DESCRIPTION: Basic Airflow container
# BUILD: docker build --rm -t puckel/docker-airflow .
# SOURCE: https://github.com/puckel/docker-airflow

FROM python:3.7-slim-buster
LABEL maintainer="WZH"

# Never prompt the user for choices on installation/configuration of packages
ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux

# Airflow
ARG AIRFLOW_VERSION=1.10.9
ARG AIRFLOW_USER_HOME=/usr/local/airflow
ARG AIRFLOW_DEPS=""
ARG PYTHON_DEPS=""
ENV AIRFLOW_HOME=${AIRFLOW_USER_HOME}

# Define en_US.
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
ENV LC_MESSAGES en_US.UTF-8

COPY ./sources.list /etc/apt/
COPY ./instantclient-basic-linux.x64-12.1.0.2.0.zip ./

# Disable noisy "Handling signal" log messages:
# ENV GUNICORN_CMD_ARGS --log-level WARNING

RUN set -ex \
    && buildDeps=' \
        freetds-dev \
        libkrb5-dev \
        libsasl2-dev \
        libssl-dev \
        libffi-dev \
        libpq-dev \
        git \
        unzip \
    ' \
    && apt-get update -yqq \
    && apt-get upgrade -yqq \
    && apt-get install -yqq --no-install-recommends \
        $buildDeps \
        freetds-bin \
        build-essential \
        default-libmysqlclient-dev \
        apt-utils \
        curl \
        rsync \
        netcat \
        locales \
        libaio1 \
        libaio-dev \
    && sed -i 's/^# en_US.UTF-8 UTF-8$/en_US.UTF-8 UTF-8/g' /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
    && useradd -ms /bin/bash -d ${AIRFLOW_USER_HOME} airflow \
    && unzip instantclient-basic-linux.x64-12.1.0.2.0.zip \
    && rm instantclient-basic-linux.x64-12.1.0.2.0.zip \
    && mv instantclient_12_1/ /usr/lib/ \
    && ln /usr/lib/instantclient_12_1/libclntsh.so.12.1 /usr/lib/libclntsh.so \
    && ln /usr/lib/instantclient_12_1/libocci.so.12.1 /usr/lib/libocci.so \
    && ln /usr/lib/instantclient_12_1/libociei.so /usr/lib/libociei.so \
    && ln /usr/lib/instantclient_12_1/libnnz12.so /usr/lib/libnnz12.so \
    && pip install -i https://mirrors.aliyun.com/pypi/simple -U pip setuptools wheel \
    && pip --no-cache-dir install prison==0.1.2 \
    && pip install -i https://mirrors.aliyun.com/pypi/simple cassandra-driver \
    && pip install -i https://mirrors.aliyun.com/pypi/simple pytz \
    && pip install -i https://mirrors.aliyun.com/pypi/simple pyOpenSSL \
    && pip install -i https://mirrors.aliyun.com/pypi/simple ndg-httpsclient \
    && pip install -i https://mirrors.aliyun.com/pypi/simple pyasn1 \
    && pip --no-cache-dir install -i https://mirrors.aliyun.com/pypi/simple asyncpg==0.20.1 cx-Oracle==7.3.0 pyarrow==0.16.0 tables==3.6.1 pymssql~=2.1.1 \
    && pip install -i https://mirrors.aliyun.com/pypi/simple apache-airflow[all]==${AIRFLOW_VERSION} \
    && pip install 'redis==3.2' \
    && if [ -n "${PYTHON_DEPS}" ]; then pip install ${PYTHON_DEPS}; fi \
    && apt-get purge --auto-remove -yqq $buildDeps \
    && apt-get autoremove -yqq --purge \
    && apt-get clean \
    && rm -rf \
        /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/* \
        /usr/share/man \
        /usr/share/doc \
        /usr/share/doc-base

ENV ORACLE_BASE /usr/lib/instantclient_12_1
ENV LD_LIBRARY_PATH /usr/lib/instantclient_12_1
ENV TNS_ADMIN /usr/lib/instantclient_12_1
ENV ORACLE_HOME /usr/lib/instantclient_12_1

COPY ./tnsnames.ora /usr/lib/instantclient_12_1/network/admin/
COPY script/entrypoint.sh /entrypoint.sh
COPY config/airflow.cfg ${AIRFLOW_USER_HOME}/airflow.cfg

RUN chown -R airflow: ${AIRFLOW_USER_HOME}

EXPOSE 8080 5555 8793

USER airflow
WORKDIR ${AIRFLOW_USER_HOME}
ENTRYPOINT ["/entrypoint.sh"]
CMD ["webserver"]
