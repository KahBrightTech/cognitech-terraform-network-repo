# Image Guide for AfriqueOriginal

## Folder Structure

```
frontend/public/images/
├── hero.jpg                    # Main hero image (woman in African wear)
├── countries/                  # Country card images
│   ├── nigeria.jpg
│   ├── ghana.jpg
│   ├── senegal.jpg
│   ├── morocco.jpg
│   ├── kenya.jpg
│   └── south-africa.jpg
└── products/                   # Product catalog images (optional)
```

## How to Add Your Images

1. **Hero Image**: Save your main hero image as `hero.jpg` in `/images/`
2. **Country Images**: Save each country image in `/images/countries/` with the exact names shown above
3. Make sure images are in `.jpg`, `.jpeg`, or `.png` format
4. Recommended sizes:
   - Hero: 1600x650px or larger
   - Countries: 400x400px or larger

## After Adding Images

Run this command to rebuild the frontend:
```bash
docker-compose up -d --build frontend
```

Your images will now appear on the website!
