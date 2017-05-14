#!/bin/bash

set -e

function build_wheel {
    echo `pwd`
    echo CFLAGS=${CFLAGS}
    echo CXXFLAGS=${CXXFLAGS}
    echo LDFLAGS=${LDFLAGS}
    pushd $1

	wget --no-check-certificate http://downloads.sourceforge.net/project/boost/boost/1.60.0/boost_1_60_0.tar.gz -O boost_1_60_0.tar.gz
	tar xf boost_1_60_0.tar.gz
    pushd boost_1_60_0
    ./bootstrap.sh
    ./bjam "cxxflags=-fPIC ${CFLAGS}" cflags="-fPIC ${CXXFLAGS}" --prefix=/usr/local --with-filesystem --with-date_time --with-system --with-regex install
    popd

    # export CFLAGS="-arch x86_64"
    # export CXXFLAGS="-arch x86_64"
    export ARROW_HOME=/usr/local/
    export PARQUET_HOME=/usr/local/
    pip install cython==0.25.2 numpy==${NP_TEST_DEP}
    pushd cpp
    mkdir build
    pushd build
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$ARROW_HOME -DARROW_BUILD_TESTS=OFF -DARROW_BUILD_SHARED=ON -DARROW_BOOST_USE_SHARED=OFF -DARROW_JEMALLOC=ON -DARROW_RPATH_ORIGIN=ON -DARROW_JEMALLOC_USE_SHARED=OFF -DARROW_PYTHON=ON ..
    make -j5
    make install
    popd
    popd

    git clone https://github.com/apache/parquet-cpp.git
    pushd parquet-cpp
    mkdir build
    pushd build
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$PARQUET_HOME -DPARQUET_BUILD_TESTS=OFF -DPARQUET_ARROW=ON -DPARQUET_BOOST_USE_SHARED=OFF ..
    make -j5
    make install
    popd
    popd

    unset ARROW_HOME
    export PYARROW_WITH_PARQUET=1
    export PYARROW_WITH_JEMALLOC=1
    export PYARROW_BUNDLE_ARROW_CPP=1
    export PYARROW_BUILD_TYPE='release'
    pushd python
    echo "python setup.py build_ext --inplace --with-parquet --with-jemalloc --bundle-arrow-cpp"
    python setup.py build_ext --inplace --with-parquet --with-jemalloc --bundle-arrow-cpp
    python setup.py bdist_wheel
    ls -l dist/
    popd
}
