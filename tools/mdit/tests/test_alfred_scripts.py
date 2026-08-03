from pathlib import Path


def test_clipboard_workflow_notifies_and_copies_output():
    script = Path("scripts/alfred-clipboard.zsh").read_text(encoding="utf-8")

    assert "display notification" in script
    assert "mdit.py --clipboard" in script
    assert 'PROJECT_DIR="${HOME}/conf/tools/mdit"' in script
    assert 'PYTHON="${HOME}/.local/bin/python"' in script
    assert '"~/conf/tools/mdit"' not in script
    assert "pbcopy" in script
    assert "Converted Markdown copied" in script
    assert "Conversion failed" in script


def test_large_type_workflow_prints_status_instead_of_markdown():
    script = Path("scripts/alfred-clipboard-large-type.zsh").read_text(encoding="utf-8")

    assert "mdit.py --clipboard" in script
    assert 'PROJECT_DIR="${HOME}/conf/tools/mdit"' in script
    assert 'PYTHON="${HOME}/.local/bin/python"' in script
    assert '"~/conf/tools/mdit"' not in script
    assert "pbcopy" in script
    assert "echo \"Copied" in script
    assert "echo \"Failed" in script
