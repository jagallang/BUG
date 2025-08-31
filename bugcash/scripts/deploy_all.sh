#!/bin/bash

# BugCash Complete Deployment Script
echo "🚀 Starting BugCash Complete Deployment..."

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Banner
echo -e "${PURPLE}"
echo "██████╗ ██╗   ██╗ ██████╗  ██████╗ █████╗ ███████╗██╗  ██╗"
echo "██╔══██╗██║   ██║██╔════╝ ██╔════╝██╔══██╗██╔════╝██║  ██║"
echo "██████╔╝██║   ██║██║  ███╗██║     ███████║███████╗███████║"
echo "██╔══██╗██║   ██║██║   ██║██║     ██╔══██║╚════██║██╔══██║"
echo "██████╔╝╚██████╔╝╚██████╔╝╚██████╗██║  ██║███████║██║  ██║"
echo "╚═════╝  ╚═════╝  ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝"
echo -e "${NC}"
echo -e "${BLUE}Complete Deployment Pipeline${NC}"
echo ""

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo -e "${BLUE}🔍 Checking prerequisites...${NC}"

# Check Flutter
if ! command_exists flutter; then
    echo -e "${RED}❌ Flutter is not installed!${NC}"
    exit 1
fi

# Check Firebase CLI
if ! command_exists firebase; then
    echo -e "${RED}❌ Firebase CLI is not installed!${NC}"
    echo "Run: npm install -g firebase-tools"
    exit 1
fi

# Check if Firebase is logged in
firebase projects:list > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Not logged into Firebase CLI!${NC}"
    echo "Run: firebase login"
    exit 1
fi

echo -e "${GREEN}✅ All prerequisites met!${NC}"
echo ""

# Menu for deployment options
echo -e "${YELLOW}📋 Select deployment options:${NC}"
echo "1) Web only"
echo "2) Android only"
echo "3) iOS only (macOS required)"
echo "4) Web + Android"
echo "5) Web + iOS (macOS required)"
echo "6) Android + iOS (macOS required)"
echo "7) All platforms (Web + Android + iOS)"
echo ""

read -p "Enter your choice (1-7): " choice

case $choice in
    1)
        echo -e "${BLUE}🌐 Deploying Web only...${NC}"
        ./scripts/deploy_web.sh
        ;;
    2)
        echo -e "${BLUE}🤖 Building Android only...${NC}"
        ./scripts/build_android.sh
        ;;
    3)
        echo -e "${BLUE}🍎 Building iOS only...${NC}"
        ./scripts/build_ios.sh
        ;;
    4)
        echo -e "${BLUE}🌐🤖 Deploying Web + Building Android...${NC}"
        ./scripts/deploy_web.sh
        if [ $? -eq 0 ]; then
            ./scripts/build_android.sh
        fi
        ;;
    5)
        echo -e "${BLUE}🌐🍎 Deploying Web + Building iOS...${NC}"
        ./scripts/deploy_web.sh
        if [ $? -eq 0 ]; then
            ./scripts/build_ios.sh
        fi
        ;;
    6)
        echo -e "${BLUE}🤖🍎 Building Android + iOS...${NC}"
        ./scripts/build_android.sh
        if [ $? -eq 0 ]; then
            ./scripts/build_ios.sh
        fi
        ;;
    7)
        echo -e "${BLUE}🌐🤖🍎 Deploying all platforms...${NC}"
        ./scripts/deploy_web.sh
        if [ $? -eq 0 ]; then
            ./scripts/build_android.sh
            if [ $? -eq 0 ]; then
                ./scripts/build_ios.sh
            fi
        fi
        ;;
    *)
        echo -e "${RED}❌ Invalid choice!${NC}"
        exit 1
        ;;
esac

# Final summary
echo ""
echo -e "${PURPLE}🎉 Deployment Summary:${NC}"
echo -e "${GREEN}✨ BugCash deployment pipeline completed! ✨${NC}"

# Show deployment URLs and file locations
if [[ $choice == 1 || $choice == 4 || $choice == 5 || $choice == 7 ]]; then
    echo -e "${BLUE}🌐 Web App: https://bugcash.web.app${NC}"
fi

if [[ $choice == 2 || $choice == 4 || $choice == 6 || $choice == 7 ]]; then
    echo -e "${GREEN}🤖 Android APK: build/app/outputs/flutter-apk/app-release.apk${NC}"
    echo -e "${GREEN}🏪 Android AAB: build/app/outputs/bundle/release/app-release.aab${NC}"
fi

if [[ $choice == 3 || $choice == 5 || $choice == 6 || $choice == 7 ]]; then
    echo -e "${YELLOW}🍎 iOS: Open ios/Runner.xcworkspace in Xcode${NC}"
fi

echo ""
echo -e "${PURPLE}Thank you for using BugCash Deployment Pipeline! 🚀${NC}"