import os

settings = """[gd_resource type="EditorSettings" format=3]
[resource]
export/android/java_sdk_path = "/usr"
export/android/android_sdk_path = "/usr/lib/android-sdk"
export/android/debug_keystore = "/root/debug.keystore"
export/android/debug_keystore_user = "androiddebugkey"
export/android/debug_keystore_pass = "android"
"""

os.makedirs("/root/.config/godot", exist_ok=True)
path = "/root/.config/godot/editor_settings-4.4.tres"
with open(path, "w") as f:
    f.write(settings)

print("Settings written:")
print(open(path).read())
