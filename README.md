# training-kas

Practical tutorial repository for learning a Yocto workflow through `kas`.

This project is intentionally small: it provides `kas` configuration files so
you can build `core-image-minimal` for QEMU or Jetson AGX Orin without manually
setting up a BitBake build directory.

## Repository layout

- `kas/base.yml`: shared project configuration (`poky`, `scarthgap`, `core-image-minimal`)
- `kas/qemu.yml`: includes `base.yml`, sets `qemux86-64`, enables `debug-tweaks`, and sets parallel build values
- `kas/tegra.yml`: includes `base.yml`, adds `meta-tegra`, and sets `jetson-agx-orin-devkit`
- `poky/`: Yocto Project source tree used by the `kas` configs
- `build/`: generated build output directory

## Prerequisites

Install `kas` (for example with `pip`):

```bash
python3 -m pip install --user kas
```

Depending on your Linux distribution, you may also need Yocto host dependencies (compiler toolchain, Python modules, etc.).

## Recommended workflow

Inspect the resolved configuration:

```bash
kas dump kas/qemu.yml
```

Build the image:

```bash
kas build kas/qemu.yml
```

Build the Jetson AGX Orin image:

```bash
kas build kas/tegra.yml
```

Open a shell in the configured build environment:

```bash
kas shell kas/qemu.yml
```

Run the image in QEMU:

```bash
kas shell kas/qemu.yml -c "runqemu qemux86-64 nographic"
```

## Notes

- The `target` is `core-image-minimal` (defined in `kas/base.yml`).
- The machine is `jetson-agx-orin-devkit` (defined in `kas/tegra.yml`).
- The `poky` and `meta-tegra` repos are pinned to the current `scarthgap`
  heads.
- Parallelism is currently pinned to 8 threads in `kas/qemu.yml` and `kas/tegra.yml`.
- Build artifacts are written under `build/`.
