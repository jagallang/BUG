#!/bin/bash

echo "🚀 Setting up BugCash Server Development Environment"
echo "================================================="

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 18+ first."
    exit 1
fi

# Check Node.js version
NODE_VERSION=$(node -v)
echo "✅ Node.js version: $NODE_VERSION"

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "❌ npm is not installed."
    exit 1
fi

# Install dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
else
    echo "✅ Dependencies already installed"
fi

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "⚠️  .env file not found. Copying from .env.example"
    cp .env.example .env
    echo "⚠️  Please edit .env file with your actual configuration"
else
    echo "✅ .env file exists"
fi

echo ""
echo "🎯 Development Setup Complete!"
echo ""
echo "Quick Start Commands:"
echo "  npm run dev    - Start development server with hot reload"
echo "  npm start      - Start production server"
echo "  npm test       - Run tests"
echo ""
echo "📝 Next Steps:"
echo "  1. Edit .env file with your Firebase and AWS credentials"
echo "  2. Set up Firebase Admin SDK key (firebase-admin-key.json)"
echo "  3. Start the development server: npm run dev"
echo ""