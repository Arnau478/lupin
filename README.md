Lupin Linux is a *build-time configured*, *non-persistent*, *reproducible* linux distribution.

**WARNING**: Very early in development

# Uses

Lupin Linux doesn't have a *runtime* package manager -- instead, you decide which packages you want at build time. It is designed for portable, small, non-persistent images (e.g. a USB to perform troubleshooting of other systems). It's always useful to have a micro-SD card or USB with a linux image with you.

# Configuration

Everything is configured in a single file, `.config`, which follows a simple `KEY=value` format.

# Build

For the sake of simplicity in the build process, we use docker:

```
docker build --output type=local,dest=out .
```

You could also compile running the shell scripts directly with some modificantions, but it's not recommended.
