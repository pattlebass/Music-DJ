Before exporting to Android add this to AndroidManifest.xml > permissions, after read external storage
<uses-permission
        android:name="android.permission.WRITE_EXTERNAL_STORAGE"
        android:maxSdkVersion="29" />
