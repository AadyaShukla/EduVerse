# Flutter ProGuard / R8 Code Shrinking Rules

-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.provider.** { *; }

# ML Kit Text Recognition Keep Rules
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Sqflite Keep Rules
-keep class com.tekartik.sqflite.** { *; }
