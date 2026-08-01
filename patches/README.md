# Core-source patches

These patch files modify OrangeFox's own **core source** (`bootable/recovery/`),
not this device tree. They cannot be "installed" by placing them here —
this folder is just where they're kept for reference. You must apply them
against the actual core source during your build.

## partitionmanager_merge_fix.patch

Found via comparison with a real, working MediaTek Android-16 OrangeFox
device tree (POCO X6 Pro / duchamp). Patches `TWPartitionManager::Check_Pending_Merges()`
in `partitionmanager.cpp` so it only runs the Virtual A/B snapshot-merge
/ `Unmap_Super_Devices()` logic when a real pending OTA snapshot marker
(`/metadata/ota/snapshot-boot`) actually exists — instead of running it
**unconditionally on every single boot**, which can unmap the very
logical partitions (system/vendor/product/odm) this device tree just
spent so much effort getting to mount correctly via `flags=logical`.

This is a plausible contributor to the still-unresolved "bootctrl module"
error and any other intermittent instability seen after a slot change.

### How to apply it

After `repo sync`, before building:
```bash
cd bootable/recovery   # or wherever OrangeFox's core recovery source lives in your tree
patch -p1 < /path/to/this/patches/partitionmanager_merge_fix.patch
# or, if that source is its own git repo:
git apply /path/to/this/patches/partitionmanager_merge_fix.patch
```
If the patch doesn't apply cleanly (line numbers can drift between
OrangeFox versions), open `partitionmanager.cpp`, find
`TWPartitionManager::Check_Pending_Merges()`, and apply the same change
by hand — add the `access("/metadata/ota/snapshot-boot", F_OK)` early-return
check at the top of the function, before it calls `Unmap_Super_Devices()`.
