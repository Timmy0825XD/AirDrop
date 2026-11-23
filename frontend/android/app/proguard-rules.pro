# Reglas de R8 para el APK de release (minifyEnabled).

# Flutter referencia Play Core (componentes diferidos) aunque la app no lo use.
-dontwarn com.google.android.play.core.**

# Plugins con código nativo que se llama por JNI o reflexión: no se renombran.
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class jp.espresso3389.pdfrx.** { *; }
