# Flutter ProGuard rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# SQLite
-keep class net.sqlcipher.** { *; }
-keep class org.sqlite.** { *; }

# Keep Arabic text / Amiri font
-keepclassmembers class ** { @com.google.gson.annotations.SerializedName <fields>; }
