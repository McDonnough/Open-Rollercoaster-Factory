#!/bin/sh

# Creates application bundles for use on Mac OS X.

bundle_name="orcf"
company_name="orcfteam"

if [ -d "${bundle_name}.app/" ]; then
  rm -R "${bundle_name}.app/"
fi

if [ ! -d "${bundle_name}.app/Contents/MacOS" ]; then
  mkdir -p "${bundle_name}.app/Contents/MacOS"
fi

if [ ! -d "${bundle_name}.app/Contents/Resources" ]; then
  mkdir -p "${bundle_name}.app/Contents/Resources"
fi

if [ ! -f "${bundle_name}.app/Contents/PkgInfo" ]; then
  echo "APPL????" > "${bundle_name}.app/Contents/PkgInfo"
fi

if [ ! -f "${bundle_name}.app/Contents/Info.plist" ]; then
  cat > "${bundle_name}.app/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>English</string>
  <key>CFBundleExecutable</key>
  <string>${bundle_name}</string>
  <key>CFBundleName</key>
  <string>${bundle_name}</string>
  <key>CFBundleIdentifier</key>
  <string>com.${company_name}.${bundle_name}</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleSignature</key>
  <string>${bundle_name}</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>CSResourcesFileMapped</key>
  <true/>
  <key>CFBundleDocumentTypes</key>
  <array>
    <dict>
      <key>CFBundleTypeRole</key>
      <string>Viewer</string>
      <key>CFBundleTypeExtensions</key>
      <array>
        <string>*</string>
      </array>
      <key>CFBundleTypeOSTypes</key>
      <array>
        <string>fold</string>
        <string>disk</string>
        <string>****</string>
      </array>
    </dict>
  </array>
  <key>CFBundleIconFile</key>
	<string>${bundle_name}.icns</string>
</dict>
</plist>
EOF
cp "${bundle_name}" "${bundle_name}.app/Contents/MacOS/"
cp -R "data/" "${bundle_name}.app/Contents/Resources/"
cp "${bundle_name}.icns" "${bundle_name}.app/Contents/Resources/"
fi

