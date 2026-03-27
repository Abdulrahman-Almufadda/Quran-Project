"""Strip embedded JSON/metadata from SVG files and optionally combine files into per-page SVGs.

Usage examples (PowerShell):
  python tools\strip_svg_metadata.py "C:\path\to\yaqiin-svgs" "C:\out\cleaned"
  python tools\strip_svg_metadata.py "C:\path\to\yaqiin-svgs" "C:\out\pages" --group-regex "page[_-]?(\d{1,3})" --overwrite

The script removes <metadata>, <script type="application/json"> blocks, JSON-like comments, and data-* attributes.
When --group-regex is provided (with one capture group), files with the same capture are merged into one SVG per group.
"""
from __future__ import annotations

import argparse
import re
from pathlib import Path
from typing import Dict, List, Tuple

SVG_TAG_RE = re.compile(r"<svg\b[^>]*>(.*?)</svg>", re.S | re.I)
METADATA_RE = re.compile(r"<metadata\b.*?>.*?</metadata>", re.S | re.I)
SCRIPT_JSON_RE = re.compile(
    r"<script\b[^>]*type=[\"']application/json[\"'][^>]*>.*?</script>", re.S | re.I
)
JSON_COMMENT_RE = re.compile(r"<!--\s*[\{\[].*?[\}\]]\s*-->", re.S)
DATA_ATTR_RE = re.compile(r"\sdata-[\w-]+=(\"|\').*?\1", re.S)


def strip_json_from_svg_text(text: str) -> str:
    """Remove common embedded JSON-containing sections and data-* attributes."""
    text = METADATA_RE.sub("", text)
    text = SCRIPT_JSON_RE.sub("", text)
    text = JSON_COMMENT_RE.sub("", text)
    text = DATA_ATTR_RE.sub("", text)
    # Normalize excess blank lines/spaces left by removals
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip() + "\n"


def extract_svg_inner(text: str) -> Tuple[str, Dict[str, str]]:
    """Return (inner_svg, attrs) extracted from the first <svg>...</svg> in text.

    attrs includes commonly useful attributes like width,height,viewBox,xmlns.
    If no <svg> tag is found, returns (text, {}).
    """
    m = re.search(r"<svg\b([^>]*)>(.*?)</svg>", text, re.S | re.I)
    if not m:
        return text, {}
    attrs_raw = m.group(1)
    inner = m.group(2)
    attrs: Dict[str, str] = {}
    for k in ("width", "height", "viewBox", "xmlns"):
        am = re.search(rf"\b{k}\s*=\s*[\"']([^\"']+)[\"']", attrs_raw)
        if am:
            attrs[k] = am.group(1)
    return inner, attrs


def build_combined_svg(groups: Dict[str, List[Tuple[Path, str]]]) -> Dict[str, str]:
    """Combine grouped SVG fragments into one SVG per group key.

    Each fragment is wrapped in a <g> with data-source attribute to keep provenance.
    """
    outputs: Dict[str, str] = {}
    for key, files in groups.items():
        first_attrs: Dict[str, str] = {}
        if files:
            _, first_attrs = extract_svg_inner(files[0][1])

        viewBox = first_attrs.get("viewBox")
        width = first_attrs.get("width")
        height = first_attrs.get("height")
        xmlns = first_attrs.get("xmlns", "http://www.w3.org/2000/svg")

        wrap_attrs: List[str] = []
        if viewBox:
            wrap_attrs.append(f'viewBox="{viewBox}"')
        if width:
            wrap_attrs.append(f'width="{width}"')
        if height:
            wrap_attrs.append(f'height="{height}"')
        wrap_attrs.append(f'xmlns="{xmlns}"')

        parts: List[str] = []
        for idx, (path, content) in enumerate(files, start=1):
            inner, _ = extract_svg_inner(content)
            gid = f'fragment-{idx}'
            # keep filename provenance; safe-escape by using attribute
            parts.append(f'<g id="{gid}" data-source="{path.name}">\n{inner}\n</g>')

        combined = f'<svg {" ".join(wrap_attrs)}>\n' + "\n".join(parts) + "\n</svg>\n"
        outputs[key] = combined
    return outputs


def group_by_filename_number(path: Path, group_regex: re.Pattern | None = None) -> str:
    name = path.name
    if group_regex:
        m = group_regex.search(name)
        if m and m.groups():
            return m.group(1)
        if m:
            return m.group(0)
    m = re.search(r"(\d{1,3})", name)
    return m.group(1) if m else name


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Strip JSON metadata from SVGs and optionally combine into per-page SVGs."
    )
    parser.add_argument("input_dir", help="Directory with SVG files (recursively scanned).")
    parser.add_argument("output_dir", help="Directory to write cleaned SVGs (and combined pages if grouping).")
    parser.add_argument(
        "--group-regex",
        help="Regex with one capture group to extract page id from filename; if set, files with same capture are merged into one SVG.",
    )
    parser.add_argument(
        "--overwrite", action="store_true", help="Overwrite existing output files.")
    args = parser.parse_args()

    inp = Path(args.input_dir)
    out = Path(args.output_dir)
    out.mkdir(parents=True, exist_ok=True)

    group_re = re.compile(args.group_regex) if args.group_regex else None

    svg_files = list(inp.rglob("*.svg"))
    if not svg_files:
        print("No SVG files found in", inp)
        return

    groups: Dict[str, List[Tuple[Path, str]]] = {}
    for p in svg_files:
        try:
            text = p.read_text(encoding="utf-8")
        except Exception:
            # fallback to system default encoding
            text = p.read_text()
        cleaned = strip_json_from_svg_text(text)
        group_key = group_by_filename_number(p, group_re)
        groups.setdefault(group_key, []).append((p, cleaned))

    if group_re:
        combined = build_combined_svg(groups)
        for key, svg_text in combined.items():
            out_path = out / f'page-{key}.svg'
            if out_path.exists() and not args.overwrite:
                print("Skipping existing:", out_path)
                continue
            out_path.write_text(svg_text, encoding="utf-8")
            print("Wrote combined:", out_path)
    else:
        # write each cleaned svg individually preserving directory structure
        for key, items in groups.items():
            for path, cleaned in items:
                try:
                    rel = path.relative_to(inp)
                except Exception:
                    rel = Path(path.name)
                out_path = out / rel
                out_path.parent.mkdir(parents=True, exist_ok=True)
                if out_path.exists() and not args.overwrite:
                    print("Skipping existing:", out_path)
                    continue
                out_path.write_text(cleaned, encoding="utf-8")
                print("Wrote:", out_path)


if __name__ == "__main__":
    main()
