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
import types
import unicodedata
from collections.abc import (
    Callable,
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
from operator import itemgetter
from pathlib import Path
from typing import (
    IO,
    Any,
    Literal,
    NewType,
    Optional,
    ParamSpec,
    Self,
    TextIO,
    TypeAlias,
    TypeVar,
    TypeVarTuple,
)
from urllib.parse import urlencode

import funcy
import pandas as pd
import requests
import tqdm as tqdm_
from bs4 import BeautifulSoup
from diskcache import Cache
from termcolor import colored

requests.packages.urllib3.disable_warnings()

T = TypeVar("T")
OptionalStr = TypeVar("OptionalStr", str, None)

R = TypeVar("R")
Ts = TypeVarTuple("Ts")
P = ParamSpec("P")
KeyType: TypeAlias = int | slice | Sequence | Mapping | AbstractSet | Callable[..., Any]


devnull = open(os.devnull, "w")  # noqa: SIM115

with contextlib.suppress(Exception):
    from traceback_with_variables import activate_by_import

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
    file: "IO|None" = None,
    encoding: str = "utf8",
    output_flag: bool = True,
    color: Literal["red", "blue", "green"] | None = None,
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
    values_str = [make_str(value) for value in values]
    out = sep.join(values_str) + end
    out = color_text_if_atty(out, color)
    if hasattr(file, "buffer"):
        file.buffer.write(out.encode(encoding))
    else:
        file.write(out)
    if flush:
        file.flush()


def xerr(
    *values: object,
    suffix: str = "",
    sep: str = "\t",
    encoding: str = "utf8",
    debug: bool = True,
    output_flag: bool = True,
    color: Literal["red", "blue", "green"] | None = None,
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
    color: str,
    on_color: str | None = None,
    attrs: Iterable[str] | None = None,
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
    color: Literal["red", "blue", "green"] | None = None,
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
    color: Literal["red", "blue", "green"] | None = None,
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


def norm_line(line: T) -> T:
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


def read_file(  # noqa: C901, PLR0912
    input_: str | Path | IO | None = sys.stdin.buffer,
    *,
    sep: str = "\t",
    encoding: str = "utf-8",
    maxsplit: int = -1,
    errors: str = "strict",
    decode_error_tolerance_count: int = 10,
    skip_header: bool = False,
    tqdm: str | bool | None = None,
    total: int | None = None,
    skip_notexists: bool = False,
    filter_func: Callable[[list[str]], bool] | None = None,
    norm: bool = True,  # 是否替换掉bad char， 如chr(160) 不间断空格
) -> Generator[list[str], None, None]:
    """Read the file line by line with a specified encoding and return iterator of list after splitting by sep.

    input_: file name/path or io; excel时，返回的每一列都是str
    """
    if isinstance(input_, (str, Path)) and skip_notexists and not os.path.exists(input_):
        return

    if isinstance(input_, str) and input_.endswith(".xlsx"):
        df = pd.read_excel(input_, dtype=str)
        it = df.itertuples(index=False)
        if norm:
            it = (tuple(remove_invalid_char(cell) if isinstance(cell, str) else cell for cell in row) for row in it)

        it = (tuple(cell if is_valid_value(cell) else None for cell in row) for row in it)
        it = (tuple(cell.strip() if isinstance(cell, str) else cell for cell in row) for row in it)

        yield from tqdm_.tqdm(it, total=len(df))
        return

    if isinstance(input_, (str, Path)) and not is_large_file(input_):
        with open(input_, encoding=encoding) as fd:
            total = sum(1 for _ in fd)

    if input_ is None:
        input_ = sys.stdin.buffer

    if tqdm is None and sys.stderr.isatty():
        tqdm = str(f"proc file {input_}") if isinstance(input_, (str, Path)) else True

    cm = open(input_, "rb") if isinstance(input_, (str, Path)) else contextlib.nullcontext(input_)

    with cm as input_:
        if skip_header:
            input_ = funcy.rest(input_)  # type:ignore  # noqa: PLW2901
        if tqdm:
            input_ = tqdm_.tqdm(input_, total=total, desc=tqdm if isinstance(tqdm, str) else None)

        for i, line in enumerate(input_):  # type:ignore
            if not isinstance(line, str):
                try:
                    uline: str = line.decode(encoding, errors=errors)  # type:ignore
                except UnicodeDecodeError:
                    xerr(f"line decode failed! #{i}:[{line[:120] if line else None}]")
                    decode_error_tolerance_count -= 1
                    if decode_error_tolerance_count < 0:
                        raise
                    else:
                        continue
            else:
                uline = line

            ll = split_str(uline, sep=sep, maxsplit=maxsplit)
            if norm:
                ll = funcy.lmap(remove_invalid_char, ll)

            if filter_func is not None and not filter_func(ll):
                continue

            yield ll


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


def write_file_new(filepath: str, mode: str = "w+", suffix: str = "", **kwargs):
    """返回自动关闭的文件对象"""
    if suffix:
        filepath = new_filename(filepath, suffix=suffix)
    return AutoClosingFile(filepath, mode, **kwargs)


def read_kv(
    input_: str | Path | IO | None = sys.stdin.buffer,
    key: KeyType = 0,
    value: KeyType | None = None,
    filter: Callable | None = None,
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
    ofname_key: KeyType = 0,
    mode: str = "a+",
) -> tuple[list[list[Any]], IO]:
    """read file and filter by key, return list of remain items"""
    if not ofname and ofname_suffix:
        ofname = new_filename(fname, suffix=ofname_suffix)

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
    if callable(f):
        return f
    if isinstance(f, int):
        return itemgetter(f)
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
) -> Generator:
    """read file line by line and split by sep and group by key, return like itertools.groupby"""
    key_func = make_key_func(key)
    f = read_file(
        input_,
        sep=sep,
        encoding=encoding,
        maxsplit=maxsplit,
        decode_error_tolerance_count=decode_error_tolerance_count,
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
    md5 = hashlib.md5()  # noqa: S324
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
    return "".join(c for c in unicodedata.normalize("NFD", s) if unicodedata.category(c) != "Mn")


def aggregate_by_key(
    fname: str | None = None,
    key: KeyType = 0,
    value: KeyType = 1,
    unpack: bool = False,
    with_len: bool = False,
    *args,
    **kwargs,
):
    """指定key，聚合value

    upack为True的话分成多列
    """
    for k, vs in read_kv(fname, *args, value_accumulate_func=None, key=key, value=value, **kwargs).items():
        res = [k, len(vs)] if with_len else [k]
        res = [*res, *vs] if unpack else [*res, vs]
        xprint(*res)


if __name__ == "__main__":
    import fire

    fire.Fire()
