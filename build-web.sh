#!/bin/bash

# Flutter Web Build Script for Vercel Deployment

echo "🔧 Setting up Flutter SDK for Vercel..."

# Set Flutter SDK path
FLUTTER_PATH="$HOME/flutter"
export PATH="$PATH:$FLUTTER_PATH/bin"

# Download and install Flutter SDK if not present
if [ ! -d "$FLUTTER_PATH" ]; then
  echo "📥 Downloading Flutter SDK..."
  # Download Flutter stable release
  wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz -O /tmp/flutter.tar.xz
  mkdir -p $FLUTTER_PATH
  tar xf /tmp/flutter.tar.xz -C $HOME --strip-components=1
  rm /tmp/flutter.tar.xz
fi

# Enable Flutter web
flutter config --enable-web

echo "🔧 Building Flutter Web App for Vercel..."

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build web app
flutter build web --release

echo "✅ Build complete! The web app is ready in the 'build/web' directory."
