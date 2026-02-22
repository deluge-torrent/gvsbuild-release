# Deluge gvsbuild Releases

Builds custom [gvsbuild] Windows releases for the Deluge GTK UI, including Python bindings and patches as needed.

[gvsbuild]: https://github.com/wingtk/gvsbuild

## Overview

This repository automates building gvsbuild releases with Deluge-specific configurations:

- **Customizable patches**: Apply patches from `gvsbuild/patches/` during build
- **Python versions**: See [workflow matrix](.github/workflows/release.yml) for current build targets
- **Deluge stack**: GTK3, PyGObject, LZ4, Enchant, and Adwaita icons

## Building Releases

Releases are built automatically via GitHub Actions:

1. Checks out this repo (for patches and configuration)
2. Checks out [wingtk/gvsbuild]
3. Applies any patches via [`apply-glib-patches.ps1`](apply-glib-patches.ps1)
4. Builds gvsbuild with patches applied
5. Creates release artifacts

[wingtk/gvsbuild]: https://github.com/wingtk/gvsbuild

### Manual Workflow Trigger

Go to [Actions → Release](../../actions/workflows/release.yml) and click "Run workflow":

- **fork**: gvsbuild fork to use (default: `wingtk`)
- **ref**: git branch/tag to checkout (default: `main`)

### Build Artifacts

Each run produces release archives for the configured Python versions and platforms defined in the [workflow matrix](.github/workflows/release.yml).

Artifacts are named: `gvsbuild-py{version}-vs{vstudio}-{platform}.zip`

## Patches

Patches are organized by project in `gvsbuild/patches/`:

```
gvsbuild/
└── patches/
    ├── glib/
    │   ├── README.md
    │   └── *.patch
    └── [other-projects]/
```

See individual patch directories for details on what each patch does.

## Adding Patches

1. Create a branch for your patch work
2. Add patches to `gvsbuild/patches/[project]/`
3. The build workflow automatically applies and registers them
4. Patch numbers must not conflict with existing patches in gvsbuild
