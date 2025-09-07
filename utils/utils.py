#!/usr/bin/env python3
"""python3 utils"""

import ast
import atexit
import base64
import collections
import contextlib
import dataclasses
import datetime
import functools
import hashlib
import inspect
import io
import itertools
import json
import locale
import os
import random
import re
import signal
import string
import sys
import threading
import time
import traceback
import unicodedata
from collections.abc import (
    Generator,
    Hashable,
    Iterable,
    Iterator,
    Mapping,
    Sequence,
)
from collections.abc import Set as AbstractSet
from contextlib import ExitStack, contextmanager, nullcontext
from functools import partial, wraps
from io import TextIOWrapper
from operator import itemgetter
from pathlib import Path
from typing import (
    IO,
    Any,
    BinaryIO,
    Callable,
    Literal,
    NewType,
    ParamSpec,
    Self,
    TextIO,
    TypeAlias,
    TypeVar,
    TypeVarTuple,
    cast,
    overload,
)
from urllib.parse import urlencode

import fire
import funcy
import pandas as pd
import requests
import rich.progress
import rich.traceback
import tqdm as tqdm_
from diskcache import Cache
from termcolor import colored

rich.traceback.install(show_locals=True, suppress=[fire], width=None)

requests.packages.urllib3.disable_warnings()  # pyright: ignore[reportAttributeAccessIssue]


Color = Literal["grey", "red", "green", "yellow", "blue", "magenta", "cyan", "white"]

Attribute = Literal["bold", "dark", "underline", "blink", "reverse", "concealed", "strike"]

Highlight = Literal[
    "on_black",
    "on_grey",
    "on_red",
    "on_green",
    "on_yellow",
    "on_blue",
    "on_magenta",
    "on_cyan",
    "on_light_grey",
    "on_dark_grey",
    "on_light_red",
    "on_light_green",
    "on_light_yellow",
    "on_light_blue",
    "on_light_magenta",
    "on_light_cyan",
    "on_white",
]

# Generic type variables for keys, values, and input items.
_K = TypeVar("_K")  # Represents the key type.
_V = TypeVar("_V")  # Represents the value type.
_T = TypeVar("_T")  # Represents the type of items read from the input file (e.g., list[str]).
_AccumulatedV = TypeVar("_AccumulatedV")  # Represents the type of the accumulated value.

T = TypeVar("T")
OptionalStr = TypeVar("OptionalStr", str, None)

T_Input = TypeVar("T_Input")
T_Output = TypeVar("T_Output")

R = TypeVar("R")
Ts = TypeVarTuple("Ts")
P = ParamSpec("P")
KeyType: TypeAlias = int | slice | Sequence | Mapping | AbstractSet | Callable[[_T], Any] | None


devnull = open(os.devnull, "w")  # noqa: SIM115


if locale.getencoding() != "UTF-8":
    print(f"system default locale {locale.getlocale()}", file=sys.stderr)
    # The open function in Python 3, if the encoding parameter is not specified,
    # defaults to the encoding of the system locale. It’s not utf8 on the Hadoop cluster.
    locale.setlocale(locale.LC_ALL, "en_US.utf-8")
    print(f"system locale changed to {locale.getlocale()}", file=sys.stderr)

try:
    sys.stdin = io.TextIOWrapper(sys.stdin.buffer, encoding="utf-8")
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")
except:  # noqa: S110
    pass

CH_PUNCTIONS = (
    "•·°！？｡。＂＃＄％＆＇（）＊＋，－／：；＜＝＞＠［＼］＾＿｀｛｜｝～｟｠｢｣"
    "､、〃》「」『』【】〔〕〖〗〘〙〚〛〜〝〞〟〰〾〿–—‘’‛“”„‟…‧﹏."
)


def make_str(value: Any) -> str:
    r"""Set/Map/Sequence to json str

    >>> make_str({1, 2, 3})
    '[1, 2, 3]'
    >>> make_str((1, 2, 3))
    '[1, 2, 3]'
    >>> make_str("你好")
    '你好'
    """
    if isinstance(value, bytes):
        return value.decode()
    if isinstance(value, str):
        return value
    if isinstance(value, AbstractSet):
        value = dump_json(sorted(value))
    elif isinstance(value, (Sequence, Mapping)):
        value = dump_json(value)
    return str(value)


def xprint(
    *values: Any,
    suffix: str = "",
    sep: str = "\t",
    flush: bool = True,
    file: IO[Any] | BinaryIO | None = None,
    encoding: str = "utf8",
    output_flag: bool = True,
    color: Color | None = None,
    newline_replacement: str | None = " ",
    tab_replacement: str | None = " ",
    strip_whitespace: bool = True,
) -> None:
    r"""print with default sep and suffix and encoding

    >>> import tempfile
    >>> with tempfile.NamedTemporaryFile("w+", delete=False) as tmp_file:
    ...     with redirect_stdout_to_file(tmp_file.name):
    ...         xprint(1, 2, 3)
    ...     tmp_file.read().strip()
    '1\t2\t3'
    """
    if not output_flag:
        return
    if file is None:
        file = sys.stdout
    end = suffix + "\n"
    if newline_replacement is not None:
        values = tuple(x.replace("\n", newline_replacement) if isinstance(x, str) else x for x in values)
    if tab_replacement is not None:
        values = tuple(x.replace("\t", tab_replacement) if isinstance(x, str) else x for x in values)

    if strip_whitespace:
        values = tuple(x.strip() if isinstance(x, str) else x for x in values)

    values_str = [make_str(value) for value in values]
    out = sep.join(values_str) + end
    out = color_text_if_atty(out, color)
    if isinstance(file, TextIOWrapper):
        file.buffer.write(out.encode(encoding))
    else:
        file.write(out)
    assert file is not None

    if flush:
        file.flush()


def xerr(
    *values: object,
    suffix: str = "",
    sep: str = "\t",
    encoding: str = "utf8",
    debug: bool = True,
    output_flag: bool = True,
    color: Color | None = None,
    file: "IO|None" = sys.stderr,
) -> None:
    """print to stderr with default sep and suffix and encoding"""
    if not debug:
        return
    if not output_flag:
        return
    xprint(
        *values,
        suffix=suffix,
        sep=sep,
        file=file,  # type:ignore
        color=color,
        encoding="unicode_escape" if is_mr() else encoding,
    )


def in_debug() -> bool:
    """是否处于debug"""
    v = os.environ.get("DEBUG")
    return not (v is None or v == "0")


def get_caller_name(level: int = 1) -> str:
    """获取callaer name, level 为0时代表自身"""
    caller_frame = sys._getframe(level + 1)  # noqa: SLF001
    function_name = caller_frame.f_code.co_name
    return function_name


def _is_literal(s: Any) -> bool:
    """是否是字面值"""
    try:
        ast.literal_eval(s)
    except Exception:
        return False
    return True


def color_text_if_atty(
    text: str,
    color: Color | None,
    on_color: Highlight | None = None,
    attrs: Iterable[Attribute] | None = None,
    force: bool = False,
) -> str:
    """颜色 text

    Available text colors:
        black, red, green, yellow, blue, magenta, cyan, white,
        light_grey, dark_grey, light_red, light_green, light_yellow, light_blue,
        light_magenta, light_cyan.

    Available text highlights:
        on_black, on_red, on_green, on_yellow, on_blue, on_magenta, on_cyan, on_white,
        on_light_grey, on_dark_grey, on_light_red, on_light_green, on_light_yellow,
        on_light_blue, on_light_magenta, on_light_cyan.

    Available attributes:
        bold, dark, underline, blink, reverse, concealed.
    """
    if color and (force or sys.stdout.isatty()):
        return colored(text, color, on_color, attrs)
    return text


def xvar(
    *values: Any,
    suffix: str = "",
    sep: str = "\t",
    encoding: str = "utf8",
    color: Color | None = None,
    force_debug: bool = False,
) -> None:
    """Output var and var's name in debug mode.

    参考 https://github.com/gruns/icecream/blob/master/icecream/icecream.py#L88
    """
    if not force_debug and not in_debug():
        return
    import executing

    caller_frame = sys._getframe(1)  # noqa: SLF001
    function_name = caller_frame.f_code.co_name
    prefix = f"DEBUG: {function_name}"

    prefix = color_text_if_atty(prefix, "green")

    # Use executing to get the node information
    executor = executing.Source.executing(caller_frame)
    if executor.node is not None:
        # Decompose the expressions
        value_names = []
        for value in executor.node.args:
            # Try to get the source of the argument
            try:
                source = executor.source.asttokens().get_text(value)
                value_names.append(source)
            except Exception:
                value_names.append("<unknown>")

        # Combine names with values
        value_info = []
        for name, val in zip(value_names, values, strict=False):
            import pprint

            val_str = pprint.pformat(val, width=119)
            if _is_literal(name):
                # For literal types, just append the value
                value_info.append(val_str)
            else:
                # For non-literal types, append the name, value, and type
                value_info.append(f"{color_text_if_atty(name, 'red', attrs=['bold'])}:{type(val).__name__}={val_str}")

        output = f"{prefix}: " + sep.join(value_info)
    else:
        # Fallback if we can't get the node
        output = f"{prefix}: " + sep.join(map(str, values))

    xerr(
        output,
        suffix=suffix,
        sep=sep,
        color=color,
        encoding="unicode_escape" if is_mr() else encoding,
    )


def xdebug(
    *values: Any,
    suffix: str = "",
    sep: str = "\t",
    encoding: str = "utf8",
    color: Color | None = None,
    force_debug: bool = False,
    file: "IO|None" = sys.stderr,
) -> None:
    """处于debug模式时，输出"""
    if not force_debug and not in_debug():
        return
    caller_frame = sys._getframe(1)  # noqa: SLF001
    function_name = caller_frame.f_code.co_name
    prefix = f"DEBUG: {function_name}"
    if not file or (file.isatty() and not color):
        prefix = colored(prefix, "green")

    xerr(
        prefix,
        *values,
        suffix=suffix,
        sep=sep,
        color=color,
        encoding="unicode_escape" if is_mr() else encoding,
        file=file,
    )


__dd_xcount: dict[Any, int] = collections.defaultdict(int)


def xcount(key: str, *args: P.args, **kwargs: P.kwargs) -> None:
    """debug key的出现次数"""
    __dd_xcount[key] += 1
    xdebug(f"{key}:count:{__dd_xcount[key]}", *args, **kwargs)


__dd_xonce = set()


def xonce(key: str, *args: P.args, **kwargs: P.kwargs) -> None:
    """对每个key只debug一次"""
    if key not in __dd_xonce:
        __dd_xonce.add(key)
        xdebug(key, *args, **kwargs)


def is_chinese_char(uchar: str) -> bool:
    """char is chinese or alpha/number

    >>> is_chinese_char("你")
    True
    >>> is_chinese_char("1")
    False
    >>> is_chinese_char("。")
    False
    """
    if uchar.encode().isalnum():
        return False
    if uchar >= "\u4e00" and uchar <= "\u9fa5":  # noqa: SIM103
        return True
    return False


def contain_chinese(s: str) -> bool:
    """是否包含中文字符，标点符号不算"""
    return any(is_chinese_char(ch) for ch in s)


def is_chinese_or_alnum(uchar: str) -> bool:
    """char is chinese or alpha/number

    >>> is_chinese_or_alnum("你")
    True
    >>> is_chinese_or_alnum("1")
    True
    >>> is_chinese_or_alnum("。")
    False
    """
    if uchar.encode().isalnum():
        return True
    if uchar >= "\u4e00" and uchar <= "\u9fa5":  # noqa: SIM103
        return True
    return False


def norm_line(line: type[T]) -> T:
    r"""使用正则表达式替换多个空白符为单个空格, 去前后空白符

    >>> norm_line("1  2\n")
    '1 2'
    """
    if isinstance(line, str):
        return re.sub(r"\s+", " ", line).strip()
    return line


trim_term = norm_line
trim_line = norm_line


def nterm(
    term: OptionalStr,
    *,
    lower: bool = True,
    trim_whitespace: bool = False,
    remove_whitespace: bool = True,
    remove_punctions: bool = True,
    remove_accounts: bool = True,
    strict: bool = False,
    stop_chars: set[str] | None = None,
) -> OptionalStr:
    """新版本norm_term， 默认小写、去空白符、去标点

    >>> nterm("手电筒‘ 0")
    '手电筒0'
    >>> nterm("手电筒‘ 0", stop_chars={"0"})
    '手电筒'
    """
    if term is None:
        return None

    if remove_accounts:
        term = strip_accents(term)
    if lower:
        ret = term.lower()
    if trim_whitespace:
        ret = norm_line(ret)
    elif remove_whitespace:
        ret = "".join(ret.split())

    if remove_punctions:
        ret = ret.translate(str.maketrans("", "", string.punctuation + CH_PUNCTIONS))

    if strict:
        ret = "".join(filter(is_chinese_or_alnum, ret))  # type:ignore

    if stop_chars:
        ret = "".join(ch for ch in ret if ch not in stop_chars)
    return ret


def norm_term(
    term: str,
    *,
    strict: bool = True,
    stop_chars: set[str] | None = None,
) -> str:
    """Convert the term to lowercase and remove whitespace characters

    strict: just keep chinese/alnum chars(no punctions/emojis)
    stop_chars : stop chars to remove

    >>> norm_term("手电筒‘ 0")
    '手电筒0'
    >>> norm_term("手电筒‘ 0", stop_chars={"0"})
    '手电筒'
    """

    ret = term.lower()
    ret = "".join(ret.split())

    if strict:
        ret = "".join(filter(is_chinese_or_alnum, ret))  # type:ignore

    if stop_chars:
        ret = "".join(ch for ch in ret if ch not in stop_chars)
    return ret


def split_str(s: str, sep: str = "\t", maxsplit: int = -1) -> list[str]:
    """split Unicode string and return list"""
    return funcy.lmap(str.strip, s.split(sep, maxsplit))


def is_large_file(file_path: str | Path, size_limit: int = 1024 * 1024 * 400) -> bool:
    """默认大小限制为300MB"""
    file_size = os.path.getsize(file_path)
    return file_size > size_limit


def remove_invalid_char(s: str) -> str:
    """去除非法字符"""
    if not isinstance(s, str):
        return s

    # 一个特殊的Unicode字符，表示零宽不连字符（Zero Width Non-Joiner，ZWNJ）
    s = s.replace(chr(160), " ")
    s = s.replace("‌", "")
    s = s.replace("\u200b", "")
    s = s.replace("\u2069", "")
    s = s.replace("\u2060", "")
    return s


def is_valid_value(value: Any) -> bool:
    """是否是有效值"""
    return bool(value is not None and not pd.isna(value))


def _read_csv(
    text_iterator: Iterator[str],
    sep: str,
    quotechar: str,
) -> Generator[list[str], None, None]:
    """Helper to read CSV-formatted lines using csv.reader."""
    import csv

    reader = csv.reader(text_iterator, delimiter=sep, quotechar=quotechar)
    yield from reader


def _read_text_lines(
    text_iterator: Iterator[str],
    sep: str,
    maxsplit: int,
) -> Generator[list[str], None, None]:
    """Helper to read and split plain text lines."""
    for line in text_iterator:
        ll = split_str(line, sep=sep, maxsplit=maxsplit)
        yield ll


def _decode_with_tolerance(
    binary_iterator: Iterator[bytes],
    encoding: str,
    errors: str,
    tolerance_count: int,
) -> Generator[str, None, None]:
    """一个生成器，它包装一个二进制迭代器，并提供解码容错计数功能。"""
    # 负数表示无限容忍
    remaining_tolerance = tolerance_count

    for i, binary_line in enumerate(binary_iterator):
        try:
            yield binary_line.decode(encoding, errors)
        except UnicodeDecodeError:
            # sys.stderr.write(...) 比 print 更适合输出错误日志
            sys.stderr.write(f"Warning: UnicodeDecodeError on line {i + 1}. Raw content: {binary_line[:120]!r}\n")
            if remaining_tolerance >= 0:
                remaining_tolerance -= 1
                if remaining_tolerance < 0:
                    sys.stderr.write("Error: Decode error tolerance exceeded. Raising exception.\n")
                    raise
            # 如果 remaining_tolerance 是负数（无限容忍），则不进行任何操作
            continue


def _open_excel_iterator(
    path: str | Path,
) -> Generator[list[str], None, None]:
    """[new] Single responsibility: parses an Excel file into a list[str] iterator."""
    import pandas as pd

    df = pd.read_excel(path, dtype=str, header=None)
    for row in df.itertuples(index=False):
        yield ["" if pd.isna(cell) else str(cell) for cell in row]


def _open_text_iterator(
    input_stream: IO,
    *,
    encoding: str,
    errors: str,
    decode_error_tolerance_count: int,
    sep: str,
    maxsplit: int,
    quotechar: str | None,
) -> Generator[list[str], None, None]:
    """[new] Single responsibility: decodes a text stream and splits it into a list[str] iterator based on rules (text/csv)."""
    if isinstance(input_stream, io.TextIOBase):
        text_iterator: Iterator[str] = input_stream
    else:
        text_iterator = _decode_with_tolerance(
            input_stream,
            encoding,
            errors,
            decode_error_tolerance_count,
        )

    if quotechar:
        yield from _read_csv(text_iterator, sep, quotechar)
    else:
        yield from _read_text_lines(text_iterator, sep, maxsplit)


def read_file(
    input_: str | Path | IO[bytes] | IO[str] | None = None,
    *,
    # --- Text parsing parameters (passed to _open_text_iterator) ---
    sep: str = "\t",
    encoding: str = "utf-8",
    maxsplit: int = -1,
    errors: str = "strict",
    decode_error_tolerance_count: int = 10,
    quotechar: str | None = None,
    # --- Unified processing parameters ---
    skip_header: bool = False,
    filter_func: Callable[[Sequence[str]], bool] | None = None,
    norm: bool = True,
    # --- Progress bar and filesystem parameters ---
    total: int | None = None,
    tqdm_desc_func: KeyType = None,
    skip_notexists: bool = False,
) -> Generator[list[str], None, None]:
    r"""智能文件读取器，作为统一的逻辑处理器，支持多种文件格式、自动计算总行数并显示动态进度条。

    Args:
        input_ (str | Path | IO | None): 输入源。可以是文件路径 (str/Path)，
            一个已打开的IO流对象 (例如 sys.stdin.buffer)，或者 None (将自动从 sys.stdin.buffer 读取)。
            支持文本文件、CSV文件和Excel文件 (.xls, .xlsx)。
        sep (str): 文本文件的列分隔符。默认为 '\t'。
        encoding (str): 文本文件的解码格式。默认为 'utf-8'。
        maxsplit (int): 每行最大拆分次数。默认为 -1 (无限制)。
        errors (str): 解码错误的处理方式 (例如 'strict', 'ignore')。默认为 'strict'。
        decode_error_tolerance_count (int): 在因解码错误而失败前，允许的解码错误行数。默认为 10。
        quotechar (str | None): CSV文件的引用字符。如果提供此参数，将启用CSV解析模式。默认为 None。
        skip_header (bool): 是否跳过输入的第一行。默认为 False。
        filter_func (Callable | None): 一个函数，用于过滤行。该函数接收一个行(list[str])作为参数，
            返回 True 则保留该行，返回 False 则跳过。默认为 None。
        norm (bool): 是否对每行中的字符串元素进行标准化（例如，移除无效字符）。默认为 True。
        total (int | None): 手动指定总行数以初始化进度条。如果为 None，对于本地的小文件会自动计算。
        tqdm_desc_func (KeyType | None): 一个函数或列索引，用于为进度条生成动态描述。
        skip_notexists (bool): 如果为 True 且输入是文件路径但文件不存在，则静默返回，不抛出错误。默认为 False。

    Yields:
        Generator[list[str], None, None]: 一个生成器，每次产出一行处理后的数据，格式为字符串列表。
    """

    # --- 1. Initialization and pre-flight checks ---
    desc_generator = make_key_func(tqdm_desc_func) if tqdm_desc_func else None
    calculated_total = total

    # -- Handle `skip_notexists` --
    if isinstance(input_, (str, Path)) and skip_notexists and not os.path.exists(input_):
        xerr(f"File not found: {input_}. Skipping.")
        return

    # -- Calculate `total` for the progress bar --
    if calculated_total is None and isinstance(input_, (str, Path)):  # noqa: SIM102
        if not str(input_).endswith((".xlsx", ".xls")) and not is_large_file(input_):
            with open(input_, encoding=encoding, errors="ignore") as f:
                calculated_total = sum(1 for _ in f)

    pbar = tqdm_.tqdm(total=calculated_total, desc="Initializing...")

    # --- 2. Get the raw row iterator ---
    row_iterator: Generator[list[str], None, None]
    input_stream: IO | None = None
    stream_opened_by_func = False

    try:
        if input_ is None:
            input_stream = sys.stdin.buffer
            input_stream = cast("IO", input_stream)
            row_iterator = _open_text_iterator(
                input_stream,
                encoding=encoding,
                errors=errors,
                decode_error_tolerance_count=decode_error_tolerance_count,
                sep=sep,
                maxsplit=maxsplit,
                quotechar=quotechar,
            )
        elif isinstance(input_, (str, Path)):
            if str(input_).endswith((".xlsx", ".xls")):
                row_iterator = _open_excel_iterator(input_)
            else:
                input_stream = open(input_, "rb")  # noqa: SIM115
                stream_opened_by_func = True
                row_iterator = _open_text_iterator(
                    input_stream,
                    encoding=encoding,
                    errors=errors,
                    decode_error_tolerance_count=decode_error_tolerance_count,
                    sep=sep,
                    maxsplit=maxsplit,
                    quotechar=quotechar,
                )
        elif hasattr(input_, "read"):
            # Handle cases where input_ is already an open stream (binary or text)
            input_stream = input_
            row_iterator = _open_text_iterator(
                input_stream,  # type: ignore
                encoding=encoding,
                errors=errors,
                decode_error_tolerance_count=decode_error_tolerance_count,
                sep=sep,
                maxsplit=maxsplit,
                quotechar=quotechar,
            )
        else:
            msg = f"Unsupported input type: {type(input_)}"
            raise TypeError(msg)

        # --- 3. Unified processing loop ---
        if skip_header:
            next(row_iterator, None)
            if pbar.total is not None and pbar.total > 0:
                pbar.total -= 1
                pbar.refresh()

        for row_list in row_iterator:
            processed_row = row_list

            if norm:
                processed_row = [
                    remove_invalid_char(cell) if isinstance(cell, str) else cell for cell in processed_row
                ]

            if filter_func and not filter_func(processed_row):
                continue

            if desc_generator:
                desc_text = str(desc_generator(processed_row))
                desc_preview = (desc_text[:47] + "...") if len(desc_text) > 50 else desc_text
                pbar.set_description(f"Processing: {desc_preview}")

            pbar.update(1)
            yield processed_row

    finally:
        # --- 4. Cleanup ---
        # Only close the stream if this function opened it
        if stream_opened_by_func and input_stream:
            input_stream.close()
        pbar.close()


class AutoClosingFile:
    """自动关闭文件的包装类"""

    def __init__(self, filepath: str, mode: str = "w+", **kwargs):
        """init"""
        self.file = open(filepath, mode, **kwargs)
        self.fname = filepath

        atexit.register(self.close)  # 注册到程序退出时自动关闭

    def __getattr__(self, name: str):
        """将所有未定义的方法委托给内部的文件对象"""
        return getattr(self.file, name)

    def close(self):
        """close file"""
        if not self.file.closed:
            self.file.close()
            xdebug(f"File '{self.file.name}' closed automatically.")


def write_file_new(filepath: str, mode: str = "w+", suffix: str = "", **kwargs: Any) -> IO[Any]:
    """返回自动关闭的文件对象"""
    if suffix:
        filepath = new_filename(filepath, suffix=suffix)
    ret = AutoClosingFile(filepath, mode, **kwargs)
    return cast("IO[Any]", ret)


# --- Overloaded Function Signatures ---


# 情况 1: value=None -> 返回 set
@overload
def read_kv(
    input_: str | Path | IO | None = ...,
    key: KeyType = ...,
    value: None = ...,
    filter: Callable[[list], bool] | None = ...,
    value_accumulate_func: None = ...,
    *args: object,
    **kwargs: object,
) -> set[KeyType]: ...


# 情况 2: value指定 -> 返回 dict
@overload
def read_kv(
    input_: str | Path | IO | None = ...,
    key: KeyType = ...,
    value: KeyType = ...,
    filter: Callable[[list], bool] | None = ...,
    value_accumulate_func: Callable | None = ...,
    *args: object,
    **kwargs: object,
) -> dict: ...


def read_kv(
    input_: str | Path | IO | None = sys.stdin.buffer,
    key: KeyType = 0,
    value: KeyType | None = None,
    filter: Callable | None = None,
    key_map_func: Callable | None = None,
    value_accumulate_func: Callable | None = funcy.first,
    *args: P.args,
    **kwargs: P.kwargs,
) -> set | dict:
    """read key value from file"""
    key_func = make_key_func(key)
    if value is None:
        value_func = None
        result = set()
        value_accumulate_func = None
    else:
        value_func = make_key_func(value)
        result = collections.defaultdict(list)
    max_try_cnt = 5
    # value_accumulate_func = make_key_func(value_accumulate)
    for i, ll in enumerate(read_file(input_, *args, **kwargs)):
        # xerr(i, *ll)
        if filter and not filter(ll):
            continue
        try:
            k = key_func(ll)
        except Exception:
            xerr(f"key or value failed! #{i}:", *ll)
            max_try_cnt -= 1
            if max_try_cnt < 0:
                raise
            continue
        if key_map_func:
            k = key_map_func(k)
        if value_func:
            try:
                v = value_func(ll)
            except Exception:
                xerr(f"key or value failed! #{i}:", *ll)
                max_try_cnt -= 1
                if max_try_cnt < 0:
                    raise
                continue

            result[k].append(v)
        else:
            result.add(k)

    if value_accumulate_func:
        return funcy.walk_values(value_accumulate_func, result)
    return result


def read_and_filter_by_key(
    fname: str,
    key: KeyType = 0,
    with_key: bool = True,
    ofname: str | None = None,
    ofname_suffix: str | None = None,
    ofname_key: KeyType | None = None,
    mode: str = "a+",
) -> tuple[list[list[Any]], IO]:
    """read file and filter by key, return list of remain items"""
    if not ofname and ofname_suffix:
        ofname = new_filename(fname, suffix=ofname_suffix)

    if ofname_key is None:
        ofname_key = key
    already_done = read_kv(ofname, key=ofname_key, skip_notexists=True) if ofname else set()

    xerr(f"{ofname} has done keys cnt {len(already_done)}")
    todos = []

    key_func = make_key_func(key)
    for ll in read_file(fname):
        real_key = key_func(ll)
        if real_key in already_done:
            continue
        if with_key:
            if isinstance(real_key, tuple):
                todos.append([*real_key, *ll])
            else:
                todos.append([real_key, *ll])
        else:
            todos.append(ll)

    of = write_file_new(ofname, mode=mode) if ofname else sys.stdout
    return todos, of


def load_unprocessed_items(
    fname: str,
    key: KeyType = 0,
    ofname: str | None = None,
    ofname_suffix: str | None = None,
    ofname_key: KeyType | None = None,
    mode: str = "a+",
    **kwargs: Any,
) -> tuple[list[list[str]], IO[Any]]:
    """read file and filter by key, return list of remain items"""
    if not ofname and ofname_suffix:
        ofname = new_filename(fname, suffix=ofname_suffix)

    if ofname_key is None:
        ofname_key = key
    already_done = read_kv(ofname, key=ofname_key, skip_notexists=True) if ofname else set()

    xerr(f"{ofname} has done keys cnt {len(already_done)}")
    todos = []

    key_func = make_key_func(key)
    for ll in read_file(fname, **kwargs):
        real_key = key_func(ll)
        if real_key in already_done:
            continue
        todos.append(ll)

    xerr(f"{fname} left todos: {len(todos)}")
    of = write_file_new(ofname, mode=mode) if ofname else sys.stdout
    return todos, of


def make_key_func(
    f: KeyType,
) -> Callable:
    """turn into key func

    >>> ll = list(range(10))
    >>> make_key_func(slice(2))(ll)
    (0, 1)
    >>> make_key_func(slice(1))(ll)
    (0,)
    >>> make_key_func(1)(ll)
    1
    >>> make_key_func([1, 0, 4])(ll)
    (1, 0, 4)
    >>> make_key_func(1)({1: 2, 3: 4})
    2
    >>> make_key_func({1, 2})(1)
    True
    >>> make_key_func(lambda x: x[1])(ll)
    1
    """
    if f is None:
        return lambda x: x
    if callable(f):
        return f
    if isinstance(f, int):
        return itemgetter(f)
    if isinstance(f, str):
        # 尝试 dict/list 索引，否则尝试 getattr
        def func(x):
            if isinstance(x, Mapping) and f in x:
                return x[f]
            return getattr(x, f)

        return func
    if isinstance(f, slice):
        return lambda x: tuple(itemgetter(f)(x))
    if isinstance(f, Sequence):
        return lambda x: tuple(x[i] for i in f)
    if isinstance(f, Mapping):
        return f.__getitem__
    if isinstance(f, AbstractSet):
        return f.__contains__
    msg = f"Can't make a func from {f.__class__.__name__}"
    raise TypeError(msg)


def group_file_by_key(
    input_: str | Path | IO | None = sys.stdin.buffer,
    *,
    key: KeyType = 0,
    sep: str = "\t",
    encoding: str = "utf-8",
    maxsplit: int = -1,
    decode_error_tolerance_count: int = 10,
    **kwargs: Any,
) -> Generator:
    """read file line by line and split by sep and group by key, return like itertools.groupby"""
    key_func = make_key_func(key)
    f = read_file(
        input_,
        sep=sep,
        encoding=encoding,
        maxsplit=maxsplit,
        decode_error_tolerance_count=decode_error_tolerance_count,
        **kwargs,
    )

    yield from itertools.groupby(f, key=key_func)


def list_to_dict(
    lls: list,
    key: KeyType = 0,
    value: KeyType = 1,
    value_accumulate: KeyType = 0,
    filter: Callable | None = None,  # noqa: A002
    skip_header: bool = False,
    decode_error_tolerance_count: int = 3,
):
    """Convert a list to a dictionary with specified key and value.

    The value will be selected from the list, and the final value will be processed using value_accumulate,
    which defaults to taking the first value.

    key: get key from ll
    value: get value from ll
    filter: filter(ll)
    """
    key_func = make_key_func(key)
    value_func = make_key_func(value)
    value_accumulate_func = make_key_func(value_accumulate)
    result = collections.defaultdict(list)
    for i, ll in enumerate(lls):
        if filter and not filter(ll):
            continue
        try:
            k = key_func(ll)
            v = value_func(ll)
        except Exception:
            xerr(f"key or value failed! #{i}:", *ll)
            decode_error_tolerance_count -= 1
            if decode_error_tolerance_count < 0:
                raise
            continue
        result[k].append(v)

    return funcy.walk_values(value_accumulate_func, result)


class JsonCustomEncoder(json.JSONEncoder):
    """支持set、datacalss"""

    def default(self, o: object) -> object:
        """encode set/dataclass"""
        if isinstance(o, set):
            return list(o)
        if isinstance(o, Exception):
            return str(o)
        if dataclasses.is_dataclass(o):
            return dataclasses.asdict(o)
        if hasattr(o, "model_dump") and callable(o.model_dump):
            with contextlib.suppress(Exception):
                return o.model_dump()
        return json.JSONEncoder.default(self, o)


def dump_json(obj: object, indent: int | None = None) -> str:
    """dump json into str, 支持set、dataclass"""
    return json.dumps(obj, ensure_ascii=False, indent=indent, cls=JsonCustomEncoder)


def xprint_json(obj: object, indent: int = 4) -> None:
    """格式化json"""
    xprint(json.dumps(obj, ensure_ascii=False, indent=indent, cls=JsonCustomEncoder))


def safe_divide(p1: float, p2: float, *, digits: int = 2, percentage: bool = False) -> str:
    """return n/a if divide 0 else value with str type

    >>> safe_divide(1, 0)
    'nan'
    >>> safe_divide(10, 3)
    '3.33'
    >>> safe_divide(1, 3, percentage=True)
    '33.33%'
    """
    if p2 == 0:
        return "nan"
    if percentage:
        return f"{{:.{digits}%}}".format(p1 / p2)
    return f"{{:.{digits}f}}".format(p1 / p2)


def safe_diff(p1: float | str, p2: float | str, *, digits: int = 2, percentage: bool = True) -> str | float:
    """return n/a if divide 0 else value with str type

    >>> safe_diff(1, 0)
    nan
    >>> safe_diff(3, 10)
    '-70.00%'
    """
    p1 = to_number(p1)
    p2 = to_number(p2)
    if p2 == 0:
        return float("nan")
    if percentage:
        return f"{{:.{digits}%}}".format(p1 / p2 - 1)
    return f"{{:.{digits}f}}".format(p1 / p2 - 1)


def to_number(s: str | float) -> float:
    """str to float/int"""
    if isinstance(s, (float, int)):
        return s

    s = s.strip()
    if s.endswith("%"):
        s = float(s[:-1]) / 100
        return s
    s = int(s) if s.isnumeric() else float(s)
    return s


def is_mr() -> str | None:
    """Determine whether the script is running on a Hadoop cluster based on environment variables.

    return: mapper/reducer/None
    """
    is_mapper = mr_mif(None)
    is_reducer = os.environ.get("mapred_task_partition", None)
    if is_mapper:
        return "mapper"
    if is_reducer:
        return "reducer"
    return None


def mr_mif(default: str | None = "") -> str | None:
    """mr job get `map_input_file` of mapper"""
    return os.getenv("map_input_file", default)


def get_set_bits(recall_src: str | int) -> set[int]:
    """Get the position of the bits set to 1 in an integer

    >>> get_set_bits(0x1)
    {0}
    >>> get_set_bits(0x10)
    {4}
    """
    return {i for i, v in enumerate(list(bin(int(recall_src))[::-1])) if v == "1"}


@contextmanager
def redirect_stdout_to_file(
    fname: str | None = None, mode: str = "w+", **kwargs: object
) -> Generator[IO[Any], None, None]:
    """
    Redirect `sys.stdout` to a file or revert to original stdout.

    Args:
        fname (str | Path | None): The name or path of the file to redirect stdout to.
                                   If `None`, stdout is not redirected.
        mode (str): The mode in which the file is opened. Default is "w+".

    Yields:
        IO[Any]: The file object being written to, or `sys.stdout` if `fname` is `None`.

    Example:
        >>> import tempfile
        >>> with tempfile.NamedTemporaryFile("w+", delete=True) as tmp_file:
        ...     with redirect_stdout_to_file(tmp_file.name) as f:
        ...         print(123)
        ...     tmp_file.read().strip()
        '123'
    """
    if fname is None:
        with nullcontext(sys.stdout) as f:
            yield f
    else:
        ofname = new_filename(fname, **kwargs) if kwargs else fname

        with open(ofname, mode) as f, contextlib.redirect_stdout(f):
            yield f


@contextmanager
def redirect_stderr_to_file(
    fname: str | None = None, mode: str = "w+", **kwargs: object
) -> Generator[IO[Any], None, None]:
    """redirect_stderr_to_file

    >>> import tempfile
    >>> with tempfile.NamedTemporaryFile("w+", delete=True) as tmp_file:
    ...     with redirect_stderr_to_file(tmp_file.name) as f:
    ...         print(123, file=sys.stderr)
    ...     tmp_file.read().strip()
    '123'
    """
    if fname is None:
        with nullcontext(sys.stderr) as f:
            yield f
    else:
        ofname = new_filename(fname, **kwargs) if kwargs else fname
        with open(ofname, mode) as f, contextlib.redirect_stderr(f):
            yield f


@contextmanager
def redirect_stdout_stderr_to_file(
    fname: str | None = None, mode: str = "w+", **kwargs: object
) -> Generator[IO[Any], None, None]:
    r"""redirect_stderr_to_file

    >>> import tempfile
    >>> with tempfile.NamedTemporaryFile("w+", delete=True) as tmp_file:
    ...     with redirect_stdout_stderr_to_file(tmp_file.name) as f:
    ...         print(123)
    ...         print(456, file=sys.stderr)
    ...     tmp_file.read().strip()
    '123\n456'
    """
    if fname is None:
        with nullcontext(sys.stderr) as f:
            yield f
    else:
        ofname = new_filename(fname, **kwargs) if kwargs else fname
        with open(ofname, mode) as f:  # noqa: SIM117
            with contextlib.redirect_stderr(f), contextlib.redirect_stdout(f):
                yield f


def sample(
    fname: str | None = None,
    n: int = 100,
    *,
    pv_idx: int | None = None,
    skip_header: bool = False,
    max_pv: int | None = None,
    max_pv_replace: int | None = None,
) -> None:
    """weighted sample with replacement

    max_pv_replace: 将max_pv替换为max_pv_replace, 默认丢弃
    """

    data: list[list[str]] = []
    population: list[int] = []
    weights: list[int] = []
    bad_pv_cnt = 0
    for ll in read_file(fname, skip_header=skip_header):
        if pv_idx is not None and len(ll) > 1:
            try:
                pv = int(ll[pv_idx])
            except ValueError:
                bad_pv_cnt += 1
                continue
            if max_pv and pv > max_pv:
                if max_pv_replace is None:
                    continue
                pv = max_pv_replace
        else:
            pv = 1
        population.append(len(data))
        data.append(ll)
        weights.append(pv)
    if bad_pv_cnt > 0:
        xerr(f"skip bad line for pv, cnt: {bad_pv_cnt}")

    for line_no in random.choices(population=population, weights=weights, k=n) if n < len(data) else range(len(data)):
        xprint(*data[line_no])


def timestamp(fmt: str = "%Y%m%d%H%M%S") -> str:
    """return current local timestamp"""

    now = datetime.datetime.now(tz=datetime.UTC).astimezone()
    ts = now.strftime(fmt)
    return ts


def date(
    ts: str | int | None = None,
    fmt: str = "%Y-%m-%d",
    tz: datetime.timezone | None = None,
) -> str:
    """return current local datetime from ts with default timezone"""

    if tz is None:
        tz = datetime.datetime.now().astimezone().tzinfo

    ts_int = time.time() if ts is None or ts == 0 else int(ts)
    dt_object = datetime.datetime.fromtimestamp(ts_int, tz)
    formatted_time = dt_object.strftime(fmt)

    return formatted_time


def stop_function() -> None:
    """kill process"""
    os.kill(os.getpid(), signal.SIGINT)


def stopit_after_timeout(
    seconds: float, raise_exception: bool = True
) -> Callable[[Callable[P, R]], Callable[P, R | str]]:
    """decorator 超时停止函数"""

    def actual_decorator(func: Callable[P, R]) -> Callable[P, R | str]:
        @functools.wraps(func)
        def wrapper(*args: P.args, **kwargs: P.kwargs) -> R | str:
            timer = threading.Timer(seconds, stop_function)
            try:
                timer.start()
                result = func(*args, **kwargs)
            except KeyboardInterrupt:
                msg = f"function {func.__name__} took longer than {seconds} s."
                if raise_exception:
                    raise TimeoutError(msg)  # noqa: B904
                result = msg
            finally:
                timer.cancel()
            return result

        return wrapper

    return actual_decorator


def parallel_process_items_processes(
    inputs: Iterable,
    proc_func: Callable[..., T],
    *,
    process_cnt: int | None = None,
    tqdm: str | bool = True,
    total: int | None = None,
    timeout: float | None = None,
    max_fail_cnt: int = 1,
) -> Generator[T, None, None]:
    """Returns an iterator over the outputs of proc_func."""
    xerr(f"pcnt {process_cnt}")
    if process_cnt == 1:
        yield from iter(proc_func(ll) for ll in tqdm_.tqdm(inputs))
        return

    if not total and isinstance(inputs, (list, tuple, set, dict)):
        total = len(inputs)

    import multiprocessing
    from multiprocessing import Pool

    # INFO:  fork will hung for lock
    # https://pythonspeed.com/articles/python-multiprocessing/
    # multiprocessing.set_start_method("spawn")

    # with Pool(processes=process_cnt) as pool:
    #     yield from tqdm_.tqdm(
    #         pool.imap(proc_func, inputs),
    #         total=total,
    #         desc=tqdm if isinstance(tqdm, str) else None,
    #     )

    # 参见 https://stackoverflow.com/questions/69927597/python-multiprocessing-imap-discard-timeout-processes
    # https://towardsdatascience.com/exception-handling-in-methods-of-the-multiprocessing-pool-class-in-python-7fbb73746c26
    # imap的  if chunksize is 1 then the next(), 只是超时了抛出一个异常，但是原进程仍然进行

    # if timeout:
    #     proc_func = stopit_after_timeout(timeout)(proc_func)

    with (
        Pool(processes=process_cnt) as pool,
        tqdm_.tqdm(
            total=total,
            desc=tqdm if isinstance(tqdm, str) else None,
        ) as pbar,
    ):
        it = iter(pool.imap(proc_func, inputs))
        fail_cnt = 0
        while True:
            try:
                ret = next(it)
                yield ret
            except StopIteration:
                break
            except Exception as e:
                fail_cnt += 1
                if fail_cnt >= max_fail_cnt:
                    traceback.print_exception(None, e, e.__traceback__, file=sys.stderr)
                    raise
            pbar.update(1)


def get_positional_param_count(func: Callable):
    """获取函数的签名中位置参数的个数

    >>> def example_func(a, b, c=2, *args, **kwargs):
    ...     pass
    >>> get_positional_param_count(example_func)
    3
    """
    sig = inspect.signature(func)
    # 遍历签名中的参数
    positional_count = sum(
        1
        for param in sig.parameters.values()
        if param.kind in {inspect.Parameter.POSITIONAL_ONLY, inspect.Parameter.POSITIONAL_OR_KEYWORD}
    )
    return positional_count


def parallel_process_items_processes_new(
    inputs: Iterable[tuple[*Ts]],
    proc_func: Callable[[*Ts], T],
    *,
    process_cnt: int | None = None,
    slice_cnt: int | None = None,
    tqdm: str | bool = True,
    total: int | None = None,
    timeout: int | None = None,
    max_fail_cnt: int = 20,
    func_arg_cnt: int | None = None,
) -> Generator[tuple[tuple[*Ts], T], None, None]:
    """
    并行处理输入项并返回结果的迭代器。

    参数：
    - inputs: 可迭代的输入项。
    - proc_func: 处理每个输入项的函数。
    - process_cnt: 并行进程数。默认为 CPU 核心数。
    - tqdm: 是否显示进度条。可以是布尔值或描述字符串。
    - total: 输入项的总数。如果未提供，且输入是序列类型，则自动计算。
    - max_fail_cnt: 允许的最大失败次数。超过后将抛出异常。
    - timeout: 每个任务的超时时间（秒）。如果任务超时，将忽略该任务并计入失败次数。

    返回：
    - 结果的迭代器。

    参考 https://github.com/alexwlchan/concurrently
    concurrent学习 https://rednafi.com/python/concurrent_futures/

    多进程共享variable，参考multiprocessing.Manager

    """
    if process_cnt is None:
        process_cnt = os.cpu_count() or 1

    xerr(f"pcnt {process_cnt}")
    positional_param_count = func_arg_cnt or get_positional_param_count(proc_func)
    assert positional_param_count > 0
    if process_cnt == 1:
        yield from iter((ll, proc_func(*ll[:positional_param_count])) for ll in tqdm_.tqdm(inputs))
        return

    if not total and isinstance(inputs, (list, tuple, set, dict)):
        total = len(inputs)

    fail_cnt = 0
    import concurrent
    import multiprocessing

    max_concurrency = slice_cnt or process_cnt
    if max_concurrency < process_cnt:
        xerr(f"slice cnt[{max_concurrency}] < process cnt[{process_cnt}]!, using {process_cnt}")
        max_concurrency = process_cnt

    desc = tqdm if isinstance(tqdm, str) else None

    def output_failed_tasks(failed_tasks: list) -> None:
        for i, (inp, e) in enumerate(failed_tasks):
            xerr(f"============failed input {i}/{len(failed_tasks)}", inp)
            traceback.print_exception(type(e), e, e.__traceback__, file=sys.stderr)

    # Make sure we get a consistent iterator throughout, rather than
    # getting the first element repeatedly.
    handler_inputs = iter(inputs)

    failed_tasks = []
    suc_cnt = 0

    with (
        concurrent.futures.ProcessPoolExecutor(
            max_workers=process_cnt,
            mp_context=multiprocessing.get_context(
                "spawn"
            ),  # fix hang  https://pythonspeed.com/articles/python-multiprocessing/
        ) as executor,
        tqdm_.tqdm(total=total, desc=desc) as pbar,
    ):
        futures = {
            executor.submit(proc_func, *input_[:positional_param_count]): input_
            for input_ in itertools.islice(handler_inputs, max_concurrency)
        }

        while futures:
            done, _ = concurrent.futures.wait(futures, return_when=concurrent.futures.FIRST_COMPLETED)
            for fut in done:
                original_input = futures.pop(fut)
                pbar.update(1)

                try:
                    result = fut.result(timeout=timeout)
                    suc_cnt += 1
                    yield original_input, result
                except TimeoutError as e:
                    fail_cnt += 1
                    failed_tasks.append((original_input, e))
                    xerr(
                        f"任务超时，已达到 {fail_cnt}/{max_fail_cnt} 次失败。input: ",
                        original_input,
                    )
                    if fail_cnt > max_fail_cnt:
                        xerr("超过最大失败次数，终止处理。")
                        output_failed_tasks(failed_tasks)
                        raise
                except Exception as e:
                    fail_cnt += 1
                    xerr(f"任务失败 {fail_cnt}/{max_fail_cnt}， input：", original_input)
                    traceback.print_exception(type(e), e, e.__traceback__, file=sys.stderr)
                    failed_tasks.append((original_input, e))
                    if fail_cnt > max_fail_cnt:
                        xerr("超过最大失败次数，终止处理。")
                        output_failed_tasks(failed_tasks)
                        raise
                    # TODO:  yeild Exception
                try:
                    input_ = next(handler_inputs)
                except StopIteration:
                    continue
                new_future = executor.submit(proc_func, *input_[:positional_param_count])
                futures[new_future] = input_

            # for input in itertools.islice(handler_inputs, len(done)):
            #     fut = executor.submit(proc_func, *input)
            #     futures[fut] = input
        output_failed_tasks(failed_tasks)
        xerr(f"{suc_cnt + len(failed_tasks)} tasks done: suc [{suc_cnt}], fail [{len(failed_tasks)}]")


def parallel_process_items_threads(
    inputs: str | Iterable,
    proc_func: Callable,
    *,
    thread_cnt: int = 4,
    tqdm: str | bool = True,
    total: int | None = None,
) -> Iterator:
    """多线程跑函数proc_func"""
    if isinstance(inputs, str):
        _inputs = read_file(inputs, tqdm=tqdm)
        if not is_large_file(inputs):
            with open(inputs) as fd:
                total = sum(1 for _ in fd)

    else:
        # _inputs = tqdm_.tqdm(inputs, total=total) if tqdm else inputs
        _inputs = inputs

    if isinstance(_inputs, (list, tuple)):
        total = len(_inputs)

    from multiprocessing.dummy import Pool

    with Pool(thread_cnt) as pool, tqdm_.tqdm(total=total) as pbar:
        imap_it = pool.imap(proc_func, _inputs)

        for it in imap_it:
            pbar.update(1)
            yield it


def parallel_process_items_threads_new(
    inputs: str | Iterable,
    proc_func: Callable,
    *,
    thread_cnt: int = 4,
    func_arg_cnt: int | None = None,
) -> Iterator:
    """多线程跑函数proc_func"""
    positional_param_count = func_arg_cnt or get_positional_param_count(proc_func)
    assert positional_param_count > 0, f"func_arg_cnt[{func_arg_cnt}] is invalid"

    if thread_cnt == 1:
        for ll in inputs:
            yield ll, proc_func(*ll[:positional_param_count])
        return

    from multiprocessing.dummy import Pool

    def func_wrapper(ll: Sequence) -> tuple[Sequence, Any]:
        params = ll[:positional_param_count]
        return ll, proc_func(*params)

    with Pool(thread_cnt) as pool:
        yield from pool.imap(func_wrapper, inputs)


def parallel_run_helper(func: Callable[P, R], ll: T, *args: P.args, **kws: P.kwargs) -> tuple[T, R]:
    """helper"""
    ret = func(*args, **kws)
    return ll, ret


VALID_FILE_SUFFIX = (
    ".tsv",
    ".csv",
    ".xlsx",
    ".txt",
    ".dat",
    ".data",
    ".json",
    ".jsonl",
    ".jpg",
    ".png",
    ".jpeg",
    ".html",
)


def remove_file_suffix(fname: str, *, force: bool = False) -> str:
    """去除文件特定后缀"""
    if force or fname.endswith(VALID_FILE_SUFFIX):
        return Path(f"{fname}").stem
    return fname


def join_with_delim(s1: str, s2: str, delim: str = ".") -> str:
    """以delim拼接s1和s2

    >>> join_with_delim("1", "2", ".")
    '1.2'
    >>> join_with_delim("1", ".tsv", ".")
    '1.tsv'
    """
    s1 = s1.removesuffix(delim)
    s2 = s2.removeprefix(delim)
    if s1 and s2:
        return f"{s1}{delim}{s2}"
    return f"{s1}{s2}"


def new_filename(
    fpath: OptionalStr,
    *,
    prefix: str = "",
    suffix: str = "",
    force: bool = False,
) -> OptionalStr:
    """新文件名

    >>> new_filename("1.tsv", prefix="2", suffix="3")
    '2.1.3.tsv'
    >>> new_filename("1.tsv", prefix="2", suffix="3.xlsx")
    '2.1.3.xlsx'
    >>> new_filename("1", prefix="2", suffix="3")
    '2.1.3'
    >>> new_filename("1", prefix="", suffix="3")
    '1.3'
    >>> new_filename("1", prefix="2")
    '2.1'
    >>> new_filename("./data1", suffix="2.tsv")
    './data1.2.tsv'

    >>> new_filename("./data1", suffix="2.tsv", force=1)
    './data1.2.tsv'

    >>> new_filename("./data1.xxx", suffix="2", force=1)
    './data1.2.xxx'
    """
    if fpath is None:
        return None
    assert prefix or suffix

    if not force:
        curr_suffix = Path(fpath).suffix if fpath.endswith(VALID_FILE_SUFFIX) else ""

        if suffix.endswith(VALID_FILE_SUFFIX):
            curr_suffix = ""
    else:
        _, extension = os.path.splitext(fpath)
        curr_suffix = extension

    fname = os.path.basename(fpath)
    dname = os.path.dirname(fpath)

    ret = join_with_delim(prefix, remove_file_suffix(fname, force=force), ".")
    ret = join_with_delim(ret, suffix, ".")
    ret = join_with_delim(ret, curr_suffix, ".")
    ret = os.path.join(dname, ret)
    # return f"{prefix}{remove_file_suffix(fname)}{suffix}{curr_suffix}"
    return ret


class TermMatcher:
    """从q中查询包含哪些term"""

    def __init__(
        self,
        terms: Iterable[str],
        *,
        ignore_case: bool = True,
        remove_punctions: bool = True,
        remove_whitespace: bool = True,
    ):
        """term list"""
        from ahocorasick import Automaton

        self.automaton = Automaton()

        # 添加模式串
        for term in terms:
            # 第二个是value
            k = nterm(
                term,
                lower=ignore_case,
                remove_punctions=remove_punctions,
                remove_whitespace=remove_whitespace,
            )
            if not k:
                xerr(f"term[{term}] empty after norm, skip")
                continue
            if k in self.automaton:
                xerr(f"term[{term}] nterm[{k}] dup, skip")
                continue

            # add_word(key, [value]) => bool
            self.automaton.add_word(k, (k, term))

        self.automaton.make_automaton()

    def match(
        self, q: str
    ) -> Generator[
        tuple[str, tuple[int, int, str]],
        None,
        None,
    ]:
        """返回查到的term: original_term, (start_index, end_index, matched_term)"""
        # iter(string, [start, [end]]),  Return an iterator of tuples (end_index, value)  for keys found in string.
        for end_index, (matched_term, original_term) in self.automaton.iter(q):
            start_index = end_index - len(matched_term) + 1
            yield original_term, (start_index, end_index, matched_term)


def jpath(js: dict, path: str, default: Any = None) -> list | Any:
    """从json中抽取value, 如 $.Result[*].DisplayData"""
    from jsonpath_ng import jsonpath, parse

    # "$.Result[0].DisplayData.resultData.tplData.tplSubData[0].result.goodsCompare.shopList[*].goodsList[*].shop_name"
    jsonpath_expr = parse(path)
    ret = [match.value for match in jsonpath_expr.find(js)]
    if not ret and default:
        return default
    return ret


__IGNORE_CNT: dict[Any, int] = collections.defaultdict(int)


def ignore(
    errors: Exception | tuple[Exception, ...] = Exception,
    default: T | None = None,
    max_error_cnt: int = 3,
) -> Callable[[Callable[P, R]], Callable[P, R | T]]:
    """specify errors to catch and default to return in case of error caught

    errors can either be exception class or a tuple of them.
    """

    def decorator(func: Callable[P, R]) -> Callable[P, R | T]:
        @functools.wraps(func)
        def wrapper(*args: P.args, **kwargs: P.kwargs) -> R | T:
            try:
                return func(*args, **kwargs)
            except errors:
                __IGNORE_CNT[func] += 1
                if __IGNORE_CNT[func] >= max_error_cnt:
                    raise
                return default

        return wrapper

    return decorator


@funcy.decorator
def with_ofname(
    call: Callable,
    *,
    ofname: str | None = None,
    prefix: str = "",
    suffix: str = "",
    mode: str = "w+",
):
    """为call function增加"""
    # print(call._func.__name__, "@@", call._args, "@@", call._kwargs)
    fname = call.fname if hasattr(call, "fname") else None

    if not ofname:
        ofname = fname
    if not ofname:
        ofname = call._func.__name__  # noqa: SLF001

    if ofname:
        ofname = new_filename(ofname, prefix=prefix, suffix=suffix)
        if hasattr(call, "ofname"):
            return redirect_stdout_to_file(ofname, mode=mode)(call)(ofname=ofname)
        return redirect_stdout_to_file(ofname, mode=mode)(call)()
    return call()


def unpack_list_args(func: Callable[..., T]) -> Callable[[list[Any]], T]:
    """将输入的list自动解包成函数的参数

    def func(a, b): pass
    unpack_list_args(func)([1, 2])
    """
    args_count = len(inspect.signature(func).parameters)

    def wrapper(ll: list) -> T:
        return func(*ll[:args_count])

    return wrapper


def crawl_parse(url: str, **css_selectors: str) -> dict[str, str | dict[str, Any]]:
    """抓取页面，并解析出css_selectors

    Return:
        title, text, html, css_selectors.XX

    >>> crawl_parse("https://www.maigoo.com/brand/1640591.html", website="div.navcont > div.logobox > a")[
    ...     "css_selectors"
    ... ]["website"][0].get("href")
    '/ajaxstream/link/?url=https://www.toptoyglobal.com/'
    """
    from bs4 import BeautifulSoup

    response = requests.get(url, timeout=300)
    soup = BeautifulSoup(response.text, "html.parser")

    results = {}
    results["title"] = soup.title.string if soup.title else None
    results["text"] = soup.get_text()
    results["html"] = soup.prettify()
    if css_selectors:
        results["css_selectors"] = {}

    for name, selector in css_selectors.items():
        # results[name] = [element.text for element in elements]
        results["css_selectors"][name] = soup.select(selector)

    return results


def print_tb():
    xerr(traceback.format_exc())


def doctest(verbose: bool = False) -> None:
    """test"""
    import doctest

    doctest.testmod(verbose=verbose)


def urlencode_params(**params: object) -> str:
    """返回 URLencode后的参数"""
    return urlencode(params)


def md5(input_string: str) -> str:
    """md5"""
    md5 = hashlib.md5()
    md5.update(input_string.encode("utf-8"))
    return md5.hexdigest()


_FCACHE_INSTANCES: dict[str, Cache] = {}
_FCACHE_LOCK = threading.Lock()


def fcache(
    cache_dir: str, ignore_empty_result: bool = True, *args: object, **kwargs: object
) -> Callable[[Callable[P, T]], Callable[P, T]]:
    """diskcache for function, expire=60*60*24*7

    https://grantjenks.com/docs/diskcache/api.html#diskcache.FanoutCache.memoize
    usage:
        @utils.fcache("./.cache")
        @utils.fcache("./cache_new", expire=60*60*24*7) # 7天过时
    """
    try:
        from diskcache import Cache
    except ModuleNotFoundError:
        xerr("diskcache library not found")
        return lambda orig_func: orig_func
    else:
        # cache = Cache(cache_dir)
        # import atexit

        # atexit.register(cache.close)
        with _FCACHE_LOCK:
            if cache_dir not in _FCACHE_INSTANCES:
                cache = Cache(cache_dir)
                atexit.register(cache.close)
                _FCACHE_INSTANCES[cache_dir] = cache
            else:
                cache = _FCACHE_INSTANCES[cache_dir]

        def decorator(func: Callable[P, T]) -> Callable[P, T]:
            memoized_func = cache.memoize(*args, **kwargs)(func)

            @functools.wraps(func)
            def wrapper(*func_args: P.args, **func_kwargs: P.kwargs) -> T:
                try:
                    result: T = memoized_func(*func_args, **func_kwargs)
                except RecursionError:
                    # 如果存入value是 `{}` 好像会raise exception，
                    xerr("disk cache failed", func_args, func_kwargs, sep="\n")
                    raise

                # Check if we should ignore caching for empty results
                if ignore_empty_result and (not result or (isinstance(result, str) and not result.strip())):
                    # Manually remove the result from cache if it was just stored
                    key = memoized_func.__cache_key__(*func_args, **func_kwargs)
                    if key in cache:
                        cache.pop(key, None)

                return result

            return wrapper

        return decorator


def fcache_op(
    cache_dir: str,
    op: Literal["clear", "check", "get", "set", "pop", "len", "peekitem", "peek", "poplast"],
    *args: str,
    **kwargs: Any,
) -> Any:
    """操作fcache对应

    https://grantjenks.com/docs/diskcache/api.html#diskcache.Cache.peekitem

    python utils.py fcache_op .gsearch_v1 peek

    python utils.py fcache_op .gsearch_v1 get "google_search.search"  "lv 是什么牌子" None
    """
    from diskcache import Cache

    if op == "len":
        op == "__len__"  # noqa: B015
    if op == "peek":
        op = "peekitem"
    if op in {"get", "pop"}:
        args = [tuple(args)]

    cache = Cache(cache_dir)
    if op == "poplast":
        k, _ = cache.peekitem()
        op = "pop"
        args = [k]
    func = getattr(cache, op)
    ret = func(*args, **kwargs)
    xdebug(args, kwargs, ret)
    cache.close()
    return ret


def b64decode(s: str, *, encoding: str = "utf8", ignore_exception: bool = False) -> str:
    """base64 decode"""
    try:
        # return base64.b64decode(s).decode(encoding, errors="replace")
        return base64.b64decode(s).decode(encoding)
    except Exception:
        if ignore_exception:
            return s
        raise


def may_from_stdin(arg: str) -> Callable[[Callable[P, R]], Callable[P, R]]:
    """
    如果指定的参数为None，则从标准输入读取其值。

    参数:
        arg (str): 需要检查的参数名称。

    返回:
        Callable: 包装后的装饰器函数。


    @may_from_stdin('username')
    def greet(username: str) -> None:
        print(f"Hello, {username}!")

    # 如果调用时未提供 `username` 参数，将会从标准输入读取
    greet()
    """

    def decorate(f: Callable[P, R]) -> Callable[P, R]:
        @wraps(f)
        def wrapped(*args: P.args, **kwargs: P.kwargs) -> R:
            # 获取函数的参数信息
            sig = inspect.signature(f)
            bound_args = sig.bind(*args, **kwargs)
            bound_args.apply_defaults()

            # 检查指定的参数是否为None
            if bound_args.arguments.get(arg) is None:
                # 读取stdin的输入
                input_value = sys.stdin.read().strip()
                bound_args.arguments[arg] = input_value

            return f(*bound_args.args, **bound_args.kwargs)

        return wrapped

    return decorate


def fetch_url(
    url: str,
    params: dict | None = None,
    json: dict | None = None,
    data: dict | bytes | None = None,
    retry_cnt: int = 3,
    return_format: Literal["html", "json", "markdown"] = "json",
    method: Literal["get", "post"] = "get",
    timeout: int = 10,
    proxy: str | list[str] | None = None,
    **kwargs: object,
) -> dict | str | None:
    """A function to fetch a URL with retry logic, random proxy selection, and format the response.

    :param url: URL to request.
    :param params: Parameters for GET requests.
    :param data: Data for POST requests (form-encoded).
    :param json: JSON data for POST requests.
    :param retry_cnt: Number of times to retry on failure.
    :param return_format: The format to return ('json' or 'html').
    :param method: HTTP method ('get' or 'post').
    :param timeout: Timeout for the request in seconds.
    :param proxy: A single proxy string or a list of proxy strings.
    :param kwargs: Additional arguments passed to requests.
    :return: Response content in the specified format.
    """
    method = method.lower()
    assert method in {"get", "post"}, "Method must be 'get' or 'post'."
    return_formats = {"json", "html", "markdown"}
    assert return_format in return_formats, f"Return format must in  {return_formats}."

    # Determine which proxy to use
    proxies = None
    if proxy:
        if isinstance(proxy, str) and "," in proxy:
            proxy = proxy.split(",")
        selected_proxy = random.choice(proxy) if isinstance(proxy, list) else proxy

        proxies = {"http": selected_proxy, "https": selected_proxy}

    for attempt in range(retry_cnt):
        try:
            if method == "get":
                response = requests.get(
                    url,
                    timeout=timeout,
                    proxies=proxies,
                    params=params,
                    verify=False,
                    **kwargs,
                )
            elif method == "post":
                response = requests.post(
                    url,
                    timeout=timeout,
                    proxies=proxies,
                    data=data,
                    json=json,
                    **kwargs,
                )

            response.raise_for_status()  # Raise an error for bad responses

            if return_format == "json":
                return response.json()  # Return JSON data

            # 使用charset检测编码
            response.encoding = response.apparent_encoding
            if return_format == "html":
                return response.text  # Return HTML content
            if return_format == "markdown":
                import html2text

                h = html2text.HTML2Text()
                return h.handle(response.text)

        except (requests.exceptions.RequestException, ValueError) as e:
            xerr(f"Attempt {attempt + 1} failed: {e}")
            if attempt < retry_cnt - 1:
                time.sleep(2**attempt)  # Exponential backoff
            else:
                raise  # Re-raise the last exception if max retries reached
    return None


def retry(
    exception_to_check: type[Exception] | tuple[Exception, ...],
    tries: int = 3,
    delay: int = 1,
    backoff: int = 2,
) -> Callable:
    """Retry calling the decorated function using an exponential backoff.

    :param exception_to_check: the exception to check. may be a tuple of exceptions to check
    :param tries: number of times to try (not retry) before giving up
    :param delay: initial delay between retries in seconds
    :param backoff: backoff multiplier e.g. value of 2 will double the delay each retry
    """

    def deco_retry(f: Callable[P, R]) -> Callable[P, R]:
        @functools.wraps(f)
        def f_retry(*args: P.args, **kwargs: P.kwargs) -> R:
            mtries, mdelay = tries, delay
            while mtries > 0:
                try:
                    return f(*args, **kwargs)
                except exception_to_check as e:
                    xerr(f"Exception: {e}, Retrying in {mdelay} seconds...")
                    time.sleep(mdelay)
                    mtries -= 1
                    mdelay *= backoff
            return f(*args, **kwargs)

        return f_retry  # true decorator

    return deco_retry


def get_defaultdict(depth: int = 1, default_factory: Callable[[], T] = int) -> collections.defaultdict:
    """创建多层级的defaultdict.

    :param depth: 要创建的嵌套defaultdict的层数
    :param default_factory: 最底层defaultdict的默认工厂函数，默认为int
    :return: 嵌套的defaultdict
    """
    if depth < 1:
        raise ValueError("depth必须是一个正整数")

    if depth == 1:
        return collections.defaultdict(default_factory)
    return collections.defaultdict(lambda: get_defaultdict(depth - 1, default_factory))


def split_by_multiple_seps(s: str, seps: str | list[str]) -> list[str]:
    """使用seps里的每个字符去给str分段

    >>> split_by_multiple_seps("a,b;c.d", ",;.")
    ['a', 'b', 'c', 'd']
    >>> split_by_multiple_seps("hello world! this is a test.", " !.")
    ['hello', 'world', 'this', 'is', 'a', 'test']
    >>> split_by_multiple_seps("one|two|three", "|")
    ['one', 'two', 'three']
    >>> split_by_multiple_seps("apple-orange-banana", "-")
    ['apple', 'orange', 'banana']
    >>> split_by_multiple_seps("no-separators", "")
    ['no-separators']
    """
    if not seps:
        return [s]
    if isinstance(seps, str):
        seps = list(seps)
    # Create a regex pattern that matches any of the separators
    pattern = f"[{''.join(map(re.escape, seps))}]"
    # Split the string using the pattern
    return [x for x in re.split(pattern, s) if x]


class StatCounter(contextlib.ContextDecorator):
    """统计次数

    使用嵌套的defaultdict来存储各维度的计数，线程安全
    """

    def __init__(
        self,
        depth: int = 1,
        dimension: int = 0,
        of: str | TextIO | None = None,
        mode: str = "w+",
    ):
        """初始化 StatCounter。

        Args:
            depth (int, optional): 统计时key的层级(dimension也会算上)。默认为 1。
            dimension (int, optional): 前多少个key作为分维度输出的依据。默认为0。
        """
        self.depth = depth
        self.dimension = dimension
        assert self.depth > self.dimension
        self.data = get_defaultdict(depth=depth, default_factory=int)
        self.lock = threading.Lock()

        self.of = None
        self.of_need_close = False
        if isinstance(of, str):
            self.of = open(of, mode)
            self.of_need_close = True
        elif of is not None:
            self.of = of

        self.do_exit = False
        atexit.register(self.__exit__, None, None, None)

    def inc(self, *args: Any, n: int = 1, **log_kwargs: Any) -> None:
        """增加指定维度下 key 的计数，并记录日志。

        Args:
            *args (Any):
                前 `depth` 个参数为统计键。
                剩余的参数为用于日志记录的额外消息。
            n (int, optional): 增加的数量。默认为 1。
            **log_kwargs (Any): 传递给日志记录的额外关键字参数。

        Raises:
            ValueError: 如果提供的参数数量少于 `depth`。
        """
        if len(args) < self.depth:
            msg = f"Number of arguments ({len(args)}) is less than the defined depth ({self.depth})"
            raise ValueError(msg)

        # 提取前 `depth` 个参数作为统计键
        keys: tuple[Hashable, ...] = args[: self.depth]
        extra_args: tuple[Any, ...] = args[self.depth :]

        with self.lock:
            # 导航到嵌套的 defaultdict
            current_level: Any = self.data
            path = []
            for key in keys[:-1]:
                current_level = current_level[key]
                path.append(str(key))
            final_key = keys[-1]
            current_level[final_key] += n
            path.append(str(final_key))

            # 获取当前计数
            count = current_level[final_key]

        path_str = "->".join(path)

        # 记录日志
        debug_message = f"{path_str}: count={count}"
        if "file" in log_kwargs:
            xdebug(debug_message, *extra_args, **log_kwargs)
            if log_kwargs["file"] is devnull:
                log_kwargs.pop("file")
                xonce(path_str, *extra_args, **log_kwargs)
        else:
            xdebug(debug_message, *extra_args, file=self.of, **log_kwargs)

    def __enter__(self) -> Self:
        """enter"""
        # 进入上下文时返回自身以便使用
        return self

    def __exit__(self, *_: object) -> None:
        """exit"""
        # 程序结束时自动输出统计结果
        if self.do_exit:
            return
        self.print_stats()
        if self.of_need_close:
            with contextlib.suppress(Exception):
                self.of.close()
        self.do_exit = True

    def print_stats(self):
        """分维度输出统计"""

        # 维度输出是 ===维度： xxxx, total cnt : xxx
        # 每一项的输出是 除了维度key之后 剩余的key 及其个数 和在此维度的百分比

        def traverse(data: dict, current_keys: list, limit: int) -> Generator[tuple[Any, dict], None, None]:
            """遍历dict到dimension

            >>> list(traverse({1: {2: 3}, "a": {"b": 4}}, [], 1))
            [(1, {2: 3}), ("a", {"b": 4})]
            """
            # xerr("tranr in", current_keys)
            if len(current_keys) == limit:
                yield (tuple(current_keys), data)
                return
            # xerr("trans", current_keys)
            for key, sub in data.items():
                yield from traverse(sub, [*current_keys, key], limit)

        # 如果 dimension 为0，表示不按任何维度分组
        if self.dimension == 0:
            total = sum(self.data.values())
            xerr(f"=== 总计: total cnt : {total}")
            for idx, (key, cnt) in enumerate(sorted(self.data.items(), key=itemgetter(1), reverse=True), 1):
                percent = safe_divide(cnt, total, percentage=True)
                xerr(f"{idx}. {key} : {cnt} ({percent}%)")
            xerr()
            return

        # 计算当前维度下所有计数的总和
        def sum_counter(d: collections.defaultdict | int) -> int:
            if isinstance(d, collections.defaultdict):
                return sum(sum_counter(v) for v in d.values())
            return d

        # xerr("@@@@", list(traverse({1: {2: 3}, "a": {"b": 4}}, [], 1)))
        # 按照指定的维度分组
        total_all = sum_counter(self.data)
        xerr(f"=== 总计: total cnt : {total_all}")
        for dimension_keys, counter in traverse(self.data, [], self.dimension):
            # xerr("loop", dimension_keys, counter)
            if not isinstance(counter, collections.defaultdict):
                # 不足深度，跳过
                xerr("counter skip for not dict")
                continue

            total = sum_counter(counter)
            dimension_percent = safe_divide(total, total_all, percentage=True)
            dimension_str = "->".join(map(str, dimension_keys))
            xerr(f"=== 维度: {dimension_str}, total cnt : {total} ({dimension_percent})")
            # 收集所有叶子节点的计数
            leaf_counts = {}

            def collect_leaves(d: collections.defaultdict, prefix: list = []) -> None:  # noqa: B006
                if isinstance(d, collections.defaultdict):
                    for k, v in d.items():
                        collect_leaves(v, [*prefix, k])
                else:
                    key_str = "->".join(map(str, prefix))
                    leaf_counts[key_str] = d

            collect_leaves(counter)
            for idx, (key, cnt) in enumerate(sorted(leaf_counts.items(), key=itemgetter(1), reverse=True), 1):
                percent = safe_divide(cnt, total, percentage=True)
                xerr(f"{idx}. {key} : {cnt} ({percent}%)")
            xerr()


stat_counter = StatCounter


@contextmanager
def write_file(fname: str | None = None, mode: str = "w+") -> Generator[IO, None, None]:
    """
    A context manager wrapper for the open function.

    If fname is None, it yields sys.stdout and does not close it upon exiting.
    Otherwise, it opens the specified file with the given mode and ensures it is closed upon exit.

    :param fname: The name of the file to open. If None, sys.stdout is used.
    :param mode: The mode in which to open the file. Defaults to "w+".
    :yield: A file-like object to write to.
    """
    if fname is None:
        # 当fname为None时，使用sys.stdout，不进行关闭
        with nullcontext(sys.stdout) as f:
            yield f
    else:
        # 否则，打开指定的文件，并确保在退出时关闭
        with open(fname, mode) as f:
            yield f


def run_with_file(
    fname: str | None = None,
    ofname: str | None = None,
    keys: list[KeyType] | None = None,
    expand_result: bool = False,
) -> Callable:
    r"""
    装饰器，用于从文件中读取数据，处理后将结果写入输出文件。

    参数:
    - fname: 输入文件名
    - ofname: 输出文件名
    - keys: 从每行数据中提取关键字的函数列表
    - expand_result 是否展开结果（为list/tuple/Iterator时）
    >>> def double(arg):
    ...     return arg * 2
    >>> import tempfile
    >>> with (
    ...     tempfile.NamedTemporaryFile("w+", delete=True) as tmp_file,
    ...     tempfile.NamedTemporaryFile("w+", delete=True) as tmp_file2,
    ... ):
    ...     with redirect_stdout_to_file(tmp_file.name):
    ...         print(123)
    ...     with redirect_stdout_to_file(tmp_file2.name):
    ...         run_with_file(tmp_file.name)(double)
    ...     tmp_file2.read().strip()
    '123\t123123'
    """
    if keys is None:
        keys = [0]

    if isinstance(keys, int):
        keys = [keys]

    def actual_decorator(func: Callable[P, R]) -> None:
        with write_file(ofname) as of:
            for ll in read_file(fname):
                real_keys = [make_key_func(key)(ll) for key in keys]
                result = func(*real_keys)
                if isinstance(result, (Generator, Iterator)):
                    result = list(result)

                if expand_result:
                    xprint(*ll, *result, file=of)
                else:
                    xprint(*ll, result, file=of)

    return actual_decorator


def echart(fname: str, chart: Literal["snakey", "funnel", "pie"], total: int | None = None):
    r"""Generate a chart (funnel, sankey, or pie) using pyecharts based on a TSV file.

    https://gallery.pyecharts.org/#/Sankey/sankey_vertical

    file format:
        snakey: source\ttarget\tvalue
        pie/funnel:source\tvalue

    Args:
        fname (str): Path to the TSV file.
        chart (str): Type of chart to generate ('funnel', 'sankey', 'pie').
        total (int | None): Total value for normalizing percentages (optional).
    """
    import pandas as pd
    from pyecharts import options as opts
    from pyecharts.charts import Funnel, Pie, Sankey

    ofname = new_filename(fname, suffix=f"{chart}.html")
    # Read TSV file into a DataFrame without header
    df = pd.read_csv(fname, sep="\t", header=None)

    # Assign default column names based on chart type
    if chart in ["funnel", "pie"]:
        df.columns = ["name", "value"]
    elif chart == "sankey":
        df.columns = ["source", "target", "value"]
    else:
        raise ValueError("Unsupported chart type. Choose from 'funnel', 'sankey', or 'pie'.")

    # Normalize value column if total is provided
    if total is not None:
        df["value"] = (df["value"] * 100 / total).round().astype(int)

    # Generate the specified chart
    if chart == "funnel":
        funnel = (
            Funnel()
            .add(
                "",
                [list(z) for z in zip(df["name"], df["value"], strict=False)],
                label_opts=opts.LabelOpts(position="inside"),
            )
            .set_global_opts(title_opts=opts.TitleOpts(title=fname))
        )
        funnel.render(ofname)

    elif chart == "sankey":
        nodes = [{"name": x} for x in set(df["source"]).union(set(df["target"]))]
        links = df[["source", "target", "value"]].to_dict(orient="records")
        sankey = (
            Sankey()
            .add(
                "",
                nodes,
                links,
                layout_iterations=100,
                linestyle_opt=opts.LineStyleOpts(opacity=0.2, curve=0.5, color="source"),
                label_opts=opts.LabelOpts(
                    position="right",
                    formatter="{b}: {c}",
                    overflow="break",
                    color="auto",
                ),
            )
            .set_global_opts(title_opts=opts.TitleOpts(title=fname))
        )
        sankey.render(ofname)

    elif chart == "pie":
        pie = (
            Pie()
            .add(
                "",
                [list(z) for z in zip(df["name"], df["value"], strict=False)],
                radius=["40%", "70%"],
            )
            .set_global_opts(
                title_opts=opts.TitleOpts(title=fname),
                legend_opts=opts.LegendOpts(orient="vertical", pos_top="15%", pos_right="10%"),
            )
            .set_series_opts(label_opts=opts.LabelOpts(formatter="{b}: {d}%"))
        )
        pie.render(ofname)

    else:
        raise ValueError("Unsupported chart type. Choose from 'funnel', 'sankey', or 'pie'.")

    xerr(f"{chart.capitalize()} chart has been rendered and saved as an HTML file: {ofname}")


def strip_accents(s: OptionalStr) -> OptionalStr:
    """去除unicode中的重读 兰蔻LANCÔM -> 兰蔻LANCOM"""
    if not s:
        return s

    assert s is not None
    result = "".join(c for c in unicodedata.normalize("NFD", s) if unicodedata.category(c) != "Mn")
    return cast("OptionalStr", result)


def aggregate_by_key(
    fname: str | None = None,
    key: KeyType = 0,
    value: KeyType = 1,
    unpack: bool = False,
    with_len: bool = False,
    *args,
    **kwargs,
):
    """根据指定键（key）对值（value）进行分组，并打印聚合结果。

    该函数是 `read_kv` 的一个封装，用于快速进行分组聚合和格式化输出。
    它从数据源读取数据，将 `value` 列按 `key` 列进行分组，然后逐行打印
    每个 key 及其聚合后的 value 列表。

    Args:
        fname: 数据源文件名。若为 None，则行为取决于底层 `read_kv` 的实现
               （通常是从标准输入读取）。
        key: 用于分组的键，可以是列索引（int）或列名（str）。默认为 0。
        value: 需要被聚合的值，可以是列索引（int）或列名（str）。默认为 1。
        unpack: 是否将聚合后的 value 列表展开。
                - True: 列表中的每个元素作为独立列输出。
                - False: 整个 value 列表作为一个单独的列输出。
                默认为 False。
        with_len: 是否在输出中包含聚合值的数量。
                  - True: 在 key 之后、value 之前插入一个计数列。
                  - False: 不输出计数列。
                  默认为 False。
        *args: 传递给底层 `read_kv` 函数的位置参数。
        **kwargs: 传递给底层 `read_kv` 函数的关键字参数。

    Side Effects:
        此函数没有返回值。它会调用 `xprint` 将结果直接打印到标准输出。

    Examples:
        假设输入数据 (data.txt) 如下，以制表符分隔:
        ```
        user1   itemA
        user2   itemB
        user1   itemC
        user1   itemA
        ```

        1. 默认调用:
        >>> aggregate_by_key("data.txt")
        # 输出:
        # user1   ['itemA', 'itemC', 'itemA']
        # user2   ['itemB']

        2. 包含数量 (with_len=True):
        >>> aggregate_by_key("data.txt", with_len=True)
        # 输出:
        # user1   3   ['itemA', 'itemC', 'itemA']
        # user2   1   ['itemB']

        3. 展开 value 列表 (unpack=True):
        >>> aggregate_by_key("data.txt", unpack=True)
        # 输出:
        # user1   itemA   itemC   itemA
        # user2   itemB

        4. 同时启用 with_len 和 unpack:
        >>> aggregate_by_key("data.txt", with_len=True, unpack=True)
        # 输出:
        # user1   3   itemA   itemC   itemA
        # user2   1   itemB
    """
    for k, vs in read_kv(fname, *args, value_accumulate_func=None, key=key, value=value, **kwargs).items():
        res = [k, len(vs)] if with_len else [k]
        res = [*res, *vs] if unpack else [*res, vs]
        xprint(*res)


def _normalize_transform_output(
    output: Any,
    mode: str,
) -> tuple[tuple, dict]:
    """根据指定模式，将 transform 函数的输出标准化为 (args, kwargs) 元组。"""

    if mode == "auto":
        if (
            isinstance(output, tuple)
            and len(output) == 2
            and isinstance(output[0], tuple)
            and isinstance(output[1], dict)
        ):
            return output
        if isinstance(output, dict):
            return ((), output)
        if isinstance(output, tuple):
            return (output, {})
        return ((output,), {})

    if mode == "args_kwargs":
        if (
            isinstance(output, tuple)
            and len(output) == 2
            and isinstance(output[0], tuple)
            and isinstance(output[1], dict)
        ):
            return output
        msg = f"transform_mode='args_kwargs' 要求返回值是 (tuple, dict) 格式, 但得到: {type(output).__name__}"
        raise TypeError(msg)

    if mode == "kwargs":
        if isinstance(output, dict):
            return ((), output)
        msg = f"transform_mode='kwargs' 要求返回值是 dict, 但得到: {type(output).__name__}"
        raise TypeError(msg)

    if mode == "args":
        if isinstance(output, tuple):
            return (output, {})
        msg = f"transform_mode='args' 要求返回值是 tuple, 但得到: {type(output).__name__}"
        raise TypeError(msg)

    if mode == "single_arg":
        return ((output,), {})

    msg = f"不支持的 transform_mode: '{mode}'"
    raise ValueError(msg)


def parallel_process(  # noqa: C901, PLR0912, PLR0915
    inputs: Iterable[T_Input],
    target_func: Callable[..., T_Output],
    *,
    transform: Callable[[T_Input], Any] | None = None,
    transform_mode: Literal["auto", "kwargs", "args", "single_arg"] = "auto",
    process_cnt: int | None = None,
    max_concurrency: int | None = None,
    tqdm_desc: str | None = "Processing",
    total: int | None = None,
    timeout: int | None = None,
    max_fail_cnt: int | float = 50,
) -> Generator[tuple[T_Input, T_Output | Exception], None, None]:
    """
    使用多进程并行处理输入项，并通过 transform 函数适配目标函数。

    参数:
    - inputs: 包含原始数据的可迭代对象。
    - target_func: 需要被并发执行的目标函数 (必须是可序列化的)。
    - transform: 一个转换函数，接收 inputs 中的单个元素，返回 target_func 的参数
    - transform_mode: 指定如何解析 transform 函数的返回值。
                 - 'auto' (默认): 自动检测返回类型 (tuple, dict), dict, tuple 或其他。
                 - 'args_kwargs': 强制要求返回 (tuple, dict)。
                 - 'kwargs': 强制要求返回 dict。
                 - 'args': 强制要求返回 tuple。
                 - 'single_arg': 将返回值视为单一位置参数。
    - process_cnt: 并行进程数。默认为 CPU 核心数。
    - max_concurrency: 最大并发任务数，用于控制同时在处理的任务量，防止内存爆炸。
                       默认为 process_cnt。
    - tqdm_desc: tqdm 进度条的描述文本。如果为 None，则不显示进度条。
    - total: 输入项的总数，用于tqdm。如果 inputs 是列表等有长度的类型，会自动计算。
    - timeout: 每个任务的超时时间（秒）。
    - max_fail_cnt: 允许的最大失败次数。超过后将抛出最后的异常。如果为小数 则表示占比

    返回:
    - 一个生成器，逐个产出 (原始输入, 结果或异常对象) 的元组。
    """

    def _identify(x: T_Input) -> tuple[tuple[T_Input], dict]:
        return (x,), {}

    if transform is None:
        transform = _identify

    if not callable(transform):
        raise TypeError("transform 必须是可调用的函数")
    if not callable(target_func):
        raise TypeError("target_func 必须是可调用的函数")

    # 确定进程数
    if process_cnt is None:
        process_cnt = os.cpu_count() or 1

    # 如果不使用tqdm，则将desc设为None
    desc = tqdm_desc if tqdm_desc is not None else None

    # 单进程模式：简单、易于调试，无需复杂的并发处理
    if process_cnt == 1:
        pbar = tqdm_.tqdm(inputs, total=total, desc=desc, disable=desc is None)
        for original_input in pbar:
            # args, kwargs = transform(original_input)
            transformed_output = transform(original_input)
            args, kwargs = _normalize_transform_output(transformed_output, mode=transform_mode)
            result = target_func(*args, **kwargs)
            yield original_input, result
        return

    # 多进程模式
    if not total and isinstance(inputs, (list, tuple, set, dict)):
        total = len(inputs)

    fail_cnt = 0
    failed_tasks: list[tuple[T_Input, Exception]] = []

    # 确定并发窗口大小
    concurrency = max_concurrency or process_cnt
    if concurrency < process_cnt:
        xerr(
            f"警告: max_concurrency ({concurrency}) 小于 process_cnt ({process_cnt})。"
            "建议保持 max_concurrency >= process_cnt。"
        )

    def output_failed_tasks(tasks: list) -> None:
        if not tasks:
            return
        xerr("-" * 60)
        xerr(f"报告 {len(tasks)} 个失败的任务:")
        for i, (inp, e) in enumerate(tasks):
            xerr(f"--- 失败任务 {i + 1}/{len(tasks)} ---")
            xerr(f"输入: {inp}")
            traceback.print_exception(type(e), e, e.__traceback__, file=sys.stderr)
        xerr("-" * 60)

    # 将输入转换为迭代器，以确保我们始终向前处理
    handler_inputs = iter(inputs)
    import concurrent.futures

    if total:
        max_fail_cnt = max_fail_cnt if max_fail_cnt >= 1 else int(total * max_fail_cnt)
    elif max_fail_cnt < 1:
        max_fail_cnt = 50
    xerr(f"{total=}, {max_fail_cnt=}")

    with (
        concurrent.futures.ProcessPoolExecutor(max_workers=process_cnt) as executor,
        tqdm_.tqdm(total=total, desc=desc, disable=desc is None) as pbar,
    ):
        # {future: original_input} 的映射
        futures: dict[concurrent.futures.Future, T_Input] = {}

        # 1. 初始填充任务队列，达到最大并发数
        for original_input in itertools.islice(handler_inputs, concurrency):
            try:
                # args, kwargs = transform(original_input)
                transformed_output = transform(original_input)
                args, kwargs = _normalize_transform_output(transformed_output, mode=transform_mode)
                future = executor.submit(target_func, *args, **kwargs)
                futures[future] = original_input
            except Exception as e:
                # 转换阶段就失败了
                fail_cnt += 1
                failed_tasks.append((original_input, e))
                pbar.update(1)

        # 2. 主循环：当有任务在执行时，持续处理
        while futures:
            # 等待至少一个任务完成
            done, _ = concurrent.futures.wait(futures, return_when=concurrent.futures.FIRST_COMPLETED)

            for fut in done:
                original_input = futures.pop(fut)
                pbar.update(1)

                # 2a. 获取结果
                try:
                    result = fut.result(timeout=timeout)
                    yield original_input, result
                except Exception as e:
                    fail_cnt += 1
                    failed_tasks.append((original_input, e))
                    yield original_input, e  # 产出异常

                    xerr(f"任务失败 ({type(e).__name__})，累计失败 {fail_cnt}/{max_fail_cnt}。输入: {original_input}")
                    if fail_cnt > max_fail_cnt:
                        xerr("超过最大失败次数，正在终止...")
                        output_failed_tasks(failed_tasks)
                        # 取消所有剩余的 future
                        for f in futures:
                            f.cancel()
                        raise

                # 2b. 补充新任务（如果还有的话）
                try:
                    next_input = next(handler_inputs)
                except StopIteration:
                    # 输入已经耗尽，无需补充
                    pass
                else:
                    try:
                        transformed_output = transform(next_input)
                        args, kwargs = _normalize_transform_output(transformed_output, mode=transform_mode)
                        # args, kwargs = transform(next_input)
                        new_future = executor.submit(target_func, *args, **kwargs)
                        futures[new_future] = next_input
                    except Exception as e:
                        # 新任务在转换阶段就失败了
                        fail_cnt += 1
                        failed_tasks.append((next_input, e))
                        pbar.update(1)

    # 循环结束后，报告所有失败的任务
    suc_cnt = (total or pbar.n) - len(failed_tasks)
    output_failed_tasks(failed_tasks)
    xerr(f"处理完成。成功: {suc_cnt}, 失败: {len(failed_tasks)}")


def parallel_thread(  # noqa: C901
    inputs: Iterable[T_Input],
    target_func: Callable[..., T_Output],
    *,
    # transform: Callable[[T_Input], tuple[tuple, dict]] | None = None,
    transform: Callable[[T_Input], Any] | None = None,
    transform_mode: Literal["auto", "kwargs", "args", "single_arg"] = "auto",
    thread_cnt: int | None = 20,
    tqdm_desc: str | None = "Processing",
    max_fail_cnt: int = 20,
    ordered_return: bool = True,
) -> Generator[tuple[T_Input, T_Output | Exception], None, None]:
    """
    使用多线程并行处理输入项，并通过 transform 函数适配目标函数。

    参数:
    - inputs: 包含原始数据的可迭代对象。
    - target_func: 需要被并发执行的目标函数 (必须是线程安全的)。
    - transform: 一个转换函数，接收 inputs 中的单个元素，返回 target_func 的参数
    - transform_mode: 指定如何解析 transform 函数的返回值。
                 - 'auto' (默认): 自动检测返回类型 (tuple, dict), dict, tuple 或其他。
                 - 'args_kwargs': 强制要求返回 (tuple, dict)。
                 - 'kwargs': 强制要求返回 dict。
                 - 'args': 强制要求返回 tuple。
                 - 'single_arg': 将返回值视为单一位置参数。
    - thread_cnt: 并行线程数。默认为 min(32, os.cpu_count() + 4)。
    - tqdm_desc: tqdm 进度条的描述文本。如果为 None，则不显示进度条。
    - max_fail_cnt: 允许的最大失败次数。超过后将抛出最后的异常。
    - ordered_return: 是否保证输出顺序与输入顺序一致。

    返回:
    - 一个生成器，按顺序或完成顺序产出 (原始输入, 结果或异常对象) 的元组。
    """

    def _identify(x: T_Input) -> tuple[tuple[T_Input], dict]:
        return (x,), {}

    if transform is None:
        transform = _identify

    if not callable(transform) or not callable(target_func):
        raise TypeError("transform and target_func must be callable")

    if thread_cnt is None:
        thread_cnt = min(32, (os.cpu_count() or 1) + 4)

    fail_cnt = 0
    failed_tasks: list[tuple[T_Input, Exception]] = []

    def output_failed_tasks(tasks: list) -> None:
        if not tasks:
            return
        xerr("-" * 60)
        xerr(f"报告 {len(tasks)} 个失败的任务:")
        for i, (inp, e) in enumerate(tasks):
            xerr(f"--- 失败任务 {i + 1}/{len(tasks)} ---")
            xerr(f"输入: {inp}")
            traceback.print_exception(type(e), e, e.__traceback__, file=sys.stderr)
        xerr("-" * 60)

    # --- Single-threaded mode for simplicity and debugging ---
    if thread_cnt == 1:
        pbar = tqdm_.tqdm(inputs, desc=tqdm_desc, disable=tqdm_desc is None)
        for original_input in pbar:
            try:
                # args, kwargs = transform(original_input)
                transformed_output = transform(original_input)
                args, kwargs = _normalize_transform_output(transformed_output, mode=transform_mode)
                yield original_input, target_func(*args, **kwargs)
            except Exception as e:
                yield original_input, e
        return

    # --- Multi-threaded modes ---
    if ordered_return:
        # --- Ordered Mode using multiprocessing.dummy.Pool.imap ---
        # This is concise and correct for ordered results.
        from multiprocessing.dummy import Pool

        inputs_list = list(inputs)
        total = len(inputs_list)
        if not total:
            return

        def wrapper(original_input: T_Input) -> tuple[T_Input, T_Output | Exception]:
            try:
                # args, kwargs = transform(original_input)
                transformed_output = transform(original_input)
                args, kwargs = _normalize_transform_output(transformed_output, mode=transform_mode)
                return original_input, target_func(*args, **kwargs)
            except Exception as e:
                return original_input, e

        with Pool(thread_cnt) as pool:
            pbar = tqdm_.tqdm(pool.imap(wrapper, inputs_list), total=total, desc=tqdm_desc, disable=tqdm_desc is None)
            for original_input, result in pbar:
                if isinstance(result, Exception):
                    fail_cnt += 1
                    failed_tasks.append((original_input, result))
                yield original_input, result
    else:
        # --- Unordered Mode using ThreadPoolExecutor ---
        # This correctly implements the "sliding window" of concurrent tasks.
        import concurrent.futures

        with concurrent.futures.ThreadPoolExecutor(max_workers=thread_cnt) as executor:
            inputs_iterator = iter(inputs)
            future_to_input = {}
            pbar = tqdm_.tqdm(desc=tqdm_desc, disable=tqdm_desc is None)

            # Initial submission of tasks
            for _ in range(thread_cnt):
                try:
                    original_input = next(inputs_iterator)
                    # args, kwargs = transform(original_input)
                except StopIteration:
                    break
                else:
                    try:
                        transformed_output = transform(original_input)
                        args, kwargs = _normalize_transform_output(transformed_output, mode=transform_mode)
                        future = executor.submit(target_func, *args, **kwargs)
                        future_to_input[future] = original_input
                    except Exception as e:
                        fail_cnt += 1
                        failed_tasks.append((original_input, e))
                        yield original_input, e

            # Process tasks as they complete
            while future_to_input:
                for future in concurrent.futures.as_completed(future_to_input):
                    original_input = future_to_input.pop(future)
                    pbar.update(1)
                    try:
                        result = future.result()
                        yield original_input, result
                    except Exception as e:
                        fail_cnt += 1
                        failed_tasks.append((original_input, e))
                        yield original_input, e

                    # Submit the next task from the iterator
                    try:
                        next_input = next(inputs_iterator)
                    except StopIteration:
                        pass  # No more tasks to submit
                    else:
                        try:
                            # args, kwargs = transform(next_input)
                            transformed_output = transform(next_input)
                            args, kwargs = _normalize_transform_output(transformed_output, mode=transform_mode)
                            new_future = executor.submit(target_func, *args, **kwargs)
                            future_to_input[new_future] = next_input
                        except Exception as e:
                            fail_cnt += 1
                            failed_tasks.append((next_input, e))
                            yield next_input, e

                    if fail_cnt >= max_fail_cnt:
                        xerr(f"Exceeded max fail count ({max_fail_cnt}). Halting.")
                        # Cancel remaining futures
                        for f in future_to_input:
                            f.cancel()
                        future_to_input.clear()
                        break
            pbar.close()

    # Final report
    output_failed_tasks(failed_tasks)
    if fail_cnt >= max_fail_cnt:
        raise failed_tasks[-1][1] from None


def classification_report(
    y_true: list[float] | None = None,
    y_pred: list[float] | None = None,
    fname: str | None = None,
    y_true_idx: int = 0,
    y_pred_idx: int = 1,
    digits: int = 3,
    positive_label: int = 1,
    col_width: int = 17,
    print_report: bool = True,
):
    """
    轻量级分类评估报告，支持二分类和多分类

    参数:
        y_true: list[int/str] or np.ndarray
        y_pred: list[int/str] or np.ndarray
        digits: 小数点保留位数（仅影响打印）
        positive_label: 二分类正类标签，必须出现在数据标签集合中
        col_width: 打印表格列宽
        print_report: 是否打印报告；False 时仅返回结果字典

    返回:
        dict: 包含 per_class 和 summary
            per_class: {label: {"precision", "recall", "f1", "support"}}
            summary: {
                "accuracy", "balanced_accuracy",
                "mcc",
                "specificity"(仅二分类),
                "micro avg": {"precision","recall","f1"},
                "macro avg": {"precision","recall","f1"},
                "weighted avg": {"precision","recall","f1"},
                "total": 样本总数
            }
    """
    import numpy as np

    def safe_div(n: float, d: float) -> float:
        return float(n) / float(d) if d != 0 else 0.0

    if y_true is None and y_pred is None:
        assert fname
        y_true = []
        y_pred = []
        for ll in read_file(fname):
            y_true.append(int(ll[y_true_idx]))
            y_pred.append(int(ll[y_pred_idx]))

    y_true = np.asarray(y_true)
    y_pred = np.asarray(y_pred)

    assert y_true is not None
    assert y_pred is not None
    if len(y_true) != len(y_pred):
        raise ValueError("y_true 与 y_pred 的长度不一致")
    total = len(y_true)
    if total == 0:
        raise ValueError("空输入：没有样本")
    # 全局 accuracy
    accuracy = safe_div(np.sum(y_true == y_pred), total)

    # 标签集合（保持稳定顺序）
    labels = np.unique(np.concatenate([y_true, y_pred]))
    positive_label = labels.dtype.type(positive_label)
    n_labels = len(labels)

    # ================= 二分类 =================
    if n_labels == 2:
        if positive_label not in set(labels.tolist()):
            msg = f"positive_label={positive_label} 不在数据标签集合 {labels.tolist()} 中，请显式指定。"
            raise ValueError(msg)
        negative_label = labels.dtype.type(next(label for label in labels if label != positive_label))

        # 统计
        tp = int(np.sum((y_true == positive_label) & (y_pred == positive_label)))
        fp = int(np.sum((y_true == negative_label) & (y_pred == positive_label)))
        fn = int(np.sum((y_true == positive_label) & (y_pred == negative_label)))
        tn = int(np.sum((y_true == negative_label) & (y_pred == negative_label)))
        xdebug(f"{n_labels=}, {tp=}, {fp=}, {tn=}, {fn=}, {positive_label=}, {negative_label=}")

        # 正类
        precision_pos = safe_div(tp, tp + fp)
        recall_pos = safe_div(tp, tp + fn)
        f1_pos = safe_div(2 * precision_pos * recall_pos, precision_pos + recall_pos)
        support_pos = int(np.sum(y_true == positive_label))

        # 负类（当作对称 one-vs-rest）
        precision_neg = safe_div(tn, tn + fn)  # NPV
        recall_neg = safe_div(tn, tn + fp)  # TNR / specificity
        f1_neg = safe_div(2 * precision_neg * recall_neg, precision_neg + recall_neg)
        support_neg = int(np.sum(y_true == negative_label))

        per_class = {
            positive_label: {"precision": precision_pos, "recall": recall_pos, "f1": f1_pos, "support": support_pos},
            negative_label: {"precision": precision_neg, "recall": recall_neg, "f1": f1_neg, "support": support_neg},
        }

        precisions = [precision_pos, precision_neg]
        recalls = [recall_pos, recall_neg]
        f1s = [f1_pos, f1_neg]
        supports = [support_pos, support_neg]

        macro = {
            "precision": float(np.mean(precisions)),
            "recall": float(np.mean(recalls)),
            "f1": float(np.mean(f1s)),
        }
        weighted = {
            "precision": float(np.sum(np.array(precisions) * np.array(supports)) / total),
            "recall": float(np.sum(np.array(recalls) * np.array(supports)) / total),
            "f1": float(np.sum(np.array(f1s) * np.array(supports)) / total),
        }
        micro = {"precision": accuracy, "recall": accuracy, "f1": accuracy}

        balanced_accuracy = macro["recall"]
        specificity = recall_neg
        denom = np.sqrt((tp + fp) * (tp + fn) * (tn + fp) * (tn + fn))
        mcc = safe_div((tp * tn) - (fp * fn), denom)

        summary = {
            "accuracy": accuracy,
            "balanced_accuracy": balanced_accuracy,
            "specificity": specificity,
            "mcc": mcc,
            "micro avg": micro,
            "macro avg": macro,
            "weighted avg": weighted,
            "total": int(total),
        }

    # ================= 多分类 =================
    label_to_idx = {lab: i for i, lab in enumerate(labels)}
    idx_true = np.array([label_to_idx[v] for v in y_true])
    idx_pred = np.array([label_to_idx[v] for v in y_pred])

    cm = np.zeros((n_labels, n_labels), dtype=int)
    for i in range(total):
        cm[idx_true[i], idx_pred[i]] += 1

    per_class = {}
    precisions, recalls, f1s, supports = [], [], [], []

    for i, c in enumerate(labels):
        tp = cm[i, i]
        fp = int(np.sum(cm[:, i]) - tp)
        fn = int(np.sum(cm[i, :]) - tp)
        support = int(np.sum(cm[i, :]))

        precision = safe_div(tp, tp + fp)
        recall = safe_div(tp, tp + fn)
        f1 = safe_div(2 * precision * recall, precision + recall)

        per_class[c] = {"precision": precision, "recall": recall, "f1": f1, "support": support}

        precisions.append(precision)
        recalls.append(recall)
        f1s.append(f1)
        supports.append(support)

    macro = {"precision": float(np.mean(precisions)), "recall": float(np.mean(recalls)), "f1": float(np.mean(f1s))}
    weighted = {
        "precision": float(np.sum(np.array(precisions) * np.array(supports)) / total),
        "recall": float(np.sum(np.array(recalls) * np.array(supports)) / total),
        "f1": float(np.sum(np.array(f1s) * np.array(supports)) / total),
    }

    tp_sum = float(np.trace(cm))
    fp_sum = float(np.sum(cm) - np.trace(cm))
    fn_sum = float(np.sum(cm) - np.trace(cm))
    micro_p = safe_div(tp_sum, tp_sum + fp_sum)
    micro_r = safe_div(tp_sum, tp_sum + fn_sum)
    micro_f1 = safe_div(2 * micro_p * micro_r, micro_p + micro_r)
    micro = {"precision": micro_p, "recall": micro_r, "f1": micro_f1}

    balanced_accuracy = macro["recall"]

    t_sum = float(np.sum(cm))
    row_sums = np.sum(cm, axis=1).astype(float)
    col_sums = np.sum(cm, axis=0).astype(float)
    s = float(np.sum(row_sums * col_sums))
    trace = float(np.trace(cm))
    denom_left = t_sum**2 - np.sum(col_sums**2)
    denom_right = t_sum**2 - np.sum(row_sums**2)
    denom = np.sqrt(denom_left * denom_right)
    mcc = safe_div((trace * t_sum) - s, denom)

    summary = {
        "accuracy": accuracy,
        "balanced_accuracy": balanced_accuracy,
        "mcc": mcc,
        "macro avg": macro,
        "micro avg": micro,
        "weighted avg": weighted,
        "total": int(total),
    }

    if print_report:
        header = (
            f"{'Class':>{col_width}} {'Precision':>{col_width}} "
            f"{'Recall':>{col_width}} {'F1':>{col_width}} {'Support':>{col_width}}"
        )
        print(header)
        print("-" * len(header))
        for c in labels:
            p = per_class[c]["precision"]
            r = per_class[c]["recall"]
            f = per_class[c]["f1"]
            s = per_class[c]["support"]
            print(
                f"{c!s:>{col_width}} {p:{col_width}.{digits}f} "
                f"{r:{col_width}.{digits}f} {f:{col_width}.{digits}f} {s:{col_width}d}"
            )

        print("\nSummary")
        print("-" * (len("Summary") + 0))
        print(f"{'accuracy':>{col_width}} {summary['accuracy']:{col_width}.{digits}f}")
        print(f"{'balanced_acc':>{col_width}} {summary['balanced_accuracy']:{col_width}.{digits}f}")
        print(f"{'mcc':>{col_width}} {summary['mcc']:{col_width}.{digits}f}")

        header_avg = (
            f"{'Average':>{col_width}} {'Precision':>{col_width}} "
            f"{'Recall':>{col_width}} {'F1':>{col_width}} {'Support':>{col_width}}"
        )
        print(header_avg)
        print("-" * len(header_avg))
        for avg_name in ["micro avg", "macro avg", "weighted avg"]:
            avg_metrics = summary[avg_name]
            print(
                f"{avg_name:>{col_width}} {avg_metrics['precision']:{col_width}.{digits}f}"
                f" {avg_metrics['recall']:{col_width}.{digits}f} "
                f"{avg_metrics['f1']:{col_width}.{digits}f} {total:{col_width}d}"
            )

    return {"per_class": per_class, "summary": summary}


def import_from_string(path: str):
    """
    根据字符串动态导入函数或对象
    :param path: 例如 "run.func1" 表示从 run.py 中获取 func1
    :return: 对应的对象（函数、类、变量等）
    """
    import importlib
    import sys

    sys.path.append(".")  # 把当前目录加进去
    sys.path.append(os.getcwd())  # 把当前目录加进去

    if "." not in path:
        raise ValueError("路径格式错误，应为 'module.attr'")

    module_name, attr_name = path.rsplit(".", 1)
    module = importlib.import_module(module_name)
    return getattr(module, attr_name)


def run_with_file_v2(
    ifname: str,
    func: str,  # "run.fun"
    keys: list[KeyType] | None = None,
    expand_result: bool = False,
    transform_mode: Literal["single_arg", "args"] = "args",
    **func_kwargs,
):
    if keys is None:
        keys = [0]

    if isinstance(keys, int):
        keys = [keys]

    real_func = import_from_string(func)
    keys_func = [make_key_func(key) for key in keys]
    for ll in read_file(ifname):
        real_keys = [key_func(ll) for key_func in keys_func]
        if transform_mode == "args":
            result = real_func(*real_keys, **func_kwargs)
        else:
            result = real_func(real_keys, **func_kwargs)

        if isinstance(result, (Generator, Iterator)):
            result = list(result)

        if expand_result:
            xprint(*ll, *result)
        else:
            xprint(*ll, result)


if __name__ == "__main__":
    fire.Fire()
