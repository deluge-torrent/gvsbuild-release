# GLib Patches for Deluge

This directory contains patches that are applied to GLib during the gvsbuild build process.

## Patches

### 003-fix-win-socket-errors.patch

Fixes GLib's broken socket event delivery on Windows, which prevented Twisted's GI/GTK reactor from working reliably.

**Problem:** GLib's Windows socket implementation (`glib/giowin32.c`) fails to deliver socket events after `source_remove`/`io_add_watch` cycles, causing 120+ second hangs waiting for write (OUT) events that never arrive.

**Solution:** Reset `event_mask` in two places:
1. `g_io_win32_sock_create_watch()` - Force fresh WSAEventSelect for new watches
2. `g_io_win32_finalize()` - Clean state on channel close

**References:**
- [GLib GitLab #214](https://gitlab.gnome.org/GNOME/glib/-/issues/214) - Missing `WSAEventSelect` call
- [GLib GitLab #40](https://gitlab.gnome.org/GNOME/glib/-/issues/40) - Async IO stalls
- Development repo: `/home/calum/Projects/Deluge/glib-win-errors`

## Usage

Patches are automatically applied by the `apply-glib-patches.ps1` script during the GitHub Actions build workflow.
