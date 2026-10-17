#!/bin/zsh
set -euo pipefail
cd "${0:A:h}"

swift_compiler=$(/usr/bin/xcrun --find swiftc)
mac_sdk=$(/usr/bin/xcrun --sdk macosx --show-sdk-path)
package_dir="$PWD/dist/SASEPopupCloser-Mac"
bundle_dir="$package_dir/SASE Popup Closer.app"
/bin/mkdir -p build "$bundle_dir/Contents/MacOS" "$package_dir/source"

for architecture in arm64 x86_64; do
    "$swift_compiler" -O -target "$architecture-apple-macosx13.0" -sdk "$mac_sdk" \
        -module-cache-path "$PWD/build/module-cache-$architecture" \
        -framework AppKit -framework ApplicationServices src/main.swift \
        -o "build/SASEPopupCloser-$architecture"
done

/usr/bin/lipo -create build/SASEPopupCloser-arm64 build/SASEPopupCloser-x86_64 \
    -output "$bundle_dir/Contents/MacOS/SASEPopupCloser"
/bin/cp resources/Info.plist "$bundle_dir/Contents/Info.plist"
/usr/bin/codesign --force --sign - --identifier local.hyper.SASEPopupCloser "$bundle_dir"
/usr/bin/codesign --verify --strict "$bundle_dir"
"$bundle_dir/Contents/MacOS/SASEPopupCloser" --self-test
/bin/cp scripts/Install.command scripts/Uninstall.command "$package_dir/"
/bin/chmod +x "$package_dir/Install.command" "$package_dir/Uninstall.command"
/bin/cp docs/安装说明.md "$package_dir/分享安装说明.md"
/bin/cp src/main.swift resources/Info.plist "$package_dir/source/"
/usr/bin/ditto -c -k --norsrc --noextattr --keepParent "$package_dir" dist/SASEPopupCloser-Mac.zip
cd dist
/usr/bin/shasum -a 256 SASEPopupCloser-Mac.zip > SASEPopupCloser-Mac.zip.sha256
print "构建完成：$PWD/SASEPopupCloser-Mac.zip"
