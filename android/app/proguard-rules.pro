# Add project specific ProGuard rules here.

# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Mobile Ads SDK
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }

# Hive Database
-keep class hive.** { *; }
-keep class **.adapter.** { *; }

# Riverpod
-keep class riverpod.** { *; }

# App Tracking Transparency
-keep class app_tracking_transparency.** { *; }

# Kotlinx Serialization
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt

# General optimizations
-optimizationpasses 5
-dontskipnonpubliclibraryclasses
-dontpreverify
-verbose