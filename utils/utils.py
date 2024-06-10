#!/usr/bin/env python3
"""python3 utils"""

import collections
import contextlib
import dataclasses
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


def xerr(*values: object, suffix: str = "", sep: str = "\t", encoding: str = "utf8") -> None:
    """print to stderr with default sep and suffix and encoding"""
    xprint(
        *values,
        suffix=suffix,
        sep=sep,
        file=sys.stderr,  # type:ignore
        encoding="unicode_escape" if is_mr() else encoding,
    )


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


def norm_term(term: str, *, strict: bool = True, stop_chars: set[Char] | None = None) -> str:
    """Convert the term to lowercase and remove whitespace characters

    strict: just keep chinese/alnum chars(no punctions/emojis)
    stop_chars : stop chars to remove

    >>> norm_term("手电筒‘ 0")
    '手电筒0'
    >>> norm_term("手电筒‘ 0", stop_chars={"0"})
    '手电筒'
    """
    ret = "".join(term.lower().split())
    if strict:
        ret = "".join(filter(is_chinese_or_alnum, ret))  # type:ignore

    if stop_chars:
        ret = "".join(ch for ch in ret if ch not in stop_chars)
    return ret


def split_str(s: str, sep: str = "\t", maxsplit: int = -1) -> list[str]:
    """split Unicode string and return list"""
    return funcy.lmap(lambda x: x.strip(), s.rstrip("\n").split(sep, maxsplit))


def read_file(
    input_: str | Path | IO | None = sys.stdin.buffer,
    *,
    sep: str = "\t",
    encoding: str = "utf-8",
    maxsplit: int = -1,
    decode_error_tolerance_count: int = 10,
    skip_header: bool = False,
    tqdm: str | bool = False,
    total: int | None = None,
) -> Iterator[list[str]]:
    """Read the file line by line with a specified encoding and return iterator of list after splitting by sep.

    input_: file name/path or io
    """
    if input_ is None:
        input_ = sys.stdin.buffer
    with ExitStack() as stack:
        if isinstance(input_, str):
            input_ = Path(input_)

        if isinstance(input_, Path):
            input_ = stack.enter_context(input_.open("rb"))

        if skip_header:
            input_ = funcy.rest(input_)  # type:ignore

        for i, line in enumerate(
            tqdm_.tqdm(input_, total=total, desc=tqdm if isinstance(tqdm, str) else None) if tqdm else input_
        ):  # type:ignore
            if not isinstance(line, str):
                try:
                    uline: str = line.decode(encoding)  # type:ignore
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
    skip_header=False,
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


def load_files(*files, map_func=None, sep="\t", encoding="utf8"):
    """load files"""
    if map_func is None:
        map_func = partial(split_str, sep=sep)
    for fname in files:
        for line in open(fname, encoding=encoding):
            yield map_func(line)


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
    'n/a'
    >>> safe_diff(3, 10)
    '-70%'
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

    def __init__(self, fname: str | Path | None, mode: str = "w", tpl: str | None = None) -> None:
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
    query_idx: int = 0,
    pv_idx: int = 1,
    skip_header: bool = False,
) -> None:
    """weighted sample with replacement"""

    population = []
    weights = []
    bad_pv_cnt = 0
    for ll in read_file(fname, skip_header=skip_header):
        q = ll[query_idx]
        if len(ll) > 1:
            try:
                pv = int(ll[pv_idx])
            except ValueError:
                bad_pv_cnt += 1
                continue
        else:
            pv = 1
        population.append(q)
        weights.append(pv)
    xerr(f"skip bad line for pv, cnt: {bad_pv_cnt}")

    for q in random.choices(population=population, weights=weights, k=n):
        xprint(q)


def timestamp(fmt: str = "%Y%m%d%H%M%S") -> str:
    """return current local timestamp"""

    now = datetime.datetime.now(tz=datetime.UTC).astimezone()
    ts = now.strftime(fmt)
    return ts


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
    else:
        _inputs = tqdm_.tqdm(inputs, total=total) if tqdm else inputs

    from multiprocessing.dummy import Pool

    with Pool(thread_cnt) as pool:
        imap_it = pool.imap(_inputs, proc_func)

        yield from imap_it


def doctest() -> None:
    """test"""
    os.system("pytest --doctest-modules")


if __name__ == "__main__":
    import fire

    fire.Fire()
