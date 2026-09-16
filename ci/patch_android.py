from pathlib import Path
import re
import xml.etree.ElementTree as ET

p = Path('android/app/src/main/AndroidManifest.xml')
ET.register_namespace('android', 'http://schemas.android.com/apk/res/android')
ANDROID = '{http://schemas.android.com/apk/res/android}'

tree = ET.parse(p)
root = tree.getroot()
existing = {e.get(ANDROID + 'name') for e in root.findall('uses-permission')}
for perm in [
    'android.permission.INTERNET',
    'android.permission.CAMERA',
    'android.permission.ACCESS_LOCAL_NETWORK',
]:
    if perm not in existing:
        e = ET.Element('uses-permission')
        e.set(ANDROID + 'name', perm)
        root.insert(0, e)

app = root.find('application')
if app is None:
    raise SystemExit('application missing')

app.set(ANDROID + 'label', 'École Gestion Prof')
app.set(ANDROID + 'usesCleartextTraffic', 'true')
app.set(ANDROID + 'networkSecurityConfig', '@xml/network_security_config')
tree.write(p, encoding='utf-8', xml_declaration=True)

xml = Path('android/app/src/main/res/xml')
xml.mkdir(parents=True, exist_ok=True)
(xml / 'network_security_config.xml').write_text('''<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
  <base-config cleartextTrafficPermitted="true" />
</network-security-config>
''', encoding='utf-8')

app_gradle = Path('android/app/build.gradle.kts')
gradle_text = app_gradle.read_text(encoding='utf-8')
gradle_text = re.sub(r'compileSdk\s*=\s*flutter\.compileSdkVersion', 'compileSdk = 37', gradle_text)
app_gradle.write_text(gradle_text, encoding='utf-8')

settings = Path('android/settings.gradle.kts')
settings_text = settings.read_text(encoding='utf-8')
settings_text = re.sub(
    r'id\("com\.android\.application"\)\s+version\s+"[^"]+"',
    'id("com.android.application") version "9.1.1"',
    settings_text,
)
settings.write_text(settings_text, encoding='utf-8')

print('Android configuré pour compileSdk 37 / AGP 9.1.1')
