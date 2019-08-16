FROM ubuntu:18.04
LABEL maintainer="andrsmllr"
LABEL version="1.0"
LABEL description="SystemC (SC) libraries and SystemC verification (SCV) libraries. Comes with compiler and runtime environment."

SHELL ["/bin/bash", "-c"]
USER root:root
WORKDIR /work
ARG SYSTEMC_VERSION=2.3.3
ARG SCV_VERSION=2.0.1

ENV SRC_DIR=/usr/src
ENV SYSTEMC_VERSION=${SYSTEMC_VERSION}
#ENV SYSTEMC_AMS_VERSION=2_0
#ENV SYSTEMC_CCI_VERSION=1_0_0
ENV SCV_VERSION=${SCV_VERSION}
#ENV SYSTEMC_SYNTHESIS_SUBSET_VERSION=1_4_7

ENV CC=gcc
ENV CXX=g++
ENV SYSTEMC_INSTALL_PATH=/opt/systemc-${SYSTEMC_VERSION}
ENV SCV_INSTALL_PATH=/opt/scv-${SCV_VERSION}
ENV CPLUS_INCLUDE_PATH=${CPLUS_INCLUDE_PATH}:${SYSTEMC_INSTALL_PATH}/include
ENV LIBRARY_PATH=${LIBRARY_PATH}:${SYSTEMC_INSTALL_PATH}/lib-linux64
ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${SYSTEMC_INSTALL_PATH}/lib-linux64

RUN apt update -qq \
    && apt install -qq -y \
    build-essential \
    cmake \
    g++ \
    wget \
    perl=5.*

RUN mkdir -p ${SRC_DIR}
# Fetch and build SystemC core library (includes TLM).
WORKDIR ${SRC_DIR}
RUN wget https://www.accellera.org/images/downloads/standards/systemc/systemc-${SYSTEMC_VERSION}.tar.gz \
    && tar -xf ./systemc-${SYSTEMC_VERSION}.tar.gz
RUN cd ./systemc-${SYSTEMC_VERSION} \
    && ./configure --prefix=${SYSTEMC_INSTALL_PATH} \
    && make \
    && make install \
    && make check
ENV SYSTEMC_HOME=${SYSTEMC_INSTALL_PATH}

# Fetch and build SystemC regression tests.
WORKDIR ${SRC_DIR}
RUN wget https://www.accellera.org/images/downloads/standards/systemc/systemc-regressions-${SYSTEMC_VERSION}.tar.gz \
    && tar -xf ./systemc-regressions-${SYSTEMC_VERSION}.tar.gz
RUN cd ./systemc-regressions-${SYSTEMC_VERSION}/tests \
    && ../scripts/verify.pl *

# Fetch and build SystemC verification library.
WORKDIR ${SRC_DIR}
RUN wget https://www.accellera.org/images/downloads/standards/systemc/scv-${SCV_VERSION}.tar.gz \
    && tar -xf ./scv-${SCV_VERSION}.tar.gz
RUN cd ./scv-${SCV_VERSION} \
    && ./configure --prefix=${SCV_INSTALL_PATH} --with-systemc=${SYSTEMC_INSTALL_PATH} \
    && make \
    && make install \
    && make check

