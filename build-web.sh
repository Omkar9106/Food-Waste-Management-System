#!/bin/bash

# Flutter Web Build Script for Vercel Deployment

echo "🔧 Building Flutter Web App for Vercel..."

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build web app
flutter build web --release --web-renderer canvaskit

echo "✅ Build complete! The web app is ready in the 'build/web' directory."
