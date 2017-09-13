# !/bin/bash

# Based on the xresign.sh script in https://github.com/xndrs/XReSign licensed under the MIT license

usage="Usage example:
$(basename "$0") -s path -c certificate [-p path] [-b identifier]

where:
-s  Path to ipa file which you want to sign/resign
-c  Signing certificate Common Name from Keychain
-p  Path to mobile provisioning file (Optional)
-i  Bundle identifier (Optional)
-v  Version number (Optional)
-b  Build number (Optional)"

while getopts s:c:p:i:v:b: option
do
    case "${option}"
    in
      s) SOURCEIPA=${OPTARG}
         ;;
      c) DEVELOPER=${OPTARG}
         ;;
      p) MOBILEPROV=${OPTARG}
         ;;
      i) BUNDLEID=${OPTARG}
         ;;
      v) BUNDLEVERSION=${OPTARG}
         ;;
      b) BUNDLEBUILD=${OPTARG}
         ;;
     \?) echo "invalid option: -$OPTARG" >&2
         echo "$usage" >&2
         exit 1
         ;;
      :) echo "missing argument for -$OPTARG" >&2
         echo "$usage" >&2
         exit 1
         ;;
    esac
done

echo "Start resign the app..."

OUTDIR=$(dirname "${SOURCEIPA}")
TMPDIR="$OUTDIR/tmp"
APPDIR="$TMPDIR/app"

mkdir -p "$APPDIR"
unzip -qo "$SOURCEIPA" -d "$APPDIR"

APPLICATION=$(ls "$APPDIR/Payload/")

rm -r "$APPDIR/Payload/$APPLICATION/_CodeSignature"

if [ -z "${MOBILEPROV}" ]; then
    echo "Sign process using existing provisioning profile from payload"
else
    echo "Coping provisioning profile into application payload"
    cp "$MOBILEPROV" "$APPDIR/Payload/$APPLICATION/embedded.mobileprovision"
fi

echo "Extract entitlements from mobileprovisioning"
security cms -D -i "$APPDIR/Payload/$APPLICATION/embedded.mobileprovision" > "$TMPDIR/provisioning.plist"
/usr/libexec/PlistBuddy -x -c 'Print:Entitlements' "$TMPDIR/provisioning.plist" > "$TMPDIR/entitlements.plist"

if [ -z "${BUNDLEID}" ]; then
    echo "Sign process using existing bundle identifier from payload"
else
    echo "Changing BundleID with : $BUNDLEID"
    /usr/libexec/PlistBuddy -c "Set:CFBundleIdentifier $BUNDLEID" "$APPDIR/Payload/$APPLICATION/Info.plist"
fi
if [ -z "${BUNDLEVERSION}" ]; then
    echo "Sign process using existing version number"
else
    echo "Changing version number to : $BUNDLEVERSION"
    /usr/libexec/PlistBuddy -c "Set:CFBundleShortVersionString $BUNDLEVERSION" "$APPDIR/Payload/$APPLICATION/Info.plist"
fi
if [ -z "${BUNDLEBUILD}" ]; then
    echo "Sign process using existing build number"
else
    echo "Changing build number to : $BUNDLEBUILD"
    /usr/libexec/PlistBuddy -c "Set:CFBundleVersion $BUNDLEBUILD" "$APPDIR/Payload/$APPLICATION/Info.plist"
fi

echo "Get list of components and resign with certificate: $DEVELOPER"
find -d "$APPDIR/Payload/$APPLICATION" \( -name "*.app" -o -name "*.appex" -o -name "*.framework" -o -name "*.dylib" \) > "$TMPDIR/components.txt"

var=$((0))
while IFS='' read -r line || [[ -n "$line" ]]; do
	if [[ ! -z "${BUNDLEID}" ]] && [[ "$line" == *".appex"* ]]; then
	   echo "Changing .appex BundleID with : $BUNDLEID.extra$var"
	   /usr/libexec/PlistBuddy -c "Set:CFBundleIdentifier $BUNDLEID.extra$var" "$line/Info.plist"
	   var=$((var+1))
	fi
    /usr/bin/codesign --continue -f -s "$DEVELOPER" --entitlements "$TMPDIR/entitlements.plist" "$line"
done < "$TMPDIR/components.txt"

echo "Creating the signed ipa"
cd "$APPDIR"
filename=$(basename "$APPLICATION")
filename="${filename%.*}-resign.ipa"
zip -qr "../$filename" *
cd ..
mv $filename "$OUTDIR"

echo "Clear temporary files"
rm -rf "$APPDIR"
rm "$TMPDIR/components.txt"
rm "$TMPDIR/provisioning.plist"
rm "$TMPDIR/entitlements.plist"

echo "FINISHED"
