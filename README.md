# OrangeFox Recovery Device Tree — CMF Phone 1 (Tetris)

Device tree for building [OrangeFox Recovery](https://orangefox.download/) /
TWRP-based recovery for the Nothing **CMF Phone 1** (codename `Tetris`,
MediaTek Dimensity 7300 / `mt6878`).

## Credits

- [Heptex](https://github.com/Heptex/) — original recovery tree
- [HpDevFox](https://github.com/hpdevFOX) — compilation assistance
- [Sidharth](https://github.com/sidharthify) — base trees
- Kernel binary and kernel modules are provided by
  [Nothing Technology Limited](https://github.com/NothingOSS) under the
  GNU General Public License.

This tree has been audited and patched for storage detection, decryption,
and Android 16 vendor-interface alignment — see **[CHANGELOG.md](CHANGELOG.md)**
for the full technical history.

## Device specifications

| Basic   | Spec Sheet |
|--------:|:-----------|
| CPU     | 4× ARM Cortex-A78 @ 2.50 GHz • 4× ARM Cortex-A55 @ 2.00 GHz |
| Chipset | MediaTek Dimensity 7300 5G (`mt6878`) |
| GPU     | Mali-G615 MC2 |
| Memory  | 6 / 8 GB RAM |
| Shipped Android version | 14 (this tree targets Android 16 vendor interface) |
| Storage | 128 GB (UFS 2.2) |
| Battery | Li-Po 5000 mAh, non-removable |
| Display | 1080 × 2400, 6.7", 60/120 Hz |

## Before you start

- **This is a device tree, not a standalone buildable project.** It must be
  placed inside a full OrangeFox/AOSP-based source tree at
  `device/nothing/Tetris` (the exact path `BoardConfig.mk` expects via
  `DEVICE_PATH`), not built by itself.
- You need a Linux build host (Ubuntu 22.04/24.04 recommended) with the
  standard AOSP build dependencies, `repo` tool, and at least ~150 GB free
  disk space and 16 GB+ RAM. Full setup steps are covered in the
  [official OrangeFox building guide](https://wiki.orangefox.tech/en/dev/building)
  — that guide, not a mobile-app SDK, is the correct reference for setting
  up the build environment.

## Compile from source

**1. Sync the OrangeFox source tree** (branch `fox_12.1`), following the
[official building guide](https://wiki.orangefox.tech/en/dev/building) for
the `repo init` / `repo sync` commands and directory layout.

**2. Place this device tree at the correct path:**
```bash
cd <your-source-root>
git clone <this-repository-url> device/nothing/Tetris
```

**3. Set up the build environment and select this device:**
```bash
source build/envsetup.sh
lunch twrp_Tetris-eng
```

**4. Build:**
```bash
mka recoveryimage
```
The output image will be under `out/target/product/Tetris/`, named following
OrangeFox's own build convention (e.g. `OrangeFox-unofficial-Tetris.img`).

## Flashing

The recovery lives inside **`vendor_boot`**, not a separate `recovery`
partition, on this device.

> **Test-boot first, don't flash blind.** A prior build of this tree bricked
> devices when flashed directly — always verify the build actually works
> before committing to a flash.

1. Reboot to fastboot: power off, then hold **Volume Down + Power**.
2. Connect via USB; confirm `fastboot devices` sees your phone.
3. **Test boot (safe, does not modify your device):**
   ```bash
   fastboot boot vendor_boot.img
   ```
   Only proceed to step 4 once this boots correctly and Internal Storage is
   visible.
4. **Flash for real:**
   ```bash
   fastboot flash vendor_boot vendor_boot.img
   fastboot reboot
   ```

## Guides

- [Bootloader unlock guide](https://xdaforums.com/t/nothing-cmf-phone-1-bootloader-unlock-guide.4680441/)
- [Root guide](https://xdaforums.com/t/root-cmf-phone-1.4681502/)

## License

Kernel and kernel modules: GPLv2, courtesy of Nothing Technology Limited.
Device tree changes: same license as the upstream OrangeFox/TWRP project
this tree is built against.
