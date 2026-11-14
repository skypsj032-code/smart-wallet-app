"""Checks that the manual-entry preview cannot listen to sensitive events."""
import unittest
from pathlib import Path
from xml.etree import ElementTree as ET

MANIFEST = Path(__file__).parents[2] / 'android/app/src/main/AndroidManifest.xml'
ANDROID = '{http://schemas.android.com/apk/res/android}'

class ManualPreviewSecurityTest(unittest.TestCase):
    def test_manual_preview_requests_no_notification_sms_or_accessibility_access(self):
        manifest = ET.parse(MANIFEST).getroot()
        dangerous = {
            'android.permission.BIND_NOTIFICATION_LISTENER_SERVICE',
            'android.permission.BIND_ACCESSIBILITY_SERVICE',
            'android.permission.READ_SMS',
            'android.permission.RECEIVE_SMS',
        }
        declared = {
            element.get(ANDROID + attr)
            for element in manifest.iter()
            for attr in ('permission', 'name')
        }
        self.assertFalse(declared & dangerous, f'Sensitive access declared: {declared & dangerous}')

if __name__ == '__main__':
    unittest.main()
