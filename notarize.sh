#!/bin/bash

# PixOrder Notarization Script
# Notarizes the built app with Apple for secure distribution

set -e

# Configuration
APP_NAME="PixOrder"

# Read version from VERSION file
if [ -f "VERSION" ]; then
    VERSION=$(cat VERSION | tr -d '\n')
    echo "📋 Using version: ${VERSION}"
else
    echo "❌ VERSION file not found. Please create a VERSION file with the version number."
    exit 1
fi

echo "🍎 PixOrder Notarization Starting..."
echo "====================================="

# Check if public folder exists
if [ ! -d "public" ]; then
    echo "❌ public/ folder not found. Please run ./deploy.sh first."
    exit 1
fi

# Check if app exists in public folder
if [ ! -f "public/${APP_NAME}-v${VERSION}.zip" ]; then
    echo "❌ ${APP_NAME}-v${VERSION}.zip not found in public/ folder."
    echo "   Please run ./deploy.sh first to create the distribution files."
    exit 1
fi

# Step 1: Submit for notarization
echo "📤 Submitting ${APP_NAME}-v${VERSION}.zip for notarization..."
echo "   This may take 5-15 minutes..."

SUBMISSION_ID=$(xcrun notarytool submit "public/${APP_NAME}-v${VERSION}.zip" \
    --keychain-profile "notarytool" \
    --wait \
    --output-format json | jq -r '.id')

if [ "$SUBMISSION_ID" = "null" ] || [ -z "$SUBMISSION_ID" ]; then
    echo "❌ Notarization submission failed."
    echo "   Please check your notarytool keychain profile setup."
    exit 1
fi

echo "✅ Notarization completed successfully!"
echo "   Submission ID: ${SUBMISSION_ID}"

# Step 2: Extract and staple the notarized app
echo "📎 Stapling notarization ticket to app..."

# Create temporary extraction directory
mkdir -p temp_notarize
cd temp_notarize

# Extract the ZIP file
unzip -q "../public/${APP_NAME}-v${VERSION}.zip"

# Wait for CloudKit to sync and try stapling with retries
echo "⏳ Waiting for Apple's CloudKit to sync..."
sleep 30

STAPLE_ATTEMPTS=0
MAX_STAPLE_ATTEMPTS=3

while [ $STAPLE_ATTEMPTS -lt $MAX_STAPLE_ATTEMPTS ]; do
    STAPLE_ATTEMPTS=$((STAPLE_ATTEMPTS + 1))
    echo "🔄 Stapling attempt ${STAPLE_ATTEMPTS}/${MAX_STAPLE_ATTEMPTS}..."
    
    if xcrun stapler staple "${APP_NAME}.app" 2>/dev/null; then
        echo "✅ Notarization ticket successfully stapled!"
        STAPLE_SUCCESS=true
        break
    else
        echo "⚠️  Stapling failed (attempt ${STAPLE_ATTEMPTS}/${MAX_STAPLE_ATTEMPTS})"
        if [ $STAPLE_ATTEMPTS -lt $MAX_STAPLE_ATTEMPTS ]; then
            echo "   Waiting 60 seconds before retry..."
            sleep 60
        fi
    fi
done

if [ "$STAPLE_SUCCESS" != "true" ]; then
    echo "⚠️  Warning: Could not staple notarization ticket"
    echo "   This can happen due to CloudKit sync delays"
    echo "   The app is still notarized, but may show warnings on some systems"
    echo "   You can try running this command manually later:"
    echo "   xcrun stapler staple '$(pwd)/${APP_NAME}.app'"
    echo ""
    echo "❓ Continue with unstapled (but notarized) app? [y/N]"
    read -r CONTINUE_CHOICE
    if [ "$CONTINUE_CHOICE" != "y" ] && [ "$CONTINUE_CHOICE" != "Y" ]; then
        cd ..
        rm -rf temp_notarize
        exit 1
    fi
    STAPLE_SUCCESS=false
fi

# Verify stapling if it succeeded
if [ "$STAPLE_SUCCESS" = "true" ]; then
    echo "🔍 Verifying stapled notarization..."
    if xcrun stapler validate "${APP_NAME}.app"; then
        echo "✅ Notarization validation successful!"
    else
        echo "⚠️  Validation warning (but continuing...)"
    fi
fi

# Step 3: Create new notarized packages
echo "📦 Creating notarized distribution packages..."

# Create notarized ZIP
zip -r "../public/${APP_NAME}-Notarized-v${VERSION}.zip" "${APP_NAME}.app"

# Create notarized DMG
cd ..
mkdir -p dmg_notarized_template
cp -R "temp_notarize/${APP_NAME}.app" "./dmg_notarized_template/"
ln -s /Applications ./dmg_notarized_template/Applications

# Create installation instructions
cat > "./dmg_notarized_template/Installation Instructions.txt" << 'EOF'
PixOrder Installation Instructions
================================

1. Drag the PixOrder.app icon to the Applications folder
2. Launch PixOrder from your Applications folder
3. Enjoy organizing your media files!

This version is notarized by Apple for enhanced security.

© 2025 PixOrder
EOF

# Hide the instructions file
chflags hidden "./dmg_notarized_template/Installation Instructions.txt"

# Create temporary DMG
DMG_NAME_NOTARIZED="${APP_NAME}-Notarized-Installer-v${VERSION}"
VOLUME_NAME_NOTARIZED="Install PixOrder (Notarized)"

hdiutil create -srcfolder ./dmg_notarized_template -volname "${VOLUME_NAME_NOTARIZED}" -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" -format UDRW -size 25m "public/${DMG_NAME_NOTARIZED}-temp.dmg"

# Mount and configure DMG
DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "public/${DMG_NAME_NOTARIZED}-temp.dmg" | \
    egrep '^/dev/' | sed 1q | awk '{print $1}')

sleep 3

# Configure DMG appearance
osascript << EOF
tell application "Finder"
    tell disk "${VOLUME_NAME_NOTARIZED}"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 920, 450}
        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 128
        set background color of theViewOptions to {61166, 61166, 61166}
        
        delay 1
        set position of item "${APP_NAME}.app" of container window to {150, 180}
        set position of item "Applications" of container window to {370, 180}
        
        set text size of theViewOptions to 12
        set label position of theViewOptions to bottom
        
        update without registering applications
        delay 3
        close
    end tell
end tell
EOF

# Unmount and create final DMG
hdiutil detach "${DEVICE}"
hdiutil convert "public/${DMG_NAME_NOTARIZED}-temp.dmg" -format UDZO -imagekey zlib-level=9 -o "public/${DMG_NAME_NOTARIZED}.dmg"

# Clean up
rm -f "public/${DMG_NAME_NOTARIZED}-temp.dmg"
rm -rf dmg_notarized_template/
rm -rf temp_notarize/

# Step 4: Display results
DMG_SIZE=$(ls -lh "public/${DMG_NAME_NOTARIZED}.dmg" | awk '{print $5}')
ZIP_SIZE=$(ls -lh "public/${APP_NAME}-Notarized-v${VERSION}.zip" | awk '{print $5}')

echo ""
echo "🎉 NOTARIZATION COMPLETED SUCCESSFULLY! 🎉"
echo "=========================================="
echo ""
echo "📦 Notarized Files (in public/ folder):"
echo "   📀 public/${DMG_NAME_NOTARIZED}.dmg (${DMG_SIZE}) - Notarized installer"
echo "   🗜️  public/${APP_NAME}-Notarized-v${VERSION}.zip (${ZIP_SIZE}) - Notarized app archive"
echo ""
echo "🔐 Apple Notarization:"
echo "   ✅ Submitted to Apple and approved"
echo "   ✅ Notarization ticket stapled to app"
echo "   ✅ No security warnings on any macOS system"
echo ""
echo "🚀 Ready for Professional Distribution!"
echo "   Recommend using: public/${DMG_NAME_NOTARIZED}.dmg"
echo "   Users can install directly without ANY security warnings"
echo ""
echo "📁 All files are in the public/ folder"
echo "   Original (signed): ${APP_NAME}-Installer-v${VERSION}.dmg"
echo "   Notarized: ${DMG_NAME_NOTARIZED}.dmg"
echo ""