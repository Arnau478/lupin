dependencies=()

build() {
    HEVI_VERSION=$(get_config_value HEVI_VERSION) || exit 1
    wget -nc https://github.com/Arnau478/hevi/archive/refs/tags/v$HEVI_VERSION.tar.gz
    tar -xf v$HEVI_VERSION.tar.gz
    cd hevi-$HEVI_VERSION

    case $HEVI_VERSION in
        1.1.0)
            patch build.zig.zon << 'EOF'
--- a
+++ b
@@ -2,6 +2,7 @@
-    .name = "hevi",
+    .name = .hevi,
     .version = "1.1.0",
+    .fingerprint = 0xdcc10eb74ab2196e,
     .dependencies = .{
         .ziggy = .{
-            .url = "git+https://github.com/kristoff-it/ziggy#ae30921d8c98970942d3711553aa66ff907482fe",
-            .hash = "1220c198cdaf6cb73fca6603cc5039046ed10de2e9f884cae9224ff826731df1c68d",
+            .url = "git+https://github.com/kristoff-it/ziggy#af41bdb5b1d64404c2ec7eb1d9de01083c0d2596",
+            .hash = "ziggy-0.1.0-kTg8v7rKBQCdELbScM186Uh4X3sxhBFgsdNpYcilLhDt",
EOF
            patch src/main.zig << 'EOF'
--- src/main.zig
+++ src/main.zig
@@ -10,1 +10,1 @@
-fn logFn(comptime message_level: std.log.Level, comptime scope: @Type(.EnumLiteral), comptime format: []const u8, args: anytype) void {
+fn logFn(comptime message_level: std.log.Level, comptime scope: @Type(.enum_literal), comptime format: []const u8, args: anytype) void {
EOF
            patch build.zig << 'EOF'
--- build.zig
+++ build.zig
@@ -43,1 +43,1 @@
-        version.pre = "dev";
+        version.pre = null;
EOF
            ;;
    esac

    zig build -Doptimize=ReleaseSmall -Dtarget=x86_64-linux
    cp zig-out/bin/hevi $OUT/usr/bin/hevi
}
