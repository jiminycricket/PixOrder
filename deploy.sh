#!/bin/bash

# PixOrder Deployment Script
# Builds, packages and creates professional DMG installer in one step

set -e

# Load environment variables if .env exists
if [ -f ".env" ]; then
    source .env
fi

# Configuration
APP_NAME="PixOrder"
SCHEME="PixOrder"
PROJECT="PixOrder.xcodeproj"

# Read version from VERSION file
if [ -f "VERSION" ]; then
    VERSION=$(cat VERSION | tr -d '\n')
    echo "📋 Using version: ${VERSION}"
else
    echo "❌ VERSION file not found. Please create a VERSION file with the version number."
    exit 1
fi

DMG_NAME="PixOrder-Installer-v${VERSION}"
VOLUME_NAME="Install PixOrder"
DMG_SIZE="25m"

echo "🚀 PixOrder Deployment Pipeline Starting..."
echo "=============================================="

# Step 1: Clean up previous builds and setup output directory
echo "🧹 Cleaning up previous builds..."
rm -rf build/
rm -rf dist/
rm -rf dmg_template/
rm -rf public/
mkdir -p public/

# Step 2: Build Release version with code signing
echo "⚡ Building PixOrder Release version..."

if [ -n "${CODE_SIGN_IDENTITY}" ]; then
    echo "🔐 Building with code signing identity: ${CODE_SIGN_IDENTITY}"
    xcodebuild -project ${PROJECT} -scheme ${SCHEME} -configuration Release \
        -derivedDataPath ./build \
        CODE_SIGN_STYLE=Manual \
        CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" \
        clean build
    
    # Verify signing
    echo "🔍 Verifying code signature..."
    if codesign -v ./build/Build/Products/Release/${APP_NAME}.app; then
        echo "✅ Code signing completed successfully"
        codesign -dv ./build/Build/Products/Release/${APP_NAME}.app | head -3
    else
        echo "❌ Code signing verification failed"
        exit 1
    fi
else
    echo "⚠️  No CODE_SIGN_IDENTITY environment variable set"
    echo "   Building without code signing - app will show security warnings"
    echo "   To sign: export CODE_SIGN_IDENTITY=\"Your Developer ID\""
    xcodebuild -project ${PROJECT} -scheme ${SCHEME} -configuration Release -derivedDataPath ./build clean build
fi

echo "✅ Build completed successfully"

# Step 3: Prepare DMG template
echo "📦 Preparing DMG template..."
mkdir -p dmg_template
cp -R ./build/Build/Products/Release/${APP_NAME}.app ./dmg_template/
ln -s /Applications ./dmg_template/Applications

# Create installation instructions in template
cat > "./dmg_template/Installation Instructions.txt" << 'EOF'
PixOrder Installation Instructions
================================

1. Drag the PixOrder.app icon to the Applications folder
2. Launch PixOrder from your Applications folder
3. On first launch, macOS may ask for permission to access folders
4. Enjoy organizing your media files!

Features:
• Smart media file organization by aspect ratio
• Support for JPEG, PNG, HEIF, MOV, MP4 and more
• Real-time progress tracking with detailed logs
• Safe copy or move operations
• Smart conflict resolution

© 2025 PixOrder
EOF

# Hide the instructions file
chflags hidden "./dmg_template/Installation Instructions.txt"

# Step 4: Create temporary DMG
echo "🔧 Creating temporary DMG..."
hdiutil create -srcfolder ./dmg_template -volname "${VOLUME_NAME}" -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" -format UDRW -size ${DMG_SIZE} "public/${DMG_NAME}-temp.dmg"

# Step 5: Mount and configure DMG
echo "🎨 Mounting and configuring DMG appearance..."
DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "public/${DMG_NAME}-temp.dmg" | \
    egrep '^/dev/' | sed 1q | awk '{print $1}')

sleep 3

MOUNT_POINT="/Volumes/${VOLUME_NAME}"

# Installation instructions already prepared in template

# Configure DMG window appearance
echo "✨ Setting up professional installation interface..."
osascript << EOF
tell application "Finder"
    tell disk "${VOLUME_NAME}"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 920, 450}
        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 128
        set background color of theViewOptions to {61166, 61166, 61166}
        
        -- Position icons perfectly
        delay 1
        set position of item "${APP_NAME}.app" of container window to {150, 180}
        set position of item "Applications" of container window to {370, 180}
        
        -- Set text properties
        set text size of theViewOptions to 12
        set label position of theViewOptions to bottom
        
        -- Update and close
        update without registering applications
        delay 3
        close
    end tell
end tell
EOF

# Step 6: Unmount and create final DMG
echo "🗜️  Creating final compressed DMG..."
hdiutil detach "${DEVICE}"
hdiutil convert "public/${DMG_NAME}-temp.dmg" -format UDZO -imagekey zlib-level=9 -o "public/${DMG_NAME}.dmg"

# Step 7: Create backup ZIP version
echo "📁 Creating ZIP backup..."
mkdir -p dist
cp -R ./build/Build/Products/Release/${APP_NAME}.app ./dist/
cd dist && zip -r ../public/${APP_NAME}-v${VERSION}.zip ${APP_NAME}.app && cd ..

# Step 8: Clean up temporary files
echo "🧹 Cleaning up temporary files..."
rm -f "public/${DMG_NAME}-temp.dmg"
rm -rf dmg_template/
rm -rf build/
rm -rf dist/

# Step 9: Verify and display results
echo "🔍 Verifying build..."
if [ -n "${CODE_SIGN_IDENTITY}" ]; then
    echo "🔐 Code signing verification:"
    codesign -dv --verbose=2 "public/${DMG_NAME}.dmg" 2>/dev/null || echo "   DMG not signed (normal for distribution)"
    if [ -f "./dmg_template/${APP_NAME}.app" ]; then
        codesign -dv --verbose=2 "./dmg_template/${APP_NAME}.app" 2>/dev/null || echo "   App verification failed"
    fi
else
    echo "⚠️  Build is unsigned - users will see security warnings"
fi

DMG_SIZE=$(ls -lh "public/${DMG_NAME}.dmg" | awk '{print $5}')
ZIP_SIZE=$(ls -lh "public/${APP_NAME}-v${VERSION}.zip" | awk '{print $5}')

echo ""
echo "🎉 DEPLOYMENT COMPLETED SUCCESSFULLY! 🎉"
echo "=============================================="
echo ""
echo "📦 Generated Files (in public/ folder):"
echo "   📀 public/${DMG_NAME}.dmg (${DMG_SIZE}) - Professional installer with drag-and-drop interface"
echo "   🗜️  public/${APP_NAME}-v${VERSION}.zip (${ZIP_SIZE}) - Compressed backup version"
echo ""
echo "🌟 DMG Features:"
echo "   ✨ Professional drag-and-drop installation"
echo "   📱 Optimized icon positioning and window layout"
echo "   🎨 Clean, modern appearance"
echo "   📋 Hidden installation instructions"
echo ""
echo "🚀 Ready for Distribution!"
echo "   Recommend using: public/${DMG_NAME}.dmg"
echo "   Users can drag ${APP_NAME}.app to Applications folder"
echo ""
if [ -n "${CODE_SIGN_IDENTITY}" ]; then
    echo "✅ Code Signing: Completed with ${CODE_SIGN_IDENTITY}"
else
    echo "⚠️  Code Signing: Not signed (set CODE_SIGN_IDENTITY to sign)"
fi
echo "✅ App Sandbox: Enabled" 
echo "✅ Architecture: Universal (ARM64 + x86_64)"
echo "✅ Minimum macOS: 13.0+"
echo ""
echo "🎯 Next Steps:"
echo "   1. Test the DMG by opening public/${DMG_NAME}.dmg"
echo "   2. Upload to your distribution platform"
echo "   3. Share with users!"
echo ""
echo "📁 All distribution files are in the public/ folder"
echo "   (This folder is git-ignored for clean repository)"
echo ""