# AstroPrerna Custom ProGuard/R8 Rules

# Keep Firebase classes (required by cloud_firestore, firebase_auth, firebase_core)
-keep class io.grpc.** { *; }
-keep class com.google.firebase.** { *; }
-dontwarn io.grpc.**
-dontwarn com.google.firebase.**

# Keep Google Mobile Ads (AdMob) classes
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# Keep OneSignal classes
-keep class com.onesignal.** { *; }
-keep class com.amazon.device.iap.** { *; }
-dontwarn com.onesignal.**

# Keep Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# Keep Cached Network Image
-keep class com.baseflow.** { *; }
-dontwarn com.baseflow.**

# Keep Speech-to-Text plugin
-keep class com.csdcorp.speech_to_text.** { *; }
-dontwarn com.csdcorp.speech_to_text.**

# Keep url_launcher plugin
-keep class androidx.browser.** { *; }
-dontwarn androidx.browser.**

# Keep package_info_plus plugin
-keep class dev.fluttercommunity.plus.** { *; }
-dontwarn dev.fluttercommunity.plus.**

# Keep share_plus plugin
-keep class dev.fluttercommunity.plus.share.** { *; }
-dontwarn dev.fluttercommunity.plus.share.**

# Keep Google Sign-In classes
-keep class com.google.android.gms.auth.** { *; }
-dontwarn com.google.android.gms.auth.**

# Keep Kotlin Coroutines (used by Firebase plugins)
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembers class kotlinx.coroutines.** {
    volatile <fields>;
}

# Keep Flutter generated plugin registrant
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.plugins.**

# Preserve annotations that R8 might strip
-keepattributes Signature, InnerClasses, EnclosingMethod
-keepattributes RuntimeVisibleAnnotations, RuntimeVisibleParameterAnnotations

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enum classes (Firebase Firestore uses them)
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
