#!/Users/youbin/.local/bin/python
from __future__ import annotations

import argparse
import io
import os
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable
from urllib.parse import unquote, urlparse


HTML_TYPES = (
    "public.html",
    "text/html",
    "Apple HTML pasteboard type",
)
PLAIN_TEXT_TYPES = (
    "public.utf8-plain-text",
    "public.plain-text",
    "NSStringPboardType",
    "text/plain",
)
FILE_URL_TYPES = (
    "public.file-url",
    "NSFilenamesPboardType",
)
IMAGE_TYPES = (
    ("public.png", ".png"),
    ("public.jpeg", ".jpg"),
    ("public.tiff", ".tiff"),
)
DEFAULT_ENV_FILE = Path(".env")
DEFAULT_LLM_PROMPT = """Convert this image to Markdown.

If the image contains readable text, code, UI labels, tables, charts, or document content, extract that content faithfully instead of describing the screenshot.
Preserve code blocks with language fences when visible, preserve tables as Markdown tables, and keep the original language.
If some text is unclear, mark it as [unclear] rather than inventing it.
Only provide a short visual description when there is no meaningful readable content to extract."""


@dataclass(frozen=True)
class ClipboardPayload:
    html: str | None = None
    plain_text: str | None = None
    file_paths: tuple[Path, ...] = ()
    image_bytes: bytes | None = None
    image_suffix: str = ".png"


def escape_markdown_table_cell(value: str) -> str:
    return value.replace("\\", "\\\\").replace("|", "\\|").replace("\n", "<br>")


def render_tsv_as_markdown(text: str) -> str:
    rows = [line.split("\t") for line in text.strip().splitlines() if line.strip()]
    if not rows or len(rows[0]) < 2:
        return text

    width = max(len(row) for row in rows)
    padded = [row + [""] * (width - len(row)) for row in rows]

    def render_row(row: Iterable[str]) -> str:
        return "| " + " | ".join(escape_markdown_table_cell(cell.strip()) for cell in row) + " |"

    header = render_row(padded[0])
    separator = "| " + " | ".join("---" for _ in range(width)) + " |"
    body = [render_row(row) for row in padded[1:]]
    return "\n".join([header, separator, *body])


def looks_like_tsv(text: str) -> bool:
    lines = [line for line in text.strip().splitlines() if line.strip()]
    return bool(lines) and all("\t" in line for line in lines)


def normalize_markitdown_output(markdown: str) -> str:
    stripped = markdown.strip()
    prefix = "# Description:\n"
    if stripped.startswith(prefix):
        return stripped[len(prefix) :].strip()
    return markdown


def normalize_clipboard_image(image_bytes: bytes, suffix: str) -> tuple[bytes, str]:
    normalized_suffix = suffix.lower()
    if normalized_suffix in {".png", ".jpg", ".jpeg"}:
        return image_bytes, normalized_suffix

    try:
        from PIL import Image
    except ImportError as exc:
        raise RuntimeError("Install Pillow to convert clipboard TIFF images to PNG.") from exc

    with Image.open(io.BytesIO(image_bytes)) as image:
        output = io.BytesIO()
        image.convert("RGBA").save(output, format="PNG")
        return output.getvalue(), ".png"


def convert_file(
    source: str | Path,
    *,
    markitdown_cls: type[Any] | None = None,
    llm_client: Any | None = None,
    llm_model: str | None = None,
    llm_prompt: str = DEFAULT_LLM_PROMPT,
) -> str:
    path = Path(source).expanduser().resolve()
    if not path.exists():
        raise FileNotFoundError(path)

    if markitdown_cls is None:
        from markitdown import MarkItDown

        markitdown_cls = MarkItDown

    converter = markitdown_cls(llm_client=llm_client, llm_model=llm_model)
    return normalize_markitdown_output(converter.convert(path, llm_prompt=llm_prompt).text_content)


def convert_clipboard_payload(
    payload: ClipboardPayload,
    *,
    markitdown_cls: type[Any] | None = None,
    llm_client: Any | None = None,
    llm_model: str | None = None,
    llm_prompt: str = DEFAULT_LLM_PROMPT,
) -> str:
    if payload.file_paths:
        return "\n\n".join(
            convert_file(
                path,
                markitdown_cls=markitdown_cls,
                llm_client=llm_client,
                llm_model=llm_model,
                llm_prompt=llm_prompt,
            )
            for path in payload.file_paths
        )

    with tempfile.TemporaryDirectory(prefix="mdit-") as temp_dir:
        temp_path = Path(temp_dir)
        if payload.html:
            source = temp_path / "clipboard.html"
            source.write_text(payload.html, encoding="utf-8")
            return convert_file(
                source,
                markitdown_cls=markitdown_cls,
                llm_client=llm_client,
                llm_model=llm_model,
                llm_prompt=llm_prompt,
            )

        if payload.image_bytes:
            image_bytes, image_suffix = normalize_clipboard_image(
                payload.image_bytes,
                payload.image_suffix,
            )
            source = temp_path / f"clipboard{image_suffix}"
            source.write_bytes(image_bytes)
            return convert_file(
                source,
                markitdown_cls=markitdown_cls,
                llm_client=llm_client,
                llm_model=llm_model,
                llm_prompt=llm_prompt,
            )

    if payload.plain_text:
        if looks_like_tsv(payload.plain_text):
            return render_tsv_as_markdown(payload.plain_text)
        return payload.plain_text

    raise RuntimeError("Clipboard does not contain HTML, files, images, or text.")


def make_llm_client(model: str | None) -> Any | None:
    if not model:
        return None

    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        raise RuntimeError("OPENAI_API_KEY is required when --llm-model is set.")

    try:
        from openai import OpenAI
    except ImportError as exc:
        raise RuntimeError("Install openai to use --llm-model.") from exc

    kwargs: dict[str, str] = {"api_key": api_key}
    if base_url := os.environ.get("OPENAI_BASE_URL"):
        kwargs["base_url"] = base_url
    return OpenAI(**kwargs)


def load_dotenv(path: str | Path = DEFAULT_ENV_FILE) -> None:
    env_path = Path(path)
    if not env_path.exists():
        return

    for line in env_path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#") or "=" not in stripped:
            continue
        key, value = stripped.split("=", 1)
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        if key:
            os.environ[key] = value


def inspect_clipboard() -> str:
    pasteboard = _get_pasteboard()
    return "\n".join(str(t) for t in pasteboard.types())


def read_clipboard_payload() -> ClipboardPayload:
    pasteboard = _get_pasteboard()

    file_paths = _read_file_paths(pasteboard)
    if file_paths:
        return ClipboardPayload(file_paths=tuple(file_paths))

    html = _first_string_for_types(pasteboard, HTML_TYPES)
    plain_text = _first_string_for_types(pasteboard, PLAIN_TEXT_TYPES)

    for type_name, suffix in IMAGE_TYPES:
        data = pasteboard.dataForType_(type_name)
        if data is not None:
            return ClipboardPayload(
                html=html,
                plain_text=plain_text,
                image_bytes=bytes(data),
                image_suffix=suffix,
            )

    return ClipboardPayload(html=html, plain_text=plain_text)


def _get_pasteboard() -> Any:
    try:
        from AppKit import NSPasteboard
    except ImportError as exc:
        raise RuntimeError("Install pyobjc-framework-Cocoa to read the macOS clipboard.") from exc

    return NSPasteboard.generalPasteboard()


def _first_string_for_types(pasteboard: Any, type_names: Iterable[str]) -> str | None:
    for type_name in type_names:
        value = pasteboard.stringForType_(type_name)
        if value:
            return str(value)
    return None


def _read_file_paths(pasteboard: Any) -> list[Path]:
    paths: list[Path] = []
    for type_name in FILE_URL_TYPES:
        value = pasteboard.stringForType_(type_name)
        if not value:
            continue

        if value.startswith("file://"):
            parsed = urlparse(value)
            paths.append(Path(unquote(parsed.path)))
        else:
            paths.extend(Path(line) for line in str(value).splitlines() if line.strip())
    return paths


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="mdit",
        description="Convert clipboard content or files to Markdown with MarkItDown.",
    )
    parser.add_argument("paths", nargs="*", type=Path, help="Files to convert.")
    parser.add_argument("-c", "--clipboard", action="store_true", help="Read from macOS clipboard.")
    parser.add_argument("-o", "--output", type=Path, help="Write Markdown to this file.")
    parser.add_argument("--llm-model", help="Enable MarkItDown LLM image descriptions with this model.")
    parser.add_argument("--llm-prompt", help="Override the default image-to-Markdown LLM prompt.")
    parser.add_argument("--inspect-clipboard", action="store_true", help="Print clipboard data types and exit.")
    return parser


def run(argv: list[str] | None = None) -> int:
    load_dotenv()
    parser = build_parser()
    args = parser.parse_args(argv)

    if args.inspect_clipboard:
        print(inspect_clipboard())
        return 0

    if bool(args.paths) == bool(args.clipboard):
        parser.error("Provide either file paths or --clipboard.")

    try:
        llm_model = args.llm_model or os.environ.get("MDIT_LLM_MODEL") or os.environ.get("EVERY2MD_LLM_MODEL")
        llm_prompt = (
            args.llm_prompt
            or os.environ.get("MDIT_LLM_PROMPT")
            or os.environ.get("EVERY2MD_LLM_PROMPT")
            or DEFAULT_LLM_PROMPT
        )
        llm_client = make_llm_client(llm_model)
        if args.clipboard:
            markdown = convert_clipboard_payload(
                read_clipboard_payload(),
                llm_client=llm_client,
                llm_model=llm_model,
                llm_prompt=llm_prompt,
            )
        else:
            markdown = "\n\n".join(
                convert_file(path, llm_client=llm_client, llm_model=llm_model, llm_prompt=llm_prompt)
                for path in args.paths
            )
    except Exception as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2

    if args.output:
        args.output.write_text(markdown, encoding="utf-8")
    else:
        sys.stdout.write(markdown)
        if markdown and not markdown.endswith("\n"):
            sys.stdout.write("\n")
    return 0


def main() -> None:
    raise SystemExit(run())


if __name__ == "__main__":
    main()
