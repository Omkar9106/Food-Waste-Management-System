# Vercel Flutter Build Fix

## Problem
Vercel doesn't have Flutter SDK pre-installed, causing "flutter: command not found" error.

## Solution 1: Build Locally and Deploy Static Files (Recommended)

This is the fastest and most reliable method:

### Steps:
1. Build the Flutter web app locally:
   ```bash
   flutter build web --release
   ```

2. Commit the `build/web` directory to Git:
   ```bash
   git add build/web
   git commit -m "Add web build"
   git push origin main
   ```

3. Update `vercel.json` to simple static deployment:
   ```json
   {
     "outputDirectory": "build/web",
     "rewrites": [
       {
         "source": "/(.*)",
         "destination": "/index.html"
       }
     ]
   }
   ```

4. Deploy to Vercel - no build needed, just serves static files

### Pros:
- ✅ Fast deployment (no build time)
- ✅ Reliable (no Flutter installation issues)
- ✅ Smaller Vercel build logs
- ✅ Works offline

### Cons:
- ❌ Need to rebuild locally after code changes
- ❌ Larger Git repository

---

## Solution 2: Install Flutter During Build (Current Setup)

The current setup uses `build-web.sh` to download and install Flutter SDK during the Vercel build.

### How it works:
1. Downloads Flutter SDK from Google's storage
2. Extracts to `$HOME/flutter`
3. Adds to PATH
4. Builds the web app

### Pros:
- ✅ Automatic builds on Git push
- ✅ No local build needed

### Cons:
- ❌ Slower deployment (downloads Flutter each build)
- ❌ May timeout on slow connections
- ❌ Uses more Vercel build minutes

---

## Solution 3: Use Vercel Build Image (Advanced)

Use a custom Docker image with Flutter pre-installed.

### Update `vercel.json`:
```json
{
  "buildCommand": "flutter build web --release",
  "outputDirectory": "build/web",
  "rewrites": [
    {
      "source": "/(.*)",
      "destination": "/index.html"
    }
  ]
}
```

### In Vercel Dashboard:
1. Go to Settings → General
2. Set "Build & Development Settings" → "Build Image" to a custom image with Flutter
3. Or use Vercel's "Other" framework with custom build settings

---

## Recommended Approach

**For development**: Use Solution 1 (build locally) - fastest and most reliable

**For production CI/CD**: Use Solution 2 (current setup) - automatic builds

## Switching to Solution 1 (Local Build)

If you want to switch to the local build approach:

1. Build locally:
   ```bash
   flutter build web --release --web-renderer canvaskit
   ```

2. Update `.gitignore` to allow `build/web`:
   ```bash
   # Remove this line from .gitignore:
   # /build/
   
   # Or change to:
   /build/android/
   /build/ios/
   /build/windows/
   /build/linux/
   /build/macos/
   ```

3. Commit the build:
   ```bash
   git add build/web
   git commit -m "Add web build"
   git push origin main
   ```

4. Update `vercel.json` to remove build command:
   ```json
   {
     "outputDirectory": "build/web",
     "rewrites": [
       {
         "source": "/(.*)",
         "destination": "/index.html"
       }
     ]
   }
   ```

5. Redeploy in Vercel
