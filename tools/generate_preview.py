#!/usr/bin/env python3
"""Fill the version field of a PDF preview template and rasterize it to Preview.png."""

import argparse
import sys
from pathlib import Path

import pymupdf

DEFAULT_FIELD_NAME = "VersionField"
DEFAULT_TARGET_WIDTH_PX = 1024  # good default for Steam Workshop preview thumbnails
DEFAULT_MAX_SIZE_BYTES = 1_048_576  # Steam Workshop preview image limit


def fill_and_render(
    template_path: Path,
    version: str,
    output_path: Path,
    field_name: str,
    target_width_px: int,
    max_size_bytes: int,
) -> None:
    doc = pymupdf.open(template_path)
    page = doc[0]

    widget = next(
        (w for w in (page.widgets() or []) if w.field_name == field_name), None
    )
    if widget is None:
        raise ValueError(f"Form field '{field_name}' not found in {template_path}")
    widget.field_value = version
    widget.update()

    # PDF page width is in points (1/72 inch); pick the DPI that renders it at target_width_px
    page_width_inches = page.rect.width / 72
    dpi = round(target_width_px / page_width_inches)

    data = page.get_pixmap(dpi=dpi).tobytes("png")
    if len(data) > max_size_bytes:
        print(
            f"Warning: rendered preview is {len(data)} bytes, over the {max_size_bytes} byte limit",
            file=sys.stderr,
        )

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_bytes(data)
    print(f"Rendered at {dpi} DPI, {len(data)} bytes")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "version", help="Version string to write into the PDF, e.g. 1.0.2"
    )
    parser.add_argument(
        "--template", type=Path, default=Path(__file__).parent / "preview_template.pdf"
    )
    parser.add_argument(
        "--output", type=Path, default=Path(__file__).parent.parent / "Preview.png"
    )
    parser.add_argument(
        "--field",
        default=DEFAULT_FIELD_NAME,
        help="Name of the PDF form field holding the version text",
    )
    parser.add_argument("--target-width-px", type=int, default=DEFAULT_TARGET_WIDTH_PX)
    parser.add_argument("--max-size-bytes", type=int, default=DEFAULT_MAX_SIZE_BYTES)
    args = parser.parse_args()

    if not args.template.exists():
        print(f"Template not found: {args.template}", file=sys.stderr)
        sys.exit(1)

    fill_and_render(
        args.template,
        args.version,
        args.output,
        args.field,
        args.target_width_px,
        args.max_size_bytes,
    )


if __name__ == "__main__":
    main()
