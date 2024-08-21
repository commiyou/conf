#!/usr/bin/env python3
"""python3 utils"""

import string
import collections
import contextlib
import dataclasses
import time
import pandas as pd
import datetime
import io
import itertools
import json
import locale
import os
import random
import re
import sys
from collections.abc import Mapping, Sequence
from collections.abc import Set as AbstractSet
from contextlib import ExitStack
from functools import partial
from operator import itemgetter
from pathlib import Path
from typing import IO, Any, Callable, Iterable, Iterator

import funcy
import tqdm as tqdm_
from traceback_with_variables import activate_by_import  # noqa

if locale.getencoding() != "UTF-8":
    print(f"system default locale {locale.getlocale()}", file=sys.stderr)
    # The open function in Python 3, if the encoding parameter is not specified,
    # defaults to the encoding of the system locale. It’s not utf8 on the Hadoop cluster.
    locale.setlocale(locale.LC_ALL, "en_US.utf-8")
    print(f"system locale changed to {locale.getlocale()}", file=sys.stderr)

sys.stdin = io.TextIOWrapper(sys.stdin.buffer, encoding="utf-8")
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

CH_PUNCTIONS = "•·°！？｡。＂＃＄％＆＇（）＊＋，－／：；＜＝＞＠［＼］＾＿｀｛｜｝～｟｠｢｣､、〃》「」『』【】〔〕〖〗〘〙〚〛〜〝〞〟〰〾〿–—‘’‛“”„‟…‧﹏."


class MetaChar(type):
    """for type hint"""

    def __instancecheck__(cls, instance: str):
        """check is cahr"""
        return isinstance(instance, str) and len(instance) == 1


class Char(str, metaclass=MetaChar):
    """for type hint"""

    __slots__ = ()


def _make_bytes(value: object, encoding: str = "utf8") -> bytes:
    r"""Set/Map/Sequence to json str, then to bytes.

    >>> _make_bytes({1, 2, 3})
    b'[1, 2, 3]'
    >>> _make_bytes((1, 2, 3))
    b'[1, 2, 3]'
    >>> _make_bytes("你好")
    b'\xe4\xbd\xa0\xe5\xa5\xbd'
    """
    if isinstance(value, str):
        value = value.encode(encoding)
    elif isinstance(value, AbstractSet):
        value = dump_json(sorted(value))
    elif isinstance(value, (Sequence, Mapping)):
        value = dump_json(value)
    if isinstance(value, bytes):
        return value
    return str(value).encode(encoding)


def xprint(
    *values: object,
    suffix: str = "",
    sep: str = "\t",
    flush: bool = True,
    file: "IO|None" = None,
    encoding: str = "utf8",
) -> None:
    """print with default sep and suffix and encoding"""
    if file is None:
        file = sys.stdout
    end = suffix + "\n"
    values = [_make_bytes(value, encoding) for value in values]
    sep_bytes = sep.encode(encoding)
    end_bytes = end.encode(encoding)
    file.buffer.write(sep_bytes.join(values) + end_bytes)
    if flush:
        file.flush()


def xerr(
    *values: object,
    suffix: str = "",
    sep: str = "\t",
    encoding: str = "utf8",
    debug=True,
) -> None:
    """print to stderr with default sep and suffix and encoding"""
    if not debug:
        return
    xprint(
        *values,
        suffix=suffix,
        sep=sep,
        file=sys.stderr,  # type:ignore
        encoding="unicode_escape" if is_mr() else encoding,
    )


def in_debug():
    v = os.environ.get("DEBUG")
    if v is None or v == "0":
        return False
    return True


def xdebug(
    *values: object,
    suffix: str = "",
    sep: str = "\t",
    encoding: str = "utf8",
) -> None:
    if not in_debug():
        return
    xerr(
        *values,
        suffix=suffix,
        sep=sep,
        encoding="unicode_escape" if is_mr() else encoding,
    )


def is_chinese_char(uchar: Char) -> bool:
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
    if uchar >= "\u4e00" and uchar <= "\u9fa5":
        return True
    return False


def contain_chinese(s: str) -> bool:
    """是否包含中文字符，标点符号不算"""
    return any(is_chinese_char(ch) for ch in s)  # noqa: W291


def is_chinese_or_alnum(uchar: Char) -> bool:
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
    if uchar >= "\u4e00" and uchar <= "\u9fa5":
        return True
    return False


def norm_line(line: str) -> str:
    """使用正则表达式替换多个空白符为单个空格, 去前后空白符

    >>> norm_line("1  2\\n")
    '1 2'
    """
    return re.sub(r"\s+", " ", line).strip()


trim_term = norm_line
trim_line = norm_line


def nterm(
    term: str,
    *,
    lower: bool = True,
    trim_whitespace: bool = False,
    remove_whitespace: bool = True,
    remove_punctions: bool = True,
    strict: bool = False,
    stop_chars: set[Char] | None = None,
) -> str:
    """
    新版本norm_term， 默认小写、去空白符、去标点

    >>> nterm("手电筒‘ 0")
    '手电筒0'
    >>> nterm("手电筒‘ 0", stop_chars={"0"})
    '手电筒'
    """

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
    stop_chars: set[Char] | None = None,
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


def is_large_file(file_path, size_limit=1024 * 1024 * 400):
    # 默认大小限制为300MB
    file_size = os.path.getsize(file_path)
    return file_size > size_limit


def read_file(
    input_: str | Path | IO | None = sys.stdin.buffer,
    *,
    sep: str = "\t",
    encoding: str = "utf-8",
    maxsplit: int = -1,
    errors="strict",
    decode_error_tolerance_count: int = 10,
    skip_header: bool = False,
    tqdm: str | bool | None = None,
    total: int | None = None,
    skip_notexists: bool = False,
    filter_func: Callable[[list[str]], bool] | None = None,
) -> Iterator[list[str]]:
    """Read the file line by line with a specified encoding and return iterator of list after splitting by sep.

    input_: file name/path or io; excel时，返回的每一列都是str
    """
    if isinstance(input_, (str, Path)) and skip_notexists:
        if not os.path.exists(input_):
            return iter([])

    if isinstance(input_, str) and input_.endswith(".xlsx"):
        df = pd.read_excel(input_, dtype=str)
        yield from (row for row in df.itertuples(index=False))
        return

    if isinstance(input_, (str, Path)):
        if not is_large_file(input_):
            with open(input_, "r") as fd:
                total = sum(1 for _ in fd)

    if input_ is None:
        input_ = sys.stdin.buffer

    if tqdm is None and sys.stderr.isatty():
        if isinstance(input_, (str, Path)):
            tqdm = str(f"proc file {input_}")
        else:
            tqdm = True

    if isinstance(input_, (str, Path)):
        cm = open(input_, "rb")
    else:
        cm = contextlib.nullcontext(input_)

    with cm as input_:
        if skip_header:
            input_ = funcy.rest(input_)  # type:ignore
        if tqdm:
            input_ = tqdm_.tqdm(
                input_, total=total, desc=tqdm if isinstance(tqdm, str) else None
            )

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
            if filter_func is not None and not filter_func(ll):
                continue
            yield ll


def make_key_func(
    f: int | slice | Sequence | Mapping | AbstractSet | Callable[..., Any],
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
        return lambda x: itemgetter(f)(x)
    if isinstance(f, slice):
        return lambda x: tuple(itemgetter(f)(x))
    if isinstance(f, Sequence):
        return lambda x: tuple(x[i] for i in f)
    if isinstance(f, Mapping):
        return f.__getitem__
    if isinstance(f, AbstractSet):
        return f.__contains__
    raise TypeError(f"Can't make a func from {f.__class__.__name__}")


def group_file_by_key(
    input_: str | Path | IO | None = sys.stdin.buffer,
    *,
    key: Callable[..., Any] | Sequence[int] | AbstractSet | Mapping | slice | int = 0,
    sep: str = "\t",
    encoding: str = "utf-8",
    maxsplit: int = -1,
    decode_error_tolerance_count: int = 10,
) -> Iterator:
    """read file line by line and split by sep and group by key, return like itertools.groupby"""
    key_func = make_key_func(key)
    f = read_file(
        input_,
        sep=sep,
        encoding=encoding,
        maxsplit=maxsplit,
        decode_error_tolerance_count=decode_error_tolerance_count,
    )

    for key, lls in itertools.groupby(f, key=key_func):
        yield key, lls


def list_to_dict(
    lls,
    key=lambda ll: ll[0],
    value=lambda ll: ll[1],
    value_accumulate=lambda value_list: value_list[0],
    filter=None,
    decode_error_tolerance_count=3,
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
        if dataclasses.is_dataclass(o):
            return dataclasses.asdict(o)
        return json.JSONEncoder.default(self, o)


def dump_json(obj: object, indent: int | None = None) -> str:
    """dump json into str, 支持set、dataclass"""
    return json.dumps(obj, ensure_ascii=False, indent=indent, cls=JsonCustomEncoder)


def xprint_json(obj: object) -> None:
    """格式化json"""
    xprint(json.dumps(obj, ensure_ascii=False, indent=4, cls=JsonCustomEncoder))


def safe_divide(
    p1: float, p2: float, *, digits: int = 2, percentage: bool = False
) -> str:
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


def safe_diff(
    p1: float | str, p2: float | str, *, digits: int = 2, percentage: bool = True
) -> str | float:
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


class RedirectStdoutToFile(contextlib.ContextDecorator):
    """redirect_stdout_to_file

    >>> with redirect_stdout_to_file("test", "w"):
    ...     print(123)
    """

    def __init__(
        self, fname: str | Path | None, mode: str = "w", tpl: str | None = None
    ) -> None:
        """file name and write mode"""
        if tpl is None:
            tpl = "{}"
        self.fname = tpl.format(fname) if fname else None
        self.mode = mode

    def __enter__(self) -> None:
        """enter"""
        if self.fname is not None:
            self.file = open(self.fname, self.mode)
        else:
            self.file = sys.stdout

        self.old_stdout = sys.stdout
        sys.stdout = self.file
        return self.file

    def __exit__(self, *exc: object):
        """exit"""
        sys.stdout = self.old_stdout
        self.file.close()


redirect_stdout_to_file = RedirectStdoutToFile


class RedirectStderrToFile(contextlib.ContextDecorator):
    """redirect_stderr_to_file

    >>> with redirect_stderr_to_file("test", "w"):
    ...     print(123, file=sys.stderr)
    """

    def __init__(self, fname: str | None, mode: str = "w", tpl: str | None = None):
        """file name and write mode"""
        if tpl is None:
            tpl = "{}"
        self.fname = tpl.format(fname) if fname else None
        self.mode = mode

    def __enter__(self):
        """enter"""
        if self.fname is not None:
            self.file = open(self.fname, self.mode)
        else:
            self.file = sys.stderr

        self.old_stderr = sys.stderr
        sys.stderr = self.file
        return self.file

    def __exit__(self, *exc: object):
        """exit"""
        sys.stderr = self.old_stderr
        self.file.close()


redirect_stderr_to_file = RedirectStderrToFile


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

    for line_no in random.choices(population=population, weights=weights, k=n):
        xprint(*data[line_no])


def timestamp(fmt: str = "%Y%m%d%H%M%S") -> str:
    """return current local timestamp"""

    now = datetime.datetime.now(tz=datetime.UTC).astimezone()
    ts = now.strftime(fmt)
    return ts


def date(ts: str | int | None = None, fmt: str = "%Y-%m-%d") -> str:
    """return current local datetime from ts"""

    if ts is None or ts == 0:
        ts = time.time()
    else:
        ts = int(ts)
    dt_object = datetime.datetime.fromtimestamp(ts)  # noqa: DTZ006
    formatted_time = dt_object.strftime(fmt)

    return formatted_time


def parallel_process_items_processes(
    inputs: Iterable,
    proc_func: Callable,
    *,
    process_cnt: int | None = None,
    tqdm: str | bool = True,
    total: int | None = None,
):
    """返回的是proc_func的输出"""
    xerr(process_cnt)
    if process_cnt == 1:
        yield from iter(proc_func(ll) for ll in tqdm_.tqdm(inputs))
        return

    if not total and isinstance(inputs, (list, tuple, set, dict)):
        total = len(inputs)

    from multiprocessing import Pool

    with Pool(processes=process_cnt) as pool:
        yield from tqdm_.tqdm(
            pool.imap(proc_func, inputs),
            total=total,
            desc=tqdm if isinstance(tqdm, str) else None,
        )


def parallel_process_items_threads(
    inputs: str | Iterable,
    proc_func: Callable,
    *,
    thread_cnt: int = 4,
    tqdm: str | bool = True,
    total: int | None = None,
) -> Iterator:
    """多线程跑函数proc_func"""
    if isinstance(inputs, str):  # noqa: SIM108
        _inputs = read_file(inputs, tqdm=tqdm)
        if not is_large_file(inputs):
            with open(inputs, "r") as fd:
                total = sum(1 for line in fd)

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


def parallel_run_helper(func, ll: list, *args, **kws):
    ret = func(*args, **kws)
    return ll, ret


def remove_file_suffix(fname: str):
    if fname.endswith((".tsv", ".xlsx", ".txt", ".dat", ".data", ".json")):
        return Path(f"{fname}").stem
    else:
        return fname


def join_with_delim(s1: str, s2: str, delim: str = ".") -> str:
    """以delim拼接s1和s2

    >>> join_with_delim("1","2",".")
    '1.2'
    >>> join_with_delim("1",".tsv",".")
    '1.tsv'
    """
    s1 = s1.removesuffix(delim)
    s2 = s2.removeprefix(delim)
    if s1 and s2:
        return f"{s1}{delim}{s2}"
    else:
        return f"{s1}{s2}"


def new_filename(fpath: str | None, prefix: str = "", suffix: str = ""):
    """新文件名
    >>> new_filename("1.tsv", "2", "3" )
    '2.1.3.tsv'
    >>> new_filename("1.tsv", "2", "3.xlsx" )
    '2.1.3.xlsx'
    >>> new_filename("1", "2", "3" )
    '2.1.3'
    >>> new_filename("1", "", "3" )
    '1.3'
    >>> new_filename("1", "2" )
    '2.1'
    >>> new_filename("./data1", suffix="2.tsv" )
    './data1.2.tsv'
    """
    if fpath is None:
        return None
    if fpath.endswith((".tsv", ".xlsx", ".txt", ".dat", ".data", ".json")):
        curr_suffix = Path(fpath).suffix
    else:
        curr_suffix = ""

    if suffix.endswith((".tsv", ".xlsx", ".txt", ".dat", ".data", ".json")):
        curr_suffix = ""

    fname = os.path.basename(fpath)
    dname = os.path.dirname(fpath)

    ret = join_with_delim(prefix, remove_file_suffix(fname), ".")
    ret = join_with_delim(ret, suffix, ".")
    ret = join_with_delim(ret, curr_suffix, ".")
    ret = os.path.join(dname, ret)
    # return f"{prefix}{remove_file_suffix(fname)}{suffix}{curr_suffix}"
    return ret


def doctest() -> None:
    """test"""
    import doctest

    doctest.testmod(verbose=True)


if __name__ == "__main__":
    import fire

    fire.Fire()
