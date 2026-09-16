from pathlib import Path
import xml.etree.ElementTree as ET

p = Path('android/app/src/main/AndroidManifest.xml')
ET.register_namespace('android', 'http://schemas.android.com/apk/res/android')
ANDROID='{http://schemas.android.com/apk/res/android}'
tree=ET.parse(p)
root=tree.getroot()
existing={e.get(ANDROID+'name') for e in root.findall('uses-permission')}
for perm in [
    'android.permission.INTERNET',
    'android.permission.CAMERA',
    'android.permission.ACCESS_LOCAL_NETWORK',
]:
    if perm not in existing:
        e=ET.Element('uses-permission')
        e.set(ANDROID+'name', perm)
        root.insert(0,e)
app=root.find('application')
if app is None:
    raise SystemExit('application missing')
app.set(ANDROID+'label','École Gestion Prof')
app.set(ANDROID+'usesCleartextTraffic','true')
app.set(ANDROID+'networkSecurityConfig','@xml/network_security_config')
tree.write(p, encoding='utf-8', xml_declaration=True)

xml = Path('android/app/src/main/res/xml')
xml.mkdir(parents=True, exist_ok=True)
(xml/'network_security_config.xml').write_text('''<?xml version="1.0" encoding="utf-8"?>\n<network-security-config>\n  <base-config cleartextTrafficPermitted="true" />\n</network-security-config>\n''', encoding='utf-8')
