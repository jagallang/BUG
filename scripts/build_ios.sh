#!/bin/bash

# BugCash iOS Build Script
echo "🍎 Starting BugCash iOS Build..."

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}❌ iOS builds are only supported on macOS!${NC}"
    exit 1
fi

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}❌ Xcode is not installed or not in PATH!${NC}"
    exit 1
fi

# Clean previous build
echo -e "${BLUE}🧹 Cleaning previous build...${NC}"
flutter clean

# Get dependencies
echo -e "${BLUE}📦 Getting Flutter dependencies...${NC}"
flutter pub get

# Check if GoogleService-Info.plist exists
if [ ! -f "ios/Runner/GoogleService-Info.plist" ]; then
    echo -e "${RED}❌ GoogleService-Info.plist not found!${NC}"
    echo -e "${YELLOW}⚠️  Please download GoogleService-Info.plist from Firebase Console and place it in ios/Runner/${NC}"
    exit 1
fi

# Install iOS pods
echo -e "${BLUE}📦 Installing iOS CocoaPods...${NC}"
cd ios
pod install --repo-update
cd ..

# Build iOS (Debug)
echo -e "${BLUE}🔨 Building iOS Debug...${NC}"
flutter build ios --debug --no-codesign

# Check if debug build was successful
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ iOS Debug build completed successfully!${NC}"
else
    echo -e "${RED}❌ iOS Debug build failed!${NC}"
    exit 1
fi

# Build iOS (Release) - requires signing for physical devices
echo -e "${BLUE}🔨 Building iOS Release...${NC}"
echo -e "${YELLOW}⚠️  Note: Release build may require code signing setup${NC}"
flutter build ios --release --no-codesign

# Check if release build was successful
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ iOS Release build completed successfully!${NC}"
else
    echo -e "${RED}❌ iOS Release build failed!${NC}"
    exit 1
fi

echo -e "${GREEN}✨ iOS builds completed successfully! ✨${NC}"
echo -e "${YELLOW}📝 Next steps:${NC}"
echo -e "${YELLOW}   1. Open ios/Runner.xcworkspace in Xcode${NC}"
echo -e "${YELLOW}   2. Set up code signing and provisioning profiles${NC}"
echo -e "${YELLOW}   3. Build and test on iOS Simulator or device${NC}"
echo -e "${YELLOW}   4. Archive and upload to App Store Connect${NC}"