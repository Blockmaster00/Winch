"""Replace the version text in a PDF preview template and rasterize it to Preview.png."""

import argparse
import subprocess
import sys
from pathlib import Path

import pymupdf

DEFAULT_FONT_NAME = "JumboxBold"
DEFAULT_FONT_QUERY = "Jumbox:style=Bold"
DEFAULT_TARGET_WIDTH_PX = 750
DEFAULT_MAX_SIZE_BYTES = 1_048_576


def load_font_buffer(font_file: Path | None, version: str) -> bytes:
    auto_resolved = font_file is None
    if auto_resolved:
        try:
            match = subprocess.run(
                ["fc-match", "-f", "%{file}", DEFAULT_FONT_QUERY],
                check=True,
                capture_output=True,
                text=True,
            )
        except (OSError, subprocess.CalledProcessError) as exc:
            raise ValueError(
                "A complete Jumbox Bold font is required; install it or pass "
                "--font-file PATH"
            ) from exc
        font_path = Path(match.stdout.strip())
    else:
        font_path = font_file

    try:
        font_buffer = font_path.read_bytes()
    except OSError as exc:
        raise ValueError(
            f"Cannot read full font file '{font_path}'; pass a readable font "
            "file with --font-file"
        ) from exc

    font = pymupdf.Font(fontbuffer=font_buffer)
    if auto_resolved:
        if "jumbox" not in font.name.casefold():
            raise ValueError(
                f"Expected Jumbox Bold, but '{font_path}' contains '{font.name}'"
            )
    missing_characters = sorted(
        {character for character in version if not font.has_glyph(ord(character))}
    )
    if missing_characters:
        missing = ", ".join(repr(character) for character in missing_characters)
        raise ValueError(f"Font '{font_path}' has no glyph for: {missing}")
    return font_buffer


def fill_and_render(
    template_path: Path,
    version: str,
    output_path: Path,
    font_name: str,
    font_file: Path | None,
    target_width_px: int,
    max_size_bytes: int,
) -> None:
    doc = pymupdf.open(template_path)
    page = doc[0]

    # Find the target span by font name
    target_span = None
    for b in page.get_text("dict")["blocks"]:
        if b["type"] != 0:
            continue
        for l in b["lines"]:
            for s in l["spans"]:
                if s["font"] == font_name:
                    target_span = s
                    break
            if target_span:
                break
        if target_span:
            break

    if target_span is None:
        raise ValueError(f"No text span with font '{font_name}' found in {template_path}")

    font_buffer = load_font_buffer(font_file, version)

    # Redact the old text
    bbox = pymupdf.Rect(target_span["bbox"])
    page.add_redact_annot(bbox)
    page.apply_redactions(images=pymupdf.PDF_REDACT_IMAGE_NONE)

    # Insert new text at the same position with the same font/size/color
    origin = pymupdf.Point(target_span["origin"])
    color_int = target_span["color"]
    color = (
        ((color_int >> 16) & 0xFF) / 255,
        ((color_int >> 8) & 0xFF) / 255,
        (color_int & 0xFF) / 255,
    )

    replacement_font_name = "replacementfont"
    page.insert_font(fontname=replacement_font_name, fontbuffer=font_buffer)
    page.insert_text(
        origin,
        version,
        fontname=replacement_font_name,
        fontsize=target_span["size"],
        color=color,
    )

    # Render to PNG
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
        "--font",
        default=DEFAULT_FONT_NAME,
        help="Font name of the version text span to replace",
    )
    parser.add_argument(
        "--font-file",
        type=Path,
        help="Path to a complete font file (otherwise resolve Jumbox Bold with Fontconfig)",
    )
    parser.add_argument("--target-width-px", type=int, default=DEFAULT_TARGET_WIDTH_PX)
    parser.add_argument("--max-size-bytes", type=int, default=DEFAULT_MAX_SIZE_BYTES)
    args = parser.parse_args()

    if not args.template.exists():
        print(f"Template not found: {args.template}", file=sys.stderr)
        sys.exit(1)

    try:
        fill_and_render(
            args.template,
            args.version,
            args.output,
            args.font,
            args.font_file,
            args.target_width_px,
            args.max_size_bytes,
        )
    except ValueError as exc:
        parser.error(str(exc))


if __name__ == "__main__":
    main()   