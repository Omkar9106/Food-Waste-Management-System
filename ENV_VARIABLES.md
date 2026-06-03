# Environment Variables for Vercel Deployment

This document lists all environment variables needed for Vercel deployment.

## Required Environment Variables

### Firebase Configuration

These are already configured in `lib/firebase_options.dart` but can be moved to environment variables for better security.

| Variable Name | Value | Description |
|--------------|-------|-------------|
| `FIREBASE_API_KEY` | `AIzaSyCUhMo0Z7chEEfuLZgzKJXxSxs-nriv8yA` | Firebase Web API Key |
| `FIREBASE_APP_ID` | `1:716084398651:web:6aaee5c916f8fc6b152a1e` | Firebase Web App ID |
| `FIREBASE_PROJECT_ID` | `food-waste-management-549d6` | Firebase Project ID |
| `FIREBASE_MESSAGING_SENDER_ID` | `716084398651` | Firebase Messaging Sender ID |
| `FIREBASE_AUTH_DOMAIN` | `food-waste-management-549d6.firebaseapp.com` | Firebase Auth Domain |
| `FIREBASE_STORAGE_BUCKET` | `food-waste-management-549d6.firebasestorage.app` | Firebase Storage Bucket |

### Google Maps API Key (Required for Web)

**IMPORTANT**: This is required for location services (Geolocator & Geocoding) to work on web.

| Variable Name | Value | Description |
|--------------|-------|-------------|
| `GOOGLE_MAPS_API_KEY` | `your_google_maps_api_key_here` | Google Maps JavaScript API Key |

#### How to Get Google Maps API Key:

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project or select existing project
3. Go to **APIs & Services** → **Credentials**
4. Click **Create Credentials** → **API Key**
5. Restrict the API key:
   - **Application restrictions**: Add your Vercel domain (e.g., `your-project.vercel.app`)
   - **API restrictions**: Enable only these APIs:
     - Maps JavaScript API
     - Geocoding API
     - Places API
6. Copy the API key and add to Vercel environment variables

### Optional Environment Variables

| Variable Name | Value | Description |
|--------------|-------|-------------|
| `FLUTTER_ENV` | `production` | Environment (development/production) |

## How to Add Environment Variables in Vercel

### Option 1: Via Vercel Dashboard

1. Go to your project in [Vercel Dashboard](https://vercel.com/dashboard)
2. Click **Settings** → **Environment Variables**
3. Add each variable from the table above
4. Click **Save**
5. Redeploy your project

### Option 2: Via Vercel CLI

```bash
# Set environment variables
vercel env add FIREBASE_API_KEY
vercel env add FIREBASE_APP_ID
vercel env add FIREBASE_PROJECT_ID
vercel env add FIREBASE_MESSAGING_SENDER_ID
vercel env add FIREBASE_AUTH_DOMAIN
vercel env add FIREBASE_STORAGE_BUCKET
vercel env add GOOGLE_MAPS_API_KEY

# Deploy with environment variables
vercel --prod
```

## Current Status

**Firebase**: Currently hardcoded in `lib/firebase_options.dart` - will work without environment variables but less secure.

**Google Maps API**: Required for web location services. You MUST set this up for geolocator and geocoding to work on web deployment.

## Notes

1. **Firebase values are already configured** in the code, so the app will work without setting Firebase environment variables. However, for production best practices, consider moving them to environment variables.

2. **Google Maps API Key is REQUIRED** for web location services. Without it, geolocator and geocoding features will not work on the web version.

3. **Never commit actual API keys** to your repository. Use the `.env.example` file as a template and add real values only in Vercel.

4. **Restrict your API keys** in Google Cloud Console to only allow requests from your Vercel domain for security.

## Testing Environment Variables

After setting up environment variables, you can test them locally:

```bash
# Install dotenv package
flutter pub add flutter_dotenv

# Create .env file locally (add to .gitignore)
# Copy values from .env.example and add real values

# Test locally
flutter run -d chrome
```

## Security Best Practices

1. **Restrict API keys** to specific domains and APIs
2. **Use different keys** for development and production
3. **Rotate keys periodically** if compromised
4. **Monitor usage** in Google Cloud Console and Firebase Console
5. **Never expose keys** in client-side code (use environment variables)
