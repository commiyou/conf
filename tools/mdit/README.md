# mdit

Convert local files or macOS clipboard content to Markdown.

`mdit` is a personal Markdown ingestion tool built on
[microsoft/markitdown](https://github.com/microsoft/markitdown). It is stored
under `~/conf/tools/mdit` so it can be reused from shell, Alfred, and other
automation.

## Install

```bash
cd /Users/youbin/conf/tools/mdit
python3 -m pip install -e ".[dev]"
```

The PATH entry is a relative symlink:

```text
/Users/youbin/conf/bin/mdit -> ../tools/mdit/mdit.py
```

## CLI

Convert files:

```bash
mdit input.xlsx -o input.md
mdit page.html
mdit image.png -o image.md
```

Convert clipboard content:

```bash
mdit --clipboard
mdit --clipboard -o clip.md
mdit --inspect-clipboard
```

Clipboard handling priority:

1. copied files
2. HTML, including copied web pages and many copied spreadsheet ranges
3. images, including macOS TIFF clipboard images normalized to PNG
4. plain text, with TSV converted to a Markdown table

## Alfred

Large Type version:

1. Add a Hotkey trigger.
2. Connect it to a Run Script action.
3. Use `/bin/zsh` and this script:

   ```zsh
   /Users/youbin/conf/tools/mdit/scripts/alfred-clipboard-large-type.zsh
   ```

4. Connect the Run Script action to an Outputs > Large Type object.

The script copies Markdown to the clipboard internally. Its stdout is only a
short status message such as `Copied 482 chars` or `Failed: ...`, so Large Type
does not display the full Markdown.

Notification version:

```zsh
/Users/youbin/conf/tools/mdit/scripts/alfred-clipboard.zsh
```

## LLM Client

Local `.env` is loaded by the CLI and overrides same-named shell variables for
this tool. Keep `.env` ignored by git.

Supported settings:

```text
OPENAI_BASE_URL=...
OPENAI_API_KEY=...
MDIT_LLM_MODEL=...
MDIT_LLM_PROMPT=...
```

Image conversion defaults to extracting readable text, code blocks, tables, and
document content as Markdown. It only falls back to a visual description when
there is no meaningful readable content.

Legacy `EVERY2MD_LLM_MODEL` and `EVERY2MD_LLM_PROMPT` are still accepted as a
fallback, but new config should use `MDIT_*`.

## Verify

```bash
cd /Users/youbin/conf/tools/mdit
python -m pytest
python -m compileall mdit.py
mdit --inspect-clipboard
scripts/alfred-clipboard-large-type.zsh
```
