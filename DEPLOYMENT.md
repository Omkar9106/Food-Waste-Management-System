# Vercel Deployment Guide for Flutter Web

This guide will help you deploy the Flutter web app to Vercel.

## Prerequisites

1. Flutter SDK installed (version 3.11.1 or higher)
2. Vercel account (free tier works)
3. Git repository (GitHub, GitLab, or Bitbucket)

## Deployment Steps

### Option 1: Automatic Deployment via Git (Recommended)

1. **Push your code to a Git repository**
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   git branch -M main
   git remote add origin <your-repository-url>
   git push -u origin main
   ```

2. **Import project in Vercel**
   - Go to [vercel.com](https://vercel.com)
   - Click "Add New Project"
   - Import your Git repository
   - Vercel will detect the Flutter project

3. **Configure Build Settings**
   - **Framework Preset**: Other
   - **Build Command**: `flutter build web --release`
   - **Output Directory**: `build/web`
   - **Install Command**: `flutter pub get`

4. **Deploy**
   - Click "Deploy"
   - Wait for the build to complete
   - Your app will be live at `https://your-project.vercel.app`

### Option 2: Manual Deployment

1. **Build the web app locally**
   ```bash
   # On Windows (Git Bash or PowerShell)
   flutter build web --release
   
   # Or use the provided script
   chmod +x build-web.sh
   ./build-web.sh
   ```

2. **Deploy using Vercel CLI**
   ```bash
   # Install Vercel CLI
   npm i -g vercel
   
   # Login to Vercel
   vercel login
   
   # Deploy
   vercel --prod
   ```

## Configuration Files

### vercel.json
This file tells Vercel how to handle the Flutter web build:
- Routes all traffic to the build/web directory
- Enables client-side routing with SPA fallback

### .vercelignore
Excludes unnecessary files from deployment to speed up builds.

## Firebase Configuration for Web

If you need Firebase web support, you'll need to:

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Click the gear icon → Project settings
4. Scroll to "Your apps" → Add Web app
5. Copy the Firebase config object
6. Create `web/firebase_options.js` with the config
7. Update `lib/main.dart` to initialize Firebase for web

Example `web/firebase_options.js`:
```javascript
const firebaseConfig = {
  apiKey: "YOUR_API_KEY",
  authDomain: "YOUR_PROJECT.firebaseapp.com",
  projectId: "YOUR_PROJECT_ID",
  storageBucket: "YOUR_PROJECT.appspot.com",
  messagingSenderId: "YOUR_SENDER_ID",
  appId: "YOUR_APP_ID"
};
```

## Important Notes

1. **Renderer**: The build uses CanvasKit renderer for better performance
2. **Base URL**: The `--base-href` flag is automatically handled by Vercel
3. **Routing**: Client-side routing works with the vercel.json configuration
4. **Environment Variables**: Add any required environment variables in Vercel dashboard

## Troubleshooting

### Build fails
- Ensure Flutter is installed and in PATH
- Check that all dependencies are installed: `flutter pub get`
- Verify the build command works locally first

### Blank screen on deployment
- Check browser console for errors
- Verify Firebase configuration if using Firebase
- Ensure the build output directory is correct (`build/web`)

### Routing issues
- The vercel.json configuration handles SPA routing
- All routes should redirect to index.html

## Performance Optimization

The build is optimized with:
- CanvasKit renderer for better performance
- Release mode for production
- Static file serving via Vercel CDN

## Updating the App

After making changes:
1. Commit and push to Git (automatic deployment)
2. Or run `vercel --prod` for manual deployment
