dependencies=()

build() {
    DDEP_VERSION=$(get_config_value DDEP_VERSION) || exit 1

    if [ "$DDEP_VERSION" = "master" ]; then
        wget -nc https://github.com/Arnau478/ddep/archive/refs/heads/master.tar.gz
        tar -xf master.tar.gz
        cd ddep-master
    else
        wget -nc https://github.com/Arnau478/ddep/archive/refs/tags/v$DDEP_VERSION.tar.gz
        tar -xf v$DDEP_VERSION.tar.gz
        cd ddep-$DDEP_VERSION
    fi

    zig build -Doptimize=ReleaseSmall -Dtarget=x86_64-linux
    cp zig-out/bin/ddep $OUT/usr/bin/ddep
}
