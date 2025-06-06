dependencies=()

build() {
    BASH_VERSION=$(get_config_value BASH_VERSION) || exit 1
    wget -nc https://ftpmirror.gnu.org/bash/bash-$BASH_VERSION.tar.gz
    tar -xf bash-$BASH_VERSION.tar.gz

    bash_patch_prefix=$(echo "bash${BASH_VERSION}" | sed -e 's/\.//g')
    patch_url_base="https://ftp.gnu.org/gnu/bash/bash-${BASH_VERSION}-patches"
    wget -q -O - "$patch_url_base/" | \
        grep -o "$bash_patch_prefix-[0-9][0-9][0-9]" | \
        sort -u | \
        while read patch; do
            wget -nc "$patch_url_base/$patch"
            cd bash-$BASH_VERSION
            patch -p0 < "../$patch"
            cd ..
        done

    cd bash-$BASH_VERSION

    patch lib/termcap/tparam.c << 'EOF'
--- tparam.c
+++ tparam.c
@@ -19,6 +19,7 @@
 */
 
 /* Emacs config.h may rename various library functions such as malloc.  */
+#include <unistd.h>
 #ifdef HAVE_CONFIG_H
 #include <config.h>
EOF

    ./configure --without-bash-malloc --enable-static-link LDFLAGS="-static" CFLAGS="-static" --prefix=$OUT/usr
    make -j$(nproc)
    make install 
}
