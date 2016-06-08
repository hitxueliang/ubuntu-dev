FROM ubuntu:latest
MAINTAINER onerhao@gmail.com

# TODO: change the apt-get mirror in /etc/apt/sources.list and pip mirror in ~/.pip/pip.conf
# otherwise it would be way too slow in China mainland

# change apt-get software respository's mirror url
# heredoc cat << EOF is not supported
RUN cp /etc/apt/sources.list /etc/apt/sources.list.bak && echo "deb http://mirrors.aliyun.com/ubuntu/ xenial main restricted universe multiverse\ndeb http://mirrors.aliyun.com/ubuntu/ xenial-security main restricted universe multiverse\ndeb http://mirrors.aliyun.com/ubuntu/ xenial-updates main restricted universe multiverse\ndeb http://mirrors.aliyun.com/ubuntu/ xenial-proposed main restricted universe multiverse\ndeb http://mirrors.aliyun.com/ubuntu/ xenial-backports main restricted universe multiverse\ndeb-src http://mirrors.aliyun.com/ubuntu/ xenial main restricted universe multiverse\ndeb-src http://mirrors.aliyun.com/ubuntu/ xenial-security main restricted universe multiverse\ndeb-src http://mirrors.aliyun.com/ubuntu/ xenial-updates main restricted universe multiverse\ndeb-src http://mirrors.aliyun.com/ubuntu/ xenial-proposed main restricted universe multiverse\ndeb-src http://mirrors.aliyun.com/ubuntu/ xenial-backports main restricted universe multiverse" > /etc/apt/sources.list

# change pip' mirror url
RUN mkdir ~/.pip && echo "[global]\n#index-urls:  https://pypi.douban.com, https://mirrors.aliyun.com/pypi,\ncheckout https://www.pypi-mirrors.org/ for more available mirror servers\nindex-url = https://pypi.douban.com/simple\ntrusted-host = pypi.douban.com" > ~/.pip/pip.conf

# install basic requirements
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        git \
        curl \
        python-dev \
        python-numpy \
        python-pip \
        python-scipy \
        python3-dev \
        python3-pip \
        software-properties-common

# install caffe
RUN apt-get install -y --no-install-recommends \
        libatlas-base-dev \
        libboost-all-dev \
        libboost-mpi-dev \
        libgflags-dev \
        libgoogle-glog-dev \
        libhdf5-serial-dev \
        libleveldb-dev \
        liblmdb-dev \
        libopencv-dev \
        libprotobuf-dev \
        libsnappy-dev \
        protobuf-compiler


ENV CAFFE_ROOT=/opt/caffe
WORKDIR $CAFFE_ROOT

# FIXME: clone a specific git tag and use ARG instead of ENV once DockerHub supports this.
ENV CLONE_TAG=master

RUN git clone -b ${CLONE_TAG} --depth 1 https://github.com/BVLC/caffe.git . && \
    for req in $(cat python/requirements.txt) pydot; do pip install $req; done && \
    mkdir build && cd build && \
    cmake -DCPU_ONLY=1 .. && \
    make -j"$(nproc)"

ENV PYCAFFE_ROOT $CAFFE_ROOT/python
ENV PYTHONPATH $PYCAFFE_ROOT:$PYTHONPATH
ENV PATH $CAFFE_ROOT/build/tools:$PYCAFFE_ROOT:$PATH
RUN echo "$CAFFE_ROOT/build/lib" >> /etc/ld.so.conf.d/caffe.conf && ldconfig


# install tensorflow
ENV TF_BINARY_URL=https://storage.googleapis.com/tensorflow/linux/gpu/tensorflow-0.9.0rc0-cp27-none-linux_x86_64.whl
RUN pip install --upgrade $TF_BINARY_URL

# install torch
ENV TORCH_ROOT=/opt/torch
RUN git clone https://github.com/torch/distro.git $TORCH_ROOT --recursive \
    cd $TORCH_ROOT \
    bash ./install-deps && bash ./install.sh


# install neovim
RUN add-apt-repository ppa:neovim-ppa/unstable -y && apt-get update && apt-get install neovim && \
    update-alternatives --install /usr/bin/vi vi /usr/bin/nvim 60 && \
    update-alternatives --install /usr/bin/vi vi /usr/bin/nvim 60 && \
    update-alternatives --install /usr/bin/vim vim /usr/bin/nvim 60 && \
    update-alternatives --config vim && \
    update-alternatives --install /usr/bin/editor editor /usr/bin/nvim 60 && \
    update-alternatives --config editor

RUN rm -rf /var/lib/apt/lists/*
WORKDIR /workspace


# install scrapy
RUN pip install scrapy scrapyd
