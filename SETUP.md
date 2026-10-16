# DesiFit – setup

1. Put this folder anywhere, then generate the platform folders (keeps `lib/` and `pubspec.yaml`):

       flutter create . --project-name desi_fit --org com.desifit
       flutter pub get

2. **Android – reminders** (needed by `flutter_local_notifications`)

   `android/app/src/main/AndroidManifest.xml`

   Inside `<manifest>` (above `<application>`):

       <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
       <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
       <uses-permission android:name="android.permission.VIBRATE"/>

   Inside `<application>`:

       <receiver android:exported="false"
           android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>
       <receiver android:exported="false"
           android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
         <intent-filter>
           <action android:name="android.intent.action.BOOT_COMPLETED"/>
           <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
           <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
           <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
         </intent-filter>
       </receiver>

   `android/app/build.gradle(.kts)` – enable desugaring:

       compileOptions { isCoreLibraryDesugaringEnabled = true }   // Kotlin DSL
       dependencies { coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") }

   (Groovy DSL: `coreLibraryDesugaringEnabled true` and
   `coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'`.)

3. Run:

       flutter run
