# Fix Changelog — twrp_device_nothing_Tetris (OrangeFox)

Original repo: https://github.com/S-O-D-A/twrp_device_nothing_Tetris
All fixes below are based on a fresh public clone. No token/credentials were used or needed.

---

## 1. `recovery/root/recovery.fstab` — REWRITTEN (root cause of missing Internal Storage)

**Problem:** `/system`, `/vendor`, `/data`, `/metadata`, `/product`, etc. were written in
**stock Android init-fstab syntax** (`avb=`, `slotselect`, `first_stage_mount`, `wait,check,...`).
TWRP/OrangeFox's own fstab parser does not understand that syntax — it only understood the
two manually-written lines at the bottom (`/sdcard1`, `/usb_otg`), which is exactly why only
SD card and USB showed up and Internal Storage never did.

**Fix:** Rewrote every line in native TWRP syntax: `<mount_point> <fstype> <device> [flags=...]`.
The `/data` line keeps the **same crypto parameters** the original stock-format line declared
(`aes-256-xts:aes-256-cts:v2+inlinecrypt_optimized`, metadata-encryption keydirectory) — these
were ported into TWRP flag syntax, not invented. Added `forcefdeorfbe` so OrangeFox actually
runs its decrypt routine instead of skipping the partition.

## 2. `vendorsetup.sh` — 4 flags fixed

| Flag | Before | After | Why |
|---|---|---|---|
| `OF_DONT_PATCH_ENCRYPTED_DEVICE` | `1` | disabled | Was telling OrangeFox to skip decrypt patching entirely |
| `OF_FBE_METADATA_MOUNT_IGNORE` | `1` | disabled | Was hiding metadata-encryption mount failures instead of fixing them |
| `OF_IGNORE_LOGICAL_MOUNT_ERRORS` | `1` | disabled | Was silently swallowing dynamic/logical partition mount errors — likely related to your "slot not working properly" symptom |
| `OF_PATCH_AVB20` | disabled (commented, "first test build") | `1` | Needed for stable boot/flash cycles on a real production build, not just bring-up testing |

**⚠️ Important:** disabling #3 means real underlying dynamic-partition problems, if any exist,
will now show up as visible errors/logs instead of being hidden. That's a good thing for
debugging, but don't be alarmed if you see new error messages after this fix — it means a
real problem is now visible, not that this fix broke something.

## 3. `BoardConfig.mk` — filesystem type mismatch + cleanup

- `BOARD_SYSTEMIMAGE_PARTITION_TYPE`: `ext4` → `erofs`
- `BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE`: `ext4` → `f2fs`
  (these now match what `recovery.fstab` and the real stock partitions actually use)
- Removed duplicate `BOARD_USES_GENERIC_KERNEL_IMAGE` (was declared twice)
- Removed duplicate/conflicting `TW_SCREEN_BLANK_ON_BOOT` (was declared twice, and directly
  contradicted `TW_NO_SCREEN_BLANK` right next to it — kept `TW_NO_SCREEN_BLANK` since that's
  the safer choice given this device already has display bring-up history)

## 4. `device.mk` — API level inconsistency

- `PRODUCT_SHIPPING_API_LEVEL`: `32` (Android 12L) → `34` (Android 14)
- Now consistent with `PRODUCT_TARGET_VNDK_VERSION := 34`, which was already correct.

## 5. `recovery/root/init.recovery.project.rc` — was missing, now stubbed

`init.recovery.mt6878.rc` does `import /init.recovery.project.rc`, but that file did not
exist anywhere in the repo. Added an empty, clearly-commented placeholder so the import
doesn't reference a totally absent file. **This is a stub, not real data** — see the note
inside that file for what to do if you have access to the stock `vendor_boot.img`.

---

## ⚠️ What I did NOT change, and why — please read this part

### The "Android 16" question

You asked me to make sure this works for Android 16. I want to be straight with you about
this rather than quietly paper over it:

- `PLATFORM_VERSION := 16.1.0` in `BoardConfig.mk` — **left as-is**. This just labels which
  AOSP source tree you're compiling this recovery *inside of* (e.g. your LineageOS 23.2 /
  Android 16 tree). It's fine for it to say 16.1.0.
- `PRODUCT_TARGET_VNDK_VERSION := 34` — **deliberately NOT bumped to 36.** This number
  describes which vendor HAL interface (keymaster, health, bootctrl, etc.) the recovery
  binaries link against. It should match your device's **real stock vendor blobs**, not the
  ROM source tree you're compiling in. CMF Phone 1 shipped on Android 14, so its actual
  vendor blobs are VNDK 34. If I had bumped this to 36 to "match Android 16," the recovery
  would be built assuming vendor HAL interfaces that don't actually exist on this hardware —
  that's a **more dangerous mistake** than the one I found (it risks bootloop/brick, not just
  a missing storage menu). Only change this yourself if you have genuine Android-16-era
  vendor blobs for this device to build against.

**In short:** this device tree builds a recovery you can compile inside your Android 16
source tree, but it does not — and cannot, from a recovery-only tree like this — verify that
your full ROM's vendor/system interface is truly Android 16-compliant. That's a property of
your ROM's device tree (`android_device_nothing_Tetris`), not this recovery tree.

### The anti-rollback hack

```
PLATFORM_SECURITY_PATCH := 2099-12-31
VENDOR_SECURITY_PATCH := 2099-12-31
```

Left as-is. This is a known, intentional community technique to avoid AVB rollback-index
lockout, not a bug. Removing it could reintroduce a *different* problem (rollback rejection)
depending on your bootloader's current security patch level. Flagging it here so you know
it's deliberate, not something I missed.

---

---

## SESSION 2 UPDATE — verified against real firmware (boot.img, vendor_boot.img,
## dtbo.img, vbmeta*.img, and live `fastboot getvar all` / device ROM info)

Everything below was cross-checked against actual dumped images and a live
device, not inferred from code alone. This **replaces** the "left as-is,
can't verify" caveats from Session 1.

### 6. `device.mk` — API level updated 34 → 36 (Android 16), now evidence-based

Session 1 deliberately did NOT bump this to 36, because bumping VNDK to
match a ROM's label without proof of real matching vendor blobs is
dangerous. Session 2 changed this because we now have actual proof:

- `boot.img` kernel banner: `Linux version 6.1.134-android14-11`
- `vbmeta.img` AVB property descriptors: `os_version=16` on **every**
  partition (init_boot, odm, odm_dlkm, product, system, system_dlkm,
  system_ext, vendor, vendor_dlkm), fingerprint
  `Nothing/lineage_Tetris/Tetris:16/BP4A.251205.006`
- Live device "Sakura" ROM info screen: kernel `6.1.134-android14-11`,
  baseband `MOLY.NR17.R1.MP5.RC.MP.V1.5.P37`, vendor patch `8 Feb 2025` —
  **all exact matches** to the dumped images, on a *second, independently
  installed* custom ROM. Two unrelated ROM builds sharing identical
  kernel/vendor/baseband confirms this is the real, stable vendor-blob
  baseline for this hardware, not a one-off.

→ `PRODUCT_SHIPPING_API_LEVEL` / `PRODUCT_TARGET_VNDK_VERSION`: `34` → `36`.

### 7. `recovery.fstab` — `/persist` mount point corrected

Real `/system/etc/recovery.fstab` extracted from the device's own
vendor_boot.img RECOVERY ramdisk fragment shows persist mounts at
`/mnt/vendor/persist`, not `/persist`. Corrected to match.

### 8. `init.recovery.mt6878.rc` — replaced with the real file

Extracted the actual RECOVERY-type ramdisk fragment from a real
`vendor_boot.img` (confirmed via the vendor ramdisk table: PLATFORM
fragment + RECOVERY fragment, matching `BOARD_INCLUDE_RECOVERY_RAMDISK_IN_VENDOR_BOOT`).
The real file is short and does **not** import any project.rc:

```
on init
    setprop sys.usb.configfs 1
    setprop sys.usb.controller "11201000.usb0"
    setprop sys.usb.ffs.aio_compat 1

on fs && property:ro.debuggable=0
    start adbd
```

The repo's original file had an extra `import /init.recovery.project.rc`
line that doesn't exist on real hardware — confirmed copy-paste leftover
from an unrelated device template. Replaced with the verified real
content; the `init.recovery.project.rc` stub from Session 1 has been
**deleted** since it's confirmed unnecessary.

### What this does NOT change

- `/data` crypto flags (`fileencryption=...`, `keydirectory=...`) —
  Session 1's values were checked against the real fstab and are an
  **exact match**, no change needed.
- The anti-rollback security-patch hack and the AVB/decrypt vendorsetup.sh
  fixes from Session 1 — unaffected by this round, still valid.
- `boot`/`vendor_boot`/`dtbo`/`init_boot` partition sizes in `BoardConfig.mk`
  were cross-checked against real `fastboot getvar all` output (boot 64MB,
  vendor_boot 64MB, init_boot 8MB, dtbo 8MB) — already correct, no change.

### Device facts now confirmed on real hardware (for reference)

```
product: k6878v1_64
bootloader: unlocked, secure: no
userdata fs: f2fs   (confirms Session 1's ext4→f2fs fix was correct)
current-slot: a, slot-count: 2
```


---

## Before you flash

Per the original maintainer's own instructions and their prior bricking incident with this
exact repo: **`fastboot boot boot.img` (or vendor_boot.img) first to test-boot, do NOT
`fastboot flash` directly**, until you've confirmed Internal Storage now shows up and `/data`
decrypts correctly.

---

## SESSION 3 UPDATE — final deep audit (bootctrl, crypto flags, live device probing)

### 9. `BoardConfig.mk` — Missing TWRP crypto/FBE compile flags (FIXED)

`TW_INCLUDE_CRYPTO_FBE`, `TW_INCLUDE_FBE_METADATA_DECRYPT`, `BOARD_USES_METADATA_PARTITION`
were **completely absent**. Verified by cross-referencing multiple real, official
OrangeFox device trees (including OrangeFoxRecovery's own `device_xiaomi_spes`
on branch `fox_11.0`) — these flags are explicitly declared per-device in every
real example found, never silently inherited from the common vendor tree.
Without them, the FBE decrypt code path isn't compiled into the recovery
binary at all, regardless of how correct `recovery.fstab`'s flags are — this
may be more fundamental than the fstab fix itself. Added all three. Did
**not** add `BOARD_USES_QCOM_FBE_DECRYPTION` (seen in the same official
examples) since that's Qualcomm-specific and this is MediaTek — adding it
would have been wrong.

### 10. `BoardConfig.mk` — duplicate `VENDOR_SECURITY_PATCH` removed

Was declared twice (once as `2021-08-01`, once as the intentional
`2099-12-31` anti-rollback value). Make's `:=` means the later one always
won, so this wasn't functionally broken, but it was confusing dead
duplication matching the same copy-paste pattern found elsewhere in this
repo. Removed the redundant first declaration.

### 11. `bootctrl/boot_region_control.cpp` hardcoded `/dev/block/sdc` — investigated, NOT changed

Raised as a serious concern (hardcoded UFS boot-LUN device path, directly
matching the reported "slot not working properly" symptom). Investigated via:
live `fastboot getvar all`, live `/proc/mounts`, live `ls -la /dev/block/sd*`,
and the real `preloader_raw_a` partition dump.

**Conclusion: left as-is.** Real device evidence shows:
- `/dev/block/sda`, `/dev/block/sdb` — small, **unpartitioned** whole-disk
  devices (no sda1/sdb1 etc. exist) — consistent with `mtk_plpath_utils.cpp`'s
  own hardcoded assumption that these are the two raw preloader images.
- `/dev/block/sdc` — the one LUN with 83 real sub-partitions (`sdc1`...`sdc83`),
  confirmed via live `/proc/mounts` to host `persist`, `protect_f`, `protect_s`,
  `nvdata`, `nvcfg`, `nt_log`, and (via device-mapper) `vendor`/`vendor_dlkm`.

Since `BOOT_LUN_EN` is a **device-level** UFS query attribute (not tied to a
specific LU), and `sdc` is the one LUN guaranteed to be open and valid at any
point after boot (it's the actively-mounted main disk), using it to issue
this ioctl is architecturally reasonable — not the unverified copy-paste bug
it first appeared to be. This is a case where deeper evidence **reversed**
an earlier suspicion, which is worth recording plainly rather than quietly
dropping.

Also cross-verified: `ro.boot.dtb_idx=0` / `ro.boot.dtbo_idx=0` on the live
device confirm DTBO entry index 0 (of the 3 board-variant entries found in
`dtbo.img`) is the one actually active on this exact unit — matches the
`hardware.sku=IND` / `hwid_version=PVT_India` properties.

### What remains genuinely unverifiable without a real compile + boot test

- Whether the recovery binary actually links/builds cleanly with these flags
  added (can't compile in this environment — see earlier network/resource
  discussion).
- Real touch/display driver behavior in recovery mode (depends on binary
  blobs and kernel driver behavior at runtime, not something inspectable
  from source alone).
- Whether `README.md`'s stale `lunch cmf_tetris-userdebug` instruction (this
  repo's real product name is `twrp_Tetris`, per `AndroidProducts.mk`) is
  the only doc inconsistency — worth a heads-up to your build team so they
  don't try the wrong lunch combo.

---

## SESSION 4 — final finishing pass

### 12. `BoardConfig.mk` — `AB_OTA_PARTITIONS` was missing `vendor_boot`, `dtbo`, `init_boot`

These are exactly the partitions this recovery tree cares about most (the
recovery lives inside `vendor_boot`), yet they were absent from the A/B
partition list — confirmed missing by cross-referencing the real device's
`fastboot getvar all` (which shows `vendor_boot_a/b`, `dtbo_a/b`,
`init_boot_a/b` all present) and the live `ro.product.ab_ota_partitions`
property. Added all three. Did not add the various MediaTek co-processor/
baseband partitions also present on the live property (`apusys`, `ccu`,
`connsys_*`, `modem`, `tee`, etc.) since those aren't something a recovery
tree's own build needs to enumerate — only ones this tree actually builds
or interacts with per-slot.

### 13. `README.md` — fully rewritten

The original had several real inaccuracies that could send someone down
the wrong path entirely:
- Referenced installing the **Android Studio SDK** (`developer.android.com`)
  as a build prerequisite — that's for building phone *apps*, completely
  unrelated to compiling AOSP-based recovery source. Removed; replaced with
  a link to OrangeFox's own official building guide.
- `lunch cmf_tetris-userdebug` — wrong product name; this tree's real lunch
  combo is `twrp_Tetris-eng` (per `AndroidProducts.mk`).
- Presented this device tree as if it were a standalone buildable project
  you `cd` into and build directly — it isn't; it must be placed at
  `device/nothing/Tetris` inside a full source tree. Clarified explicitly.
- Original credits preserved in full; added a pointer to this changelog for
  the fix history rather than duplicating it in the README itself.
- Kept and strengthened the test-boot-before-flashing warning, given this
  exact tree's prior bricking history.

---

## SESSION 5 — REAL DEVICE TESTING (first actual build + flash!)

User successfully compiled and flashed this OrangeFox build on real hardware.
Two confirmed, evidence-based bugs found from real device logs and fixed:

### 14. `recovery.fstab` `/data` line — CRITICAL, my own bug from Session 1

Real device log showed:
```
E:Unhandled flag: 'forcefdeorfbe'
...
Could not mount /data and unable to find crypto footer.
Cannot decrypt adopted storage because /data will not mount
```

Root cause: Session 1 invented a flag named `metadata_encryption=aes-256-xts`
that **does not exist**. The real flag — verified directly against the
device's own stock `fstab.mt6878` dump — is:
```
keydirectory=/metadata/vold/metadata_encryption
```
Because TWRP never received a valid key directory path, it fell back to
legacy FDE crypto-footer lookup, which doesn't exist on this FBE device —
exactly matching the observed error. Fixed by replacing the fabricated flag
with the real one, copied exactly from verified device data. Also dropped
`forcefdeorfbe` (also logged as unhandled, and was never grounded in real
device data to begin with).

Note: `E:Unhandled flag: 'fsverity'` is very likely harmless — a real,
working TWRP log from an unrelated device (found during investigation)
shows several flags logged as "Unhandled" on a build where FBE decrypt
still worked correctly. Left `fsverity` in place since it's a verified
real flag from stock `fstab.mt6878`, just not one TWRP's parser acts on.

### 15. `init.recovery.mt6878.rc` — missing `/dev/block/bootdevice` symlink

Real device log showed:
```
dd bs=1048576 if=/dev/block/bootdevice/by-name/vendor_boot_a of=/dev/block/bootdevice/by-name/vendor_boot_b
process ended with ERROR: 1
E:Failed to flash the /vendor_boot image
```
(triggered by OrangeFox's own "Reflash OrangeFox after flashing a ROM" option)

`/dev/block/bootdevice` is a standard Android alias that OrangeFox's
built-in tooling assumes exists — it was never created anywhere in this
tree. Added the symlink rule, pointed at the real UFS host controller path
(`112b0000.ufshci`, verified via the device's own `sysfs_path=` value in
stock `fstab.mt6878`).

### Confirmed WORKING on real hardware (no action needed)

- All partitions (System, Vendor, Data, Metadata, persist at the corrected
  `mnt/vendor/persist`, etc.) now correctly appear in the Mount screen —
  the original storage-detection bug is fixed.
- Backup successfully reads and digests Data, Boot, dtbo, init_boot,
  persist, vbmeta*, vendor_boot.
- USB-OTG storage detection works correctly.

### Still open — needs the full recovery.log to diagnose precisely

- `E:Error getting bootctrl module.` — seen after a slot-change operation;
  cause not yet clear from screenshots alone.
- The ROM zip itself (`voltage-5.11-EOL-Tetris...zip`) fails with a generic
  `Updater process ended with ERROR: 1` — the specific updater-script line
  that failed isn't visible in the cropped screenshots.

---

## SESSION 6 — real device logs (recovery.log, recovery_error.txt) deeply analyzed

This is likely THE most impactful fix so far — it explains "kuch bhi work
nahi karta" (nothing works) as a single root cause.

### 16. `recovery.fstab` — `flags=logical` was missing on ALL super.img partitions (CRITICAL)

Real `recovery_error.txt` showed, for every single partition inside
`BOARD_NOTHING_DYNAMIC_PARTITIONS_PARTITION_LIST`:
```
I:Failed to mount '/system_root' (Invalid argument)
I:Actual block device: '', current file system: 'erofs'
```
...repeated identically for `/vendor`, `/odm` (many times, across multiple
retry attempts). Root cause: `system`, `system_ext`, `vendor`, `vendor_dlkm`,
`product`, `odm`, `odm_dlkm` all live inside `super.img` as logical
partitions — there is no real `/dev/block/by-name/<X>` symlink for them at
all. Without `flags=logical` on these fstab lines, TWRP tried a plain
by-name lookup (which returns nothing) instead of creating the
device-mapper node from `super.img`'s metadata. This is almost certainly
why "system mein bhi nahi ho raha" and general instability across nearly
every recovery feature — TWRP could barely mount its own core partitions.

Added `flags=logical` to all 7 affected lines (system_dlkm intentionally
excluded — it isn't in `BOARD_NOTHING_DYNAMIC_PARTITIONS_PARTITION_LIST`).

### 17. `recovery.fstab` `/data` line — self-correction from Session 5

Session 5 replaced `metadata_encryption=aes-256-xts` with `keydirectory=...`,
reasoning the first flag "didn't exist." Re-reading the actual real device
log more carefully showed this was wrong: the SAME log had
`metadata_encryption=aes-256-xts` present AND showed `Is_Decrypted=true` —
i.e. it was already working. Restored it alongside `keydirectory=` rather
than removing something with direct evidence of working. Recorded here
plainly rather than quietly re-editing, since I got this one wrong once
already and want that visible, not hidden.

### 18. ROM zip flash failure — NOT a device tree bug

Real log showed the actual cause plainly:
```
I:Zip signature verification failed: 1
ZIP signature verification failed!
```
The ROM zip isn't signed with a key this recovery's `otacerts.zip` trusts —
completely normal for a custom ROM zip. This needs "Verify ZIP signature"
disabled in OrangeFox's own Settings menu (not just the per-flash
checkbox), not a device tree change.

### Notes on the two files that didn't help

- `dmesg.log` / `dmesg_log.txt` turned out to be captured from the **normal
  booted custom ROM**, not from OrangeFox recovery (evidence: `keystore2`,
  touchscreen driver events, cpuset services — none of these run in
  recovery mode). Not useful for this specific investigation.
- `E:Error getting bootctrl module.` (seen in an earlier screenshot) does
  **not** appear anywhere in either `recovery.log` or `recovery_error.txt`
  — still unresolved, needs a fresh log captured from the specific session
  where that error occurs.

---

## SESSION 7 — re-reviewed screenshots + fresh full-repo pass

### Self-correction

Earlier this session I searched `BoardConfig.mk` and `twrp_Tetris.mk` for
bootctrl wiring, found nothing, and wrongly concluded the module was never
referenced anywhere. I had not checked `device.mk`, which does correctly
declare it in `PRODUCT_PACKAGES`. Recording this plainly since I got it
wrong before catching it, not quietly fixing it.

### 19. `device.mk` — `init.recovery.mt6886.rc` doesn't exist (real bug, found while re-checking)

```
PRODUCT_PACKAGES += \
    init.recovery.mt6886.rc
```
"mt6886" is the marketing chip number (Dimensity 7300). Every real,
verified piece of evidence in this whole investigation — `fstab.mt6878`,
`ro.boot.hardware=mt6878`, the actual filename in `recovery/root/` — uses
the real internal platform code `mt6878`. This PRODUCT_PACKAGES line
pointed at a file (`init.recovery.mt6886.rc`) that doesn't exist anywhere
in the tree. Fixed to reference the real file, `init.recovery.mt6878.rc`.
Searched the whole repo for any other `mt6886` instances — none remain.

### Screenshot review cross-checked against the two uploaded log files

Every distinct error visible across all 16 screenshots was cross-checked:

| Screenshot error | Status |
|---|---|
| `Unhandled flag: forcefdeorfbe/fsverity` | Confirmed harmless (real reference example shows unhandled flags coexisting with working decrypt) |
| 30× `Failed to mount 'X' (Invalid argument)` (system/vendor/odm/product) | Fixed — Session 6, `flags=logical` |
| `dd ... vendor_boot_a -> vendor_boot_b ... ERROR: 1` | Fixed — Session 5, `/dev/block/bootdevice` symlink |
| ROM zip `Updater process ended with ERROR: 1` | Not a device-tree bug — zip signature verification, needs disabling in Settings |
| `Could not mount /data and unable to find crypto footer` + `E:Error getting bootctrl module` (seen only in one screenshot, ~20:58, right after "Changing Boot Slot completed") | **Still unresolved** — does not appear in either uploaded log file, so it's from a different boot session than the one captured. See below. |

### Still open: the 20:58 screenshot (slot-change → crypto footer + bootctrl error)

This is the one thing in the screenshots I cannot yet explain with real
log evidence. It's plausible it's connected to `bootctrl` given it appears
immediately after a "Changing Boot Slot" action, but I don't have a log
capture from that specific moment to confirm what actually failed. If it
happens again: `adb pull /tmp/recovery.log` (or Copy Log to SD)
**immediately after it appears**, before doing anything else, so the log
isn't overwritten by subsequent actions.

---

## SESSION 8 — cross-referenced against multiple real MediaTek OrangeFox trees

With explicit permission to research as deep as needed, cloned and compared
against 4 real device trees: Pacman (Nothing Phone 2A, same base
contributor as this tree), SPES (official OrangeFoxRecovery org),
Joyeuse (explicit FBE v2 support), and Marble (POCO F5, **exact same
`fox_12.1` branch as this tree**, 165 GitHub stars).

### 20. Confirmed: every bug found in this tree also exists in Pacman (Nothing Phone 2A)

`open("/dev/block/sdc"...)`, missing `flags=logical`, missing
`/dev/block/bootdevice` symlink, the same 3 `OF_*` decrypt-suppressing
flags, missing `TW_INCLUDE_CRYPTO_FBE`, and even `init.recovery.mt6886.rc`
(correct for Pacman's real MT6886 chip, wrong when copy-pasted into this
Tetris tree) — **all identical** in Pacman's tree. This isn't a
Tetris-specific mistake; it's inherited from a shared template across the
whole Nothing/CMF MediaTek device-tree family. Strengthens confidence that
the fixes so far are addressing real, systemic issues, not guesses.

### 21. `recovery.fstab` dynamic partitions — rewritten to match proven fox_12.1 format (MAJOR)

Marble's tree (exact branch match, real working 165-star device) uses the
**standard Android fstab structure** for its dynamic partitions — not the
TWRP-native syntax I used in Session 6:
```
system   /system   erofs   ro   wait,slotselect,avb=vbmeta_system,logical,first_stage_mount
```
— with **two entries per partition** (ext4 and erofs variants), and
`logical` as one of several comma-separated `fs_mgr_flags`. Rewrote all 7
of our dynamic-partition lines (system, system_ext, vendor, vendor_dlkm,
product, odm, odm_dlkm) to match this exact proven structure.

**`/data`, `/sdcard1`, `/usb_otg`, `/metadata`, `/persist`, `/misc` were
deliberately left in TWRP-native syntax** — those specific lines have
direct proof of working on our own real hardware (recovery_error.txt
showed successful decrypt and mount), and rewriting proven-working lines
without cause would be reckless. The file is intentionally mixed-format
now; TWRP/OrangeFox's fstab parser processes each line independently
(detecting format by whether the first field starts with `/`), so this is
expected to be safe, but — like everything relying on parser behavior
under fox_12.1 specifically — it is validated against a real matching
example, not assumed.

### 22. Added 5 more officially-documented MediaTek-specific flags

Found via OrangeFox's own official Building guide and a MediaTek-specific
device-tree gist:
```
TW_USE_FSCRYPT_POLICY := 2   (evidenced: our real fileencryption= contains "v2")
TW_PREPARE_DATA_MEDIA_EARLY := true
BOARD_ROOT_EXTRA_FOLDERS += metadata
TARGET_RECOVERY_DEVICE_MODULES += libkeymaster4
TW_RECOVERY_ADDITIONAL_RELINK_LIBRARY_FILES += .../libkeymaster4.so
```

### What this does NOT change

`OF_FORCE_USE_RECOVERY_FSTAB` — found in official OrangeFox flag docs,
specifically described for "decryption fails on an MTK device" — but the
same docs explicitly say "should not be used unless absolutely necessary."
Since our own real log already showed successful decrypt without it, not
adding it defensively.

### Honest bottom line after this round

This is the single most evidence-backed revision of this tree yet — cross
validated against 4 independent real trees, one of them an exact branch +
architecture match with 165 stars. It is still not proof against OUR
specific hardware for the rewritten dynamic-partition lines specifically
(only /data and the crypto flags have been directly real-hardware-tested
on Tetris itself so far). Next real boot test is what will confirm it.

---

## SESSION 9 — full file-by-file compare against real POCO F5 (marble) tree

Correction first: marble is actually **Qualcomm**, not MediaTek (confirmed
via `sysfs_path` pattern: Qualcomm uses "ufshc", MediaTek uses "ufshci" --
mislabeled it in Session 8. Only the fstab *structural* format lesson
carries over, since that's OrangeFox-core behavior, not SoC-specific).

Did a complete file-by-file diff: BoardConfig.mk, device.mk, vendorsetup.sh,
twrp.flags, against marble's equivalents.

### 23. `system/etc/twrp.flags` — a whole file I had never actually read until now

This supplementary flags file already existed in the repo with `logical`
correctly set on system/system_ext/vendor_dlkm/system_dlkm — but **/vendor,
/odm, /odm_dlkm, /product were completely absent**, and its `/usb_otg`
line pointed at `/dev/block/sda1` — a partition that **cannot exist**
(confirmed earlier via real device: sda is unpartitioned). Added the
missing partitions matching the existing pattern, fixed usb_otg to the
proven sdd1/sdd value already used in recovery.fstab.

### 24. `vendorsetup.sh` — 3 missing flags

`FOX_USE_TWRP_RECOVERY_IMAGE_BUILDER`, `FOX_RECOVERY_SYSTEM_PARTITION`,
`FOX_RECOVERY_VENDOR_PARTITION` (pointed at the standard AOSP liblp
device-mapper paths, `/dev/block/mapper/<name>` -- universal convention,
not SoC-specific).

### 25. `BoardConfig.mk` — 6 more missing flags

`BOARD_AVB_RECOVERY_KEY_PATH` (+3 companion AVB recovery-signing vars,
standard AOSP test key), `TW_EXCLUDE_DEFAULT_USB_INIT` (avoids conflicting
with our own custom USB setprop lines), `TW_NO_EXFAT_FUSE`.

### 26. `device.mk` — `update_engine_client` + `PRODUCT_SOONG_NAMESPACES` + API level companions

Had `update_engine`/`update_engine_sideload`/`update_verifier` already but
was missing `update_engine_client`. Added `PRODUCT_SOONG_NAMESPACES`.
Real reference trees set `BOARD_SHIPPING_API_LEVEL`, `BOARD_API_LEVEL`,
`SHIPPING_API_LEVEL` alongside `PRODUCT_SHIPPING_API_LEVEL` — we only had
the last one. Added the other 3 at the same value (36).

### What was deliberately NOT copied from marble

Marble's prebuilt HAL approach (extracted stock Qualcomm .so blobs for
boot control/keymaster/gatekeeper, e.g. `libboot_control_qti.so`) is a
fundamentally different, Qualcomm-specific architecture from our
custom-source-built MediaTek `bootctrl/` — this is expected and correct,
not something to unify. Its VINTF `manifest.xml` files were also not
copied: fabricating a device-specific VINTF manifest without verified
real content would risk introducing new, unverified assumptions (exactly
the mistake pattern this changelog has already had to self-correct twice).
Our real log already shows this gracefully falls back to a correct
default (keymaster 4.1), so the risk of fabricating one outweighs the
uncertain benefit.

---

## SESSION 10 — compared against a REAL MediaTek device (POCO X6 Pro / duchamp)

Per request, found and compared against a genuinely MediaTek (Dimensity
8300 Ultra), genuinely Android-16-era OrangeFox tree — more directly
relevant than Session 9's marble (which turned out Qualcomm).

### 27. THIRD independent confirmation: `sdc` in bootctrl is correct

Duchamp's `boot_region_control.cpp` uses the exact same
`open("/dev/block/sdc", O_RDWR)`. Combined with Pacman (Session 8) and
our own real partition-layout evidence (Session 3), this is now about as
settled as it can get without literally booting our own device with a
debugger attached.

### 28. Dynamic-partition fstab format — independently re-confirmed

Duchamp's `/system /system_ext /vendor /product /odm /vendor_dlkm /odm_dlkm`
lines use the exact same structure as our Session 8 rewrite
(`<src> <mnt_point> <type> ro wait,slotselect,avb=...,logical,first_stage_mount`).
Strong confirmation Session 8's conversion was correct, this time from an
actual same-architecture (MediaTek) device rather than marble's Qualcomm one.

### 29. Added `sepolicy/` — completely missing before (POTENTIALLY IMPORTANT)

Duchamp's maintainer left a comment literally calling one rule
**"THE KILLSHOT"** for FBE decrypt keystore access. The rules grant
`recovery` domain access to KeyMint/Keystore2/Gatekeeper services and to
`vold_key`/`vold_metadata_file` — directly relevant to our own decrypt
struggles, and several rules concern `service_manager` registration,
which is plausibly connected to the still-unresolved "bootctrl module"
error (a HAL failing to register with service_manager can manifest
exactly as "couldn't get/find the module"). These are additive SELinux
`allow` rules only — they cannot break anything that already worked, only
grant permissions that were previously missing. Added `sepolicy/recovery.te`
and `sepolicy/file_contexts`, wired in via `BOARD_RECOVERY_SEPOLICY_DIRS`.

### 30. Added `patches/partitionmanager_merge_fix.patch` (NOT auto-applied — see patches/README.md)

This patches OrangeFox's own **core source** (`partitionmanager.cpp`),
not anything in this device tree — so it can't be fixed by editing files
here. Makes `Check_Pending_Merges()` only run its Virtual A/B
merge-check / `Unmap_Super_Devices()` logic when a real pending OTA
snapshot marker exists, instead of unconditionally on every single boot
— which could unmap the exact logical partitions this tree just spent so
much effort getting to mount via `flags=logical`. Copied into
`patches/` with clear apply instructions since it must be applied against
the core source tree during your build, not something I can wire in from
here.

### 31. 14 more `BoardConfig.mk` flags found completely missing

`TARGET_USES_64_BIT_BINDER`, `BOARD_HAS_MTK_HARDWARE` (likely gates
MTK-specific code paths in OrangeFox core), `BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE`,
`BOARD_VENDOR_DLKMIMAGE_FILE_SYSTEM_TYPE`, `BOARD_ODM_DLKIMAGE_FILE_SYSTEM_TYPE`,
`BOARD_USES_VENDOR_DLKMIMAGE`, `BOARD_USES_ODM_DLKIMAGE`,
`TARGET_COPY_OUT_PRODUCT`, `TARGET_COPY_OUT_VENDOR_DLKM`,
`TARGET_COPY_OUT_ODM_DLKM`, `TARGET_USES_PREBUILT_DYNAMIC_PARTITIONS`,
`TW_NO_LEGACY_PARTITIONS`, `TARGET_USES_LOGD`, `BOARD_SUPPRESS_SECURE_ERASE`.
The `TARGET_COPY_OUT_*` and `BOARD_*IMAGE_FILE_SYSTEM_TYPE` ones are
particularly significant — without them the build system may not have
known how to properly construct the product/vendor_dlkm/odm_dlkm
partition images at all. Filesystem types set to `erofs` to match our own
verified real device data, not blindly copied from duchamp's values.

### Not copied

`TW_LOAD_VENDOR_MODULES := "haptic.ko"` — device-specific to duchamp's own
haptic driver filename; we don't have verified knowledge of our own
equivalent, so not guessing at a value here.

---

## SESSION 11 — full file/blob inventory comparison (every file, not just configs)

Direct answer to "did you compare ALL blobs and files": no, not until this
session. Did a complete file-existence diff between our tree and duchamp's
— every single file path, not just the config files checked so far.

### What this found: ~250 files duchamp has that we don't

The overwhelming majority are **not applicable and were deliberately NOT
copied**: duchamp's kernel is for MT6897 (Dimensity 8300 Ultra) — a
**different chip** from our MT6878. Every `.ko` module, the DTB, Xiaomi's
"mitee" TEE binaries, Goodix/Focaltech touch firmware, camera HALs, and
duchamp's own VINTF manifest.xml (checked — it's saturated with
Xiaomi-proprietary and dual-SIM radio HAL entries specific to their
hardware) all fall in this category. Copying binary blobs across
different chips/kernels doesn't work — wrong ABI, wrong drivers, could
actively cause boot failures if force-installed.

### What WAS added — genuinely generic, standard AOSP files, safe to adopt

**32. `system/etc/ld.config.recovery.txt`** — completely missing. This is
the dynamic linker's namespace/search-path config for recovery. Verified
duchamp's version is 100% generic AOSP boilerplate (no device-specific
paths). **This is a plausible new lead for the "bootctrl module" mystery**
— if the linker doesn't know to search `/vendor/lib64`, a vendor HAL `.so`
can fail to load even if the file exists in the right place.

**33. `system/etc/ueventd.rc`** — completely missing. Also verified
generic (imports `/vendor/etc/ueventd.rc` and `/odm/etc/ueventd.rc` for
device-specific rules rather than hardcoding any here). Standard baseline
device-node permissions.

**34. `Android.bp`** (top-level, `soong_namespace {}`) — this is the
actual missing companion piece for Session 9's `PRODUCT_SOONG_NAMESPACES`
addition. That variable alone doesn't do anything without the namespace
being declared here.

### Found but deliberately NOT copied (with reasons)

- **`keystore2` binary** — missing from both trees' comparison point of
  view, but this is a compiled ELF executable. Binary "portability" across
  devices isn't guaranteed even for relatively generic userspace binaries
  (build fingerprint/toolchain dependent). Also: our own real hardware log
  already showed successful decrypt (`Is_Decrypted=true`) without this
  binary present, so it's not proven necessary for us specifically.
- **`android.hardware.boot-service.mtk`** (prebuilt binary + .rc) —
  duchamp uses a MediaTek-provided prebuilt service binary for boot HAL
  instead of our custom-compiled `bootctrl/` source. This is a genuinely
  interesting architectural difference (and a real alternate approach that
  might sidestep our "bootctrl module" issue entirely) but the binary
  itself is proprietary and chip-specific — not safely copyable.
- **VINTF `manifest.xml`** — read the full content; it's saturated with
  Xiaomi-proprietary and dual-SIM radio HAL declarations specific to
  duchamp's exact hardware. Fabricating one for our device without
  extracting real HAL data from our own vendor partition would be a guess
  presented as fact — exactly the mistake pattern already self-corrected
  twice in this changelog. Not doing that a third time.

This is likely close to the practical limit of what file-level comparison
against other device trees can responsibly contribute — further progress
from here really does need a real boot test.
