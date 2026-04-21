# training-kas

Practical tutorial repository for learning a Yocto workflow through `kas`.

This project is intentionally small: it provides `kas` configuration files and a `poky` checkout so you can build `core-image-minimal` for QEMU without manually setting up a BitBake build directory.

## Repository layout

- `kas/base.yml`: shared project configuration (`poky`, `kirkstone`, `core-image-minimal`)
- `kas/qemu.yml`: includes `base.yml`, sets `qemux86-64`, enables `debug-tweaks`, and sets parallel build values
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
- Parallelism is currently pinned to 8 threads in `kas/qemu.yml`.
- Build artifacts are written under `build/`.
