#
# Dockerfile for building C++ project
#
# https://github.com/tatsy/dockerfile/ubuntu/cxx
#

# OS image
FROM ubuntu:16.04

MAINTAINER gmedders "https://github.com/gmedders"

# Install gcc-8 and g++-8
RUN apt-get update --no-install-recommends -y \
    && apt-get upgrade --no-install-recommends -y \
    && apt-get dist-upgrade --no-install-recommends -y \
    && apt-get install build-essential software-properties-common --no-install-recommends -y \
    && add-apt-repository ppa:ubuntu-toolchain-r/test -y \
    && apt-get update --no-install-recommends -y \
    && apt-get install gcc-8 g++-8 gfortran-8 --no-install-recommends -y \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 60 --slave /usr/bin/g++ g++ /usr/bin/g++-8 \
    && update-alternatives --config gcc \
    && update-alternatives --install /usr/bin/gfortran gfortran /usr/bin/gfortran-8 60 \
    && update-alternatives --config gfortran

# Install other dependencies
RUN apt-get install git wget curl libcurl4-openssl-dev zlib1g-dev --no-install-recommends -y

# Set environment variables.
ENV HOME /root

# Define working directory.
WORKDIR /root

# Define default command.
CMD ["bash"]

# Update CMake to v3.11.3 with ssl-enabled curl
RUN git clone -q --branch=v3.11.3 --depth=1 https://github.com/Kitware/CMake.git \
    && cd CMake \
    && ./bootstrap --system-curl \
    && make -j4 \
    && make install \
    && ldconfig \
    && cd .. \
    && rm -rf CMake \
    && cmake --version

# Install OpenBLAS (required by Lapack and armadillo)
RUN git clone -q --branch=v0.2.20 --depth=1 https://github.com/xianyi/OpenBLAS.git \
    && cd OpenBLAS \
    && make -j4 \
    && make install PREFIX=/usr/local \
    && ldconfig \
    && cd .. \
    && rm -rf OpenBLAS

# Install Current Release of Lapack (required by armadillo)
RUN git clone https://github.com/Reference-LAPACK/lapack-release.git \
    && cd lapack-release \
    && mkdir build && cd build \
    && cmake -DBLAS_LIBRARIES="-L/usr/local/lib -lopenblas" -DBUILD_SHARED_LIBS=ON .. \
    && make -j4 \
    && make install \
    && ldconfig \
    && cd ../.. \
    && rm -rf lapack-release

# Install armadillo
RUN git clone -q --branch=8.400.x --depth=1 https://gitlab.com/conradsnicta/armadillo-code.git \
    && cd armadillo-code \
    && mkdir build && cd build \
    && cmake .. \
    && make -j4 \
    && make install \
    && cd ../.. \
    && rm -rf armadillo-code

# Install fftw3
RUN wget http://www.fftw.org/fftw-3.3.8.tar.gz \
    && tar -xf fftw-3.3.8.tar.gz \
    && cd fftw-3.3.8 \
    && ./configure --prefix=/usr --enable-shared=yes \
    && make -j4 \
    && make install \
    && cd .. \
    && rm -rf fftw-3.3.8 fftw-3.3.8.tar.gz

# Show environments
RUN echo "--- Build Enviroment ---"
RUN ls
RUN gcc --version | grep gcc
RUN g++ --version | grep g++
RUN cmake --version | grep version
RUN echo "------------------------"
