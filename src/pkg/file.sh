dependencies=()

build() {
    FILE_VERSION=$(get_config_value FILE_VERSION) || exit 1
    wget -nc https://astron.com/pub/file/file-$FILE_VERSION.tar.gz
    tar -xf file-$FILE_VERSION.tar.gz
    cd file-$FILE_VERSION
    ./configure --prefix=$OUT/usr
    make
    make install
}
