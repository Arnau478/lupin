dependencies=()

build() {
    FILE_VERSION=$(get_config_value FILE_VERSION) || exit 1
    wget -nc https://astron.com/pub/file/file-$FILE_VERSION.tar.gz
    tar -xf file-$FILE_VERSION.tar.gz
    cd file-$FILE_VERSION
    mkdir out
    ./configure --prefix=/usr --datadir=/usr/share/file CC="zig cc -target x86_64-linux-musl" CCFLAGS="-Os" LDFLAGS="-static" --disable-shared --enable-static
    make
    make DESTDIR=$(realpath out) install
    cp out/usr/bin/file $OUT/usr/bin/file
    cp out/usr/include/magic.h $OUT/usr/include/magic.h
    cp -r out/usr/share/man/* $OUT/usr/share/man
    mkdir -p $OUT/usr/share/file/misc
    cp out/usr/share/file/misc/magic.mgc $OUT/usr/share/file/misc/magic.mgc
}
