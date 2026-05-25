#!/usr/bin/env python3
"""Generate placeholder PNG assets for the 2X2Coin wallet build."""
from pathlib import Path
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]
IMAGES_DIR = ROOT / "assets" / "images"
DRAWABLE_DIR = ROOT / "android" / "res" / "drawable"


def png_chunk(tag: bytes, data: bytes) -> bytes:
    crc = zlib.crc32(tag + data) & 0xFFFFFFFF
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", crc)


def write_png(path: Path, width: int, height: int, rgba_fn):
    rows = []
    for y in range(height):
        row = bytearray([0])
        for x in range(width):
            row.extend(rgba_fn(x, y))
        rows.append(bytes(row))
    raw = b"".join(rows)
    compressed = zlib.compress(raw, 9)

    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    png = b"\x89PNG\r\n\x1a\n"
    png += png_chunk(b"IHDR", ihdr)
    png += png_chunk(b"IDAT", compressed)
    png += png_chunk(b"IEND", b"")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(png)


def logo_rgba(x, y):
    cx, cy = 64, 64
    dx, dy = x - cx, y - cy
    dist = (dx * dx + dy * dy) ** 0.5
    if dist < 52:
        t = max(0.0, 1.0 - dist / 52.0)
        return bytes([0, int(212 * t), int(170 * t), 255])
    return bytes([15, 15, 26, 255])


def splash_rgba(x, y):
    return bytes([15, 15, 26, 255])


def launcher_rgba(x, y):
    return logo_rgba(x, y)


def main():
    write_png(IMAGES_DIR / "logo_2x2coin.png", 128, 128, logo_rgba)
    write_png(IMAGES_DIR / "splash_bg.png", 390, 844, splash_rgba)
    write_png(DRAWABLE_DIR / "ic_launcher.png", 192, 192, launcher_rgba)
    print("Generated:", IMAGES_DIR / "logo_2x2coin.png")
    print("Generated:", IMAGES_DIR / "splash_bg.png")
    print("Generated:", DRAWABLE_DIR / "ic_launcher.png")


if __name__ == "__main__":
    main()
