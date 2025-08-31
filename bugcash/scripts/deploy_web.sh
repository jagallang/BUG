#!/bin/bash

# BugCash Web Deployment Script
echo "🚀 Starting BugCash Web Deployment..."

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo -e "${RED}❌ Firebase CLI is not installed. Please install it first.${NC}"
    echo "Run: npm install -g firebase-tools"
    exit 1
fi

# Clean previous build
echo -e "${BLUE}🧹 Cleaning previous build...${NC}"
flutter clean

# Get dependencies
echo -e "${BLUE}📦 Getting Flutter dependencies...${NC}"
flutter pub get

# Build for web
echo -e "${BLUE}🔨 Building Flutter web app...${NC}"
flutter build web --release --web-renderer html

# Check if build was successful
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Web build completed successfully!${NC}"
else
    echo -e "${RED}❌ Web build failed!${NC}"
    exit 1
fi

# Deploy to Firebase Hosting
echo -e "${BLUE}🌐 Deploying to Firebase Hosting...${NC}"
firebase deploy --only hosting

# Check if deployment was successful
if [ $? -eq 0 ]; then
    echo -e "${GREEN}🎉 Web deployment completed successfully!${NC}"
    echo -e "${GREEN}🔗 Your app is live at: https://bugcash.web.app${NC}"
else
    echo -e "${RED}❌ Firebase deployment failed!${NC}"
    exit 1
fi

echo -e "${GREEN}✨ All done! Your BugCash web app is now live! ✨${NC}"