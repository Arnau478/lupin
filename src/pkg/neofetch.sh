dependencies=(bash)

build() {
    NEOFETCH_VERSION=$(get_config_value NEOFETCH_VERSION) || exit 1
    wget -nc https://github.com/dylanaraps/neofetch/archive/refs/tags/$NEOFETCH_VERSION.tar.gz
    tar -xf $NEOFETCH_VERSION.tar.gz
    cd neofetch-$NEOFETCH_VERSION
    patch neofetch << 'EOFF'
--- neofetch
+++ neofetch
@@ -8428,6 +8428,33 @@ ${c5}  `._.-._.'
 EOF
         ;;
 
+        "Lupin"*)
+            set_colors 3 7
+            read -rd '' ascii_data <<'EOF'
+${c1}         ******
+      *************
+     **************${c2}@@${c1}
+   ***************${c2}@@@@${c1}
+  ****************${c2}@@@@${c1}
+  ****************${c2}@@@@${c1}
+ ********************
+ ********************
+********************
+********************
+********************
+********************
+********************
+ ********************
+ ********************
+  ********************
+  ********************
+   *******************
+     ****************
+      *************
+         ******
+EOF
+        ;;
+
         "mac"* | "Darwin")
             set_colors 2 3 1 1 5 4
             read -rd '' ascii_data <<'EOF'
EOFF
    make PREFIX=$OUT/usr install
}
