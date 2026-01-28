# Razorpay SDK ProGuard Rules
-keepattributes *Annotation*
-dontwarn com.razorpay.**
-keep class com.razorpay.** {*;}

# Required for Razorpay proactive instrumentation
-optimizations !method/inlining/*

# Keep JSON serialization classes
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}
