"""Replace the version text in a PDF preview template and rasterize it to Preview.png."""

import argparse
import re
import subprocess
import sys
from pathlib import Path

import pymupdf

DEFAULT_FONT_NAME = "JumboxBold"
DEFAULT_FONT_QUERY = "Jumbox:style=Bold"
DEFAULT_TARGET_WIDTH_PX = 750
DEFAULT_MAX_SIZE_BYTES = 1_048_576


def load_font_buffer(
    doc: pymupdf.Document,
    font_name: str,
    version: str,
    font_file: Path | None,
) -> bytes:
    if font_file is not None:
        try:
            font_buffer = font_file.read_bytes()
        except OSError as exc:
            raise ValueError(f"Cannot read font file '{font_file}'") from exc
    else:
        font_xref = next(
            (
                font[0]
                for font in doc[0].get_fonts()
                if font[3].split("+")[-1].casefold() == font_name.casefold()
            ),
            None,
        )
        if font_xref is None:
            raise ValueError(
                f"No embedded font '{font_name}' found in {doc.name}; "
                "pass --font-file PATH to provide one"
            )
        _, _, _, font_buffer = doc.extract_font(font_xref)

    font = pymupdf.Font(fontbuffer=font_buffer)
    missing_characters = sorted(
        {character for character in version if not font.has_glyph(ord(character))}
    )
    if missing_characters and font_file is None:
        try:
            match = subprocess.run(
                ["fc-match", "-f", "%{file}", DEFAULT_FONT_QUERY],
                check=True,
                capture_output=True,
                text=True,
            )
            font_buffer = Path(match.stdout.strip()).read_bytes()
            font = pymupdf.Font(fontbuffer=font_buffer)
            missing_characters = sorted(
                {
                    character
                    for character in version
                    if not font.has_glyph(ord(character))
                }
            )
        except (OSError, subprocess.CalledProcessError) as exc:
            raise ValueError(
                "The PDF's embedded font lacks required glyphs; install Jumbox "
                "Bold or pass --font-file PATH"
            ) from exc
    if missing_characters:
        missing = ", ".join(repr(character) for character in missing_characters)
        raise ValueError(f"Font '{font.name}' has no glyph for: {missing}")
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

    # Find the numeric version span, not the glyph chart rendered in the same font.
    target_span = None
    target_line = None
    for b in page.get_text("dict")["blocks"]:
        if b["type"] != 0:
            continue
        for l in b["lines"]:
            for s in l["spans"]:
                if s["font"] == font_name and re.fullmatch(
                    r"\s*\d+\.\d+\.\d+\s*", s["text"]
                ):
                    target_span = s
                    target_line = l
                    break
            if target_span:
                break
        if target_span:
            break

    if target_span is None:
        raise ValueError(f"No text span with font '{font_name}' found in {template_path}")

    label_prefix = next(
        (
            span
            for span in target_line["spans"]
            if span["text"].strip() == "V"
            and span["bbox"][2] <= target_span["bbox"][0]
        ),
        None,
    )
    if label_prefix is None:
        raise ValueError(f"No version prefix found beside the version in {template_path}")

    font_buffer = load_font_buffer(doc, font_name, version, font_file)

    label_spans = [
        span
        for span in target_line["spans"]
        if label_prefix["bbox"][0] <= span["bbox"][0]
        and span["bbox"][2] <= target_span["bbox"][2]
    ]
    for span in label_spans:
        page.add_redact_annot(pymupdf.Rect(span["bbox"]), fill=None)
    page.apply_redactions(images=pymupdf.PDF_REDACT_IMAGE_NONE)

    # Jumbox is an all-caps display font, so use a separate font for lowercase v.
    origin = pymupdf.Point(label_prefix["origin"])
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
        "v",
        fontname="hebo",
        fontsize=target_span["size"],
        color=color,
    )
    number_origin = pymupdf.Point(
        origin.x + pymupdf.Font("hebo").text_length("v", target_span["size"]),
        target_span["origin"][1],
    )
    page.insert_text(
        number_origin,
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
        "--template",
        type=Path,
        default=Path(__file__).parent.parent / "preview_template.pdf",
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
        help="Path to a font file (otherwise use the font embedded in the PDF)",
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
