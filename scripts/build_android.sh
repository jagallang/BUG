#!/bin/bash

# BugCash Android Build Script
echo "🤖 Starting BugCash Android Build..."

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Clean previous build
echo -e "${BLUE}🧹 Cleaning previous build...${NC}"
flutter clean

# Get dependencies
echo -e "${BLUE}📦 Getting Flutter dependencies...${NC}"
flutter pub get

# Check if google-services.json exists
if [ ! -f "android/app/google-services.json" ]; then
    echo -e "${RED}❌ google-services.json not found!${NC}"
    echo -e "${YELLOW}⚠️  Please download google-services.json from Firebase Console and place it in android/app/${NC}"
    exit 1
fi

# Build APK (Debug)
echo -e "${BLUE}🔨 Building Debug APK...${NC}"
flutter build apk --debug

# Check if debug build was successful
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Debug APK build completed successfully!${NC}"
    echo -e "${GREEN}📱 Debug APK location: build/app/outputs/flutter-apk/app-debug.apk${NC}"
else
    echo -e "${RED}❌ Debug APK build failed!${NC}"
    exit 1
fi

# Build APK (Release)
echo -e "${BLUE}🔨 Building Release APK...${NC}"
flutter build apk --release

# Check if release build was successful
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Release APK build completed successfully!${NC}"
    echo -e "${GREEN}📱 Release APK location: build/app/outputs/flutter-apk/app-release.apk${NC}"
else
    echo -e "${RED}❌ Release APK build failed!${NC}"
    exit 1
fi

# Build AAB (Android App Bundle) for Play Store
echo -e "${BLUE}🔨 Building Android App Bundle (AAB)...${NC}"
flutter build appbundle --release

# Check if AAB build was successful
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ AAB build completed successfully!${NC}"
    echo -e "${GREEN}🏪 AAB location: build/app/outputs/bundle/release/app-release.aab${NC}"
else
    echo -e "${RED}❌ AAB build failed!${NC}"
    exit 1
fi

# Display file sizes
echo -e "${BLUE}📊 Build Statistics:${NC}"
if [ -f "build/app/outputs/flutter-apk/app-debug.apk" ]; then
    DEBUG_SIZE=$(stat -f%z "build/app/outputs/flutter-apk/app-debug.apk" 2>/dev/null || stat -c%s "build/app/outputs/flutter-apk/app-debug.apk" 2>/dev/null)
    echo -e "${GREEN}📱 Debug APK: $(echo "scale=1; $DEBUG_SIZE/1024/1024" | bc)MB${NC}"
fi

if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    RELEASE_SIZE=$(stat -f%z "build/app/outputs/flutter-apk/app-release.apk" 2>/dev/null || stat -c%s "build/app/outputs/flutter-apk/app-release.apk" 2>/dev/null)
    echo -e "${GREEN}📱 Release APK: $(echo "scale=1; $RELEASE_SIZE/1024/1024" | bc)MB${NC}"
fi

if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
    AAB_SIZE=$(stat -f%z "build/app/outputs/bundle/release/app-release.aab" 2>/dev/null || stat -c%s "build/app/outputs/bundle/release/app-release.aab" 2>/dev/null)
    echo -e "${GREEN}🏪 AAB Bundle: $(echo "scale=1; $AAB_SIZE/1024/1024" | bc)MB${NC}"
fi

echo -e "${GREEN}✨ All Android builds completed successfully! ✨${NC}"
echo -e "${YELLOW}📝 Next steps:${NC}"
echo -e "${YELLOW}   1. Test the Debug APK on your device${NC}"
echo -e "${YELLOW}   2. Upload the AAB to Google Play Console for production${NC}"