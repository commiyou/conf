import os
from pathlib import Path

import pytest

from mdit import (
    ClipboardPayload,
    convert_clipboard_payload,
    convert_file,
    load_dotenv,
    make_llm_client,
    normalize_markitdown_output,
    render_tsv_as_markdown,
    run,
)


class FakeConversion:
    def __init__(self, text_content):
        self.text_content = text_content


class FakeMarkItDown:
    last_llm_client = None
    last_llm_model = None
    last_converted = None
    last_convert_kwargs = None
    last_converted_bytes = None

    def __init__(self, llm_client=None, llm_model=None):
        type(self).last_llm_client = llm_client
        type(self).last_llm_model = llm_model

    def convert(self, path, **kwargs):
        type(self).last_converted = Path(path)
        type(self).last_converted_bytes = Path(path).read_bytes()
        type(self).last_convert_kwargs = kwargs
        return FakeConversion(f"converted:{Path(path).name}")


class FailingMarkItDown:
    def __init__(self, llm_client=None, llm_model=None):
        pass

    def convert(self, path):
        raise ValueError("conversion exploded")


def test_render_tsv_as_markdown_converts_clipboard_table():
    tsv = "Name\tScore\nAlice\t10\nBob\t9"

    assert render_tsv_as_markdown(tsv) == (
        "| Name | Score |\n"
        "| --- | --- |\n"
        "| Alice | 10 |\n"
        "| Bob | 9 |"
    )


def test_normalize_markitdown_output_strips_description_wrapper():
    assert normalize_markitdown_output("\n# Description:\n```zsh\npwd\n```\n") == "```zsh\npwd\n```"


def test_convert_file_uses_markitdown_with_llm_client(tmp_path):
    source = tmp_path / "image.png"
    source.write_bytes(b"not really an image")
    client = object()

    result = convert_file(
        source,
        markitdown_cls=FakeMarkItDown,
        llm_client=client,
        llm_model="gpt-4o-mini",
    )

    assert result == "converted:image.png"
    assert FakeMarkItDown.last_converted == source
    assert FakeMarkItDown.last_llm_client is client
    assert FakeMarkItDown.last_llm_model == "gpt-4o-mini"
    assert "llm_prompt" in FakeMarkItDown.last_convert_kwargs


def test_convert_file_accepts_custom_llm_prompt(tmp_path):
    source = tmp_path / "image.png"
    source.write_bytes(b"not really an image")

    convert_file(source, markitdown_cls=FakeMarkItDown, llm_prompt="Extract text only.")

    assert FakeMarkItDown.last_convert_kwargs["llm_prompt"] == "Extract text only."


def test_convert_clipboard_payload_prefers_html_over_plain_text():
    payload = ClipboardPayload(
        html="<table><tr><th>A</th></tr><tr><td>1</td></tr></table>",
        plain_text="A\n1",
    )

    result = convert_clipboard_payload(payload, markitdown_cls=FakeMarkItDown)

    assert result == "converted:clipboard.html"
    assert FakeMarkItDown.last_converted.name == "clipboard.html"


def test_convert_clipboard_payload_uses_tsv_plain_text_without_markitdown():
    payload = ClipboardPayload(plain_text="A\tB\n1\t2")

    assert convert_clipboard_payload(payload, markitdown_cls=FakeMarkItDown) == (
        "| A | B |\n"
        "| --- | --- |\n"
        "| 1 | 2 |"
    )


def test_convert_clipboard_payload_converts_tiff_images_to_png():
    payload = ClipboardPayload(
        image_bytes=(
            b"II*\x00\x08\x00\x00\x00\x08\x00\x00\x01\x03\x00\x01\x00\x00\x00\x01\x00\x00\x00"
            b"\x01\x01\x03\x00\x01\x00\x00\x00\x01\x00\x00\x00\x02\x01\x03\x00\x03\x00\x00\x00"
            b"n\x00\x00\x00\x03\x01\x03\x00\x01\x00\x00\x00\x01\x00\x00\x00\x06\x01\x03\x00"
            b"\x01\x00\x00\x00\x02\x00\x00\x00\x11\x01\x04\x00\x01\x00\x00\x00t\x00\x00\x00"
            b"\x15\x01\x03\x00\x01\x00\x00\x00\x03\x00\x00\x00\x17\x01\x04\x00\x01\x00\x00\x00"
            b"\x03\x00\x00\x00\x00\x00\x00\x00\x08\x00\x08\x00\x08\x00\xff\xff\xff"
        ),
        image_suffix=".tiff",
    )

    result = convert_clipboard_payload(payload, markitdown_cls=FakeMarkItDown)

    assert result == "converted:clipboard.png"
    assert FakeMarkItDown.last_converted.name == "clipboard.png"
    assert FakeMarkItDown.last_converted_bytes.startswith(b"\x89PNG\r\n\x1a\n")


def test_make_llm_client_requires_api_key(monkeypatch):
    monkeypatch.delenv("OPENAI_API_KEY", raising=False)

    with pytest.raises(RuntimeError, match="OPENAI_API_KEY"):
        make_llm_client("gpt-4o-mini")


def test_load_dotenv_overrides_existing_values_with_project_config(tmp_path, monkeypatch):
    env_file = tmp_path / ".env"
    env_file.write_text(
        "OPENAI_BASE_URL=https://oneapi-comate.baidu-int.com/v1\n"
        "MDIT_LLM_MODEL=gpt-5.4\n"
        "EXISTING=from-file\n",
        encoding="utf-8",
    )
    monkeypatch.delenv("OPENAI_BASE_URL", raising=False)
    monkeypatch.delenv("MDIT_LLM_MODEL", raising=False)
    monkeypatch.setenv("EXISTING", "from-env")

    load_dotenv(env_file)

    assert os.environ["OPENAI_BASE_URL"] == "https://oneapi-comate.baidu-int.com/v1"
    assert os.environ["MDIT_LLM_MODEL"] == "gpt-5.4"
    assert os.environ["EXISTING"] == "from-file"


def test_run_reports_llm_configuration_errors_without_traceback(tmp_path, monkeypatch, capsys):
    monkeypatch.chdir(tmp_path)
    monkeypatch.delenv("OPENAI_API_KEY", raising=False)

    exit_code = run(["--llm-model", "gpt-4o-mini", "missing.png"])

    captured = capsys.readouterr()
    assert exit_code == 2
    assert "OPENAI_API_KEY is required" in captured.err
    assert "Traceback" not in captured.err


def test_run_uses_dotenv_default_model(tmp_path, monkeypatch):
    source = tmp_path / "input.html"
    source.write_text("<h1>Hello</h1>", encoding="utf-8")
    (tmp_path / ".env").write_text(
        "OPENAI_BASE_URL=https://oneapi-comate.baidu-int.com/v1\n"
        "MDIT_LLM_MODEL=gpt-5.4\n",
        encoding="utf-8",
    )
    seen = {}

    monkeypatch.chdir(tmp_path)
    monkeypatch.setenv("OPENAI_API_KEY", "test-key")
    monkeypatch.delenv("OPENAI_BASE_URL", raising=False)
    monkeypatch.delenv("MDIT_LLM_MODEL", raising=False)
    monkeypatch.setattr("mdit.make_llm_client", lambda model: seen.setdefault("model", model))
    monkeypatch.setattr(
        "mdit.convert_file",
        lambda path, **kwargs: seen.setdefault("llm_model", kwargs["llm_model"]) or "converted",
    )

    exit_code = run([str(source)])

    assert exit_code == 0
    assert seen["model"] == "gpt-5.4"
    assert seen["llm_model"] == "gpt-5.4"


def test_convert_file_surfaces_markitdown_errors_to_cli(tmp_path, capsys, monkeypatch):
    source = tmp_path / "bad.png"
    source.write_bytes(b"bad")

    monkeypatch.setattr("mdit.make_llm_client", lambda model: None)
    monkeypatch.setattr("mdit.convert_file", lambda *args, **kwargs: FailingMarkItDown().convert(args[0]))

    exit_code = run([str(source)])

    captured = capsys.readouterr()
    assert exit_code == 2
    assert "conversion exploded" in captured.err
    assert "Traceback" not in captured.err
