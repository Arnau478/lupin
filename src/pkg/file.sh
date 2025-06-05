dependencies=()

build() {
    FILE_VERSION=$(get_config_value FILE_VERSION) || exit 1
    wget -nc https://astron.com/pub/file/file-$FILE_VERSION.tar.gz
    tar -xf file-$FILE_VERSION.tar.gz
    cd file-$FILE_VERSION
    mkdir out
    ./configure --prefix=$(realpath out) LD="musl-gcc" CCFLAGS="-Os" LDFLAGS="-static" --disable-shared --enable-static
    make
    make install
    mv out/bin/file $OUT/usr/bin/file
}
