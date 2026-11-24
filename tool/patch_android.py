"""بيظبط ملفات أندرويد المتولّدة عشان الإشعارات المجدولة تشتغل."""
import pathlib

# ---------- AndroidManifest ----------
m = pathlib.Path('android/app/src/main/AndroidManifest.xml')
s = m.read_text(encoding='utf8')
if 'POST_NOTIFICATIONS' not in s:
    perms = (
        '<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>\n'
        '    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>\n'
        '    <uses-permission android:name="android.permission.USE_EXACT_ALARM"/>\n'
        '    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" android:maxSdkVersion="32"/>\n'
        '    <uses-permission android:name="android.permission.VIBRATE"/>\n'
        '    '
    )
    recv = (
        '    <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />\n'
        '        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">\n'
        '            <intent-filter>\n'
        '                <action android:name="android.intent.action.BOOT_COMPLETED"/>\n'
        '                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>\n'
        '                <action android:name="android.intent.action.QUICKBOOT_POWERON" />\n'
        '                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>\n'
        '            </intent-filter>\n'
        '        </receiver>\n'
        '    '
    )
    assert '<application' in s and '</application>' in s, 'manifest layout changed'
    s = s.replace('<application', perms + '<application', 1)
    s = s.replace('</application>', recv + '</application>', 1)
    m.write_text(s, encoding='utf8')
    print('manifest patched')

# ---------- Gradle (desugaring) ----------
done = False
for name in ('android/app/build.gradle.kts', 'android/app/build.gradle'):
    p = pathlib.Path(name)
    if not p.exists():
        continue
    s = p.read_text(encoding='utf8')
    kts = name.endswith('.kts')
    if 'coreLibraryDesugaring' not in s:
        assert 'compileOptions {' in s, 'compileOptions not found in ' + name
        flag = 'isCoreLibraryDesugaringEnabled = true' if kts else 'coreLibraryDesugaringEnabled true'
        s = s.replace('compileOptions {', 'compileOptions {\n        ' + flag, 1)
        if kts:
            s += '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'
        else:
            s += "\ndependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'\n}\n"
        p.write_text(s, encoding='utf8')
        print('gradle patched:', name)
    done = True
assert done, 'no app build.gradle found'
