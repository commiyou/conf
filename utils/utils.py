#! coding:utf8
"""
youbin's utils

test case: python -m doctest -v utils.py

python2 support
"""
from __future__ import unicode_literals

import __builtin__
import base64
import collections
import datetime
import hashlib
import heapq
import inspect
import itertools
import json
import logging
import logging.handlers
import operator
import os
import re
import string
import subprocess
import sys
import tempfile
import threading
import time
import traceback
import types
import urllib2
import warnings
from functools import wraps
from repr import Repr

__version__ = '0.1.0'

###########################################
# ======> internal
###########################################
# {

PY2 = sys.version_info[0] == 2
PY3 = sys.version_info[0] == 3

if PY3:
    text_type = str
    string_types = str,
else:
    text_type = unicode
    string_types = basestring,

# logging
LOG_FMT = ('[%(asctime)s][%(levelname)s:%(name)s] %(filename)s:%(lineno)d '
           '%(funcName)s:  %(message)s')
LOG_DATEFMT = '%Y-%m-%d %H:%M:%S'
formatter = logging.Formatter(LOG_FMT, LOG_DATEFMT)

no_pad = '__no__pad__'
_printable = set(string.printable)
_decode_encodings = ('utf8', 'gb18030')

if os.getenv("mapred_job_name", None) is not None:
    _output_encoding = "unicode-escape"
elif sys.stdout.isatty():
    _output_encoding = sys.stdin.encoding
else:
    _output_encoding = 'utf8'
# }


###########################################
# ======> hadoop
###########################################
# {
def is_mrjob():
    """
    是否是在hadoop集群上
    """
    return os.getenv("mapred_job_name", None) is not None


def mif(default=None):
    """
    取得map_input_file
    """
    return os.getenv("map_input_file", default)


# }


def set_output_encoding(encoding):
    global _output_encoding
    _output_encoding = encoding


###########################################
# ======> string
###########################################
# {
def is_chinese_char(uchar):
    """ 传入unicode 判断是不是汉字 """
    if uchar in _printable:
        return True
    if uchar in u"，。“”《》？！%（）【】":
        return True
    if uchar >= u'\u4e00' and uchar <= u'\u9fa5':
        return True
    else:
        return False


def clean_illegal_str(ustr):
    """
    清理不可打印字符
    """
    return "".join(filter(lambda x: is_chinese_char(x), ustr)).strip()


def is_alnum(s, extra=string.punctuation):
    """
    判断是否是字母数字标点

    >>> is_alnum(u"你好")
    False
    >>> is_alnum("你好")
    False
    >>> is_alnum(u"123你好")
    False
    >>> is_alnum("123你好")
    False
    >>> is_alnum("123ab")
    True
    >>> is_alnum("123ab+++")
    True
    """
    if re.match(r'^[\w ' + extra + r']+$', s):
        return True
    return False


def split_str(s, delim='\t', encoding='utf8', errors='strict', maxsplit=-1, columns=None):
    if isinstance(s, text_type):
        us = s
    else:
        us = s.decode(encoding, errors)

    result = map(lambda x: x.strip(), us.rstrip('\n').split(delim, maxsplit))
    if columns:
        if isinstance(columns, string_types):
            if ',' in columns:
                columns = split_str(columns, delim=',')
            else:
                columns = split_str(columns, delim=' ')
        result = Storage(zip(columns, result))
    return result


def dumpu(obj, indent=None):
    """
    dump obj to unicode, obj must be unicode
    """
    string = json.dumps(obj, ensure_ascii=False, indent=indent)
    return string


def dumps(obj, encoding='utf8', indent=None, errors="strict"):
    """
    dump obj to string, obj must be unicode
    """
    string = dumpu(obj, indent)
    if encoding is not None:
        return string.encode(encoding, errors=errors)
    else:
        return string


def loads(s, encoding='utf8', errors="strict"):
    """
    loads obj to json
    """
    if isinstance(s, text_type):
        obj = json.loads(s)
    else:
        obj = json.loads(s.decode(encoding, errors=errors))
    return obj


def format_args(*args, **kws):
    """
    return utf8 str of args joined by delim, if encoding is None, return unicode

    flatten, 是否展开list/tuple
    """
    encoding = kws.get("encoding", 'utf8')
    errors = kws.get('errors', 'strict')
    suffix = kws.get('suffix', "")
    delim = kws.get("delim", "\t")
    flatten = kws.get("flatten", True)
    tmp = []

    def _get_obj_str(obj):
        if isinstance(obj, text_type):
            return obj
        elif type(obj).__str__ is not object.__str__:
            return str(obj).decode('utf8')
        else:
            return dumpu(obj)

    for arg in args:
        if flatten and isinstance(arg, (list, tuple)):
            tmp += map(_get_obj_str, arg)
        else:
            tmp.append(_get_obj_str(arg))

    args = tmp
    us = "%s%s" % (delim.join(args), suffix)
    if encoding:
        return us.encode(encoding, errors=errors)
    else:
        return us


def print_args(*args, **kws):
    """
    return str of args joined by delim
    """
    fd = kws.get("fd", sys.stdout)
    print >> fd, format_args(*args, **kws)


# }

###########################################
# ======> file
###########################################
# {


def absname(path):
    path = os.path.abspath(os.path.expanduser(path))
    return path


def realpath(path):
    path = os.path.relpath(os.path.expanduser(path))
    return path


def basename(path):
    # path = absname(path)
    return os.path.basename(path)


def dirname(path):
    if path.startswith('.') or path.startswith('~'):
        path = absname(path)
    return os.path.dirname(path)


def isabs(path):
    path = os.path.expanduser(path)
    return os.path.isabs(path)


# https://stackoverflow.com/questions/3718657/how-to-properly-determine-current-script-directory/22881871#22881871
def get_main_file(follow_symlinks=False):
    """
    获取__main__所在文件, 如果是在ipython中会raise exception
    """
    if getattr(sys, 'frozen', False):  # py2exe, PyInstaller, cx_Freeze
        path = os.path.abspath(sys.executable)
    else:
        import __main__
        if not hasattr(__main__, "__file__"):
            raise IOError('Can not locate "__main__" file')
        # path = inspect.getabsfile(get_main_fileC)
        path = absname(__main__.__file__)
    if follow_symlinks:
        path = os.path.realpath(path)
    return path


def get_main_dir(follow_symlinks=False):
    """
    获取__main__文件所在目录, 如果是在ipython中会raise exception
    """
    path = get_main_file(follow_symlinks)
    return dirname(path)


def split_file(fd=sys.stdin,
               delim='\t',
               encoding='utf8',
               maxsplit=-1,
               errors='strict',
               index=False,
               max_failures_cnt=5):
    if isinstance(fd, string_types):
        fd = open(fd)

    for i, line in enumerate(fd):
        try:
            ll = split_str(line, delim=delim, encoding=encoding, maxsplit=maxsplit, errors=errors)
        except Exception as e:
            warnings.warn(
                'fd<%s> read line error.\n line > %r\n%s' % (fd.name, line, e), stacklevel=2)
            max_failures_cnt -= 1
            if max_failures_cnt <= 0:
                raise IOError("fd read line error too much!")

            continue
        if index:
            yield i, ll
        else:
            yield ll


def groupbyN(seq, N):
    """
    按照前N field groupby
    """

    def _key(x):
        k = x[:N]
        if N == 1:
            return k[0]
        else:
            return k

    return itertools.groupby(seq, key=_key)


def groupbyN_file(N, fd=sys.stdin, delim='\t', encoding='utf8', maxsplit=-1, errors="strict"):
    """
    itertools.groupby first N columns as key, and lists as lines split by delim
    if N equals to 1, key will be first column, else will be tuple of first N columns
    """
    if isinstance(fd, string_types):
        fd = open(fd)

    return groupbyN(
        split_file(fd=fd, delim=delim, maxsplit=maxsplit, encoding=encoding, errors=errors), N)


# }


###########################################
#             itertools
###########################################
# {
def peek(seq):
    """ Retrieve the next element of a sequence

    Returns the first element and an iterable equivalent to the original
    sequence, still having the element retrieved.

    >>> seq = [0, 1, 2, 3, 4]
    >>> first, seq = peek(seq)
    >>> first
    0
    >>> list(seq)
    [0, 1, 2, 3, 4]
    """
    iterator = iter(seq)
    item = next(iterator)
    return item, itertools.chain([item], iterator)


def chunks(n, seq):
    """ Partition all elements of sequence into tuples of length at most n

    The final tuple may be shorter to accommodate extra elements.

    >>> list(chunks(2, [1, 2, 3, 4]))
    [(1, 2), (3, 4)]

    >>> list(chunks(2, [1, 2, 3, 4, 5]))
    [(1, 2), (3, 4), (5,)]

    """
    args = [iter(seq)] * n
    it = itertools.izip_longest(*args, fillvalue=no_pad)
    try:
        prev = next(it)
    except StopIteration:
        return
    for item in it:
        yield prev
        prev = item
    if prev[-1] is no_pad:
        try:
            # If seq defines __len__, then
            # we can quickly calculate where no_pad starts
            yield prev[:len(seq) % n]
        except TypeError:
            # Get first index of no_pad without using .index()
            # https://github.com/pytoolz/toolz/issues/387
            # Binary search from CPython's bisect module,
            # modified for identity testing.
            lo, hi = 0, n
            while lo < hi:
                mid = (lo + hi) // 2
                if prev[mid] is no_pad:
                    hi = mid
                else:
                    lo = mid + 1
            yield prev[:lo]
    else:
        yield prev


def sliding_window(n, seq):
    """ A sequence of overlapping subsequences

    >>> list(sliding_window(2, [1, 2, 3, 4]))
    [(1, 2), (2, 3), (3, 4)]

    This function creates a sliding window suitable for transformations like
    sliding means / smoothing

    >>> mean = lambda seq: float(sum(seq)) / len(seq)
    >>> list(map(mean, sliding_window(2, [1, 2, 3, 4])))
    [1.5, 2.5, 3.5]
    """
    return zip(*(collections.deque(itertools.islice(it, i), 0) or it
                 for i, it in enumerate(itertools.tee(seq, n))))


def take_nth(n, seq):
    """ Every nth item in seq

    >>> list(take_nth(2, [10, 20, 30, 40, 50]))
    [10, 30, 50]
    """
    return itertools.islice(seq, 0, None, n)


def tail(n, seq):
    """ The last n elements of a sequence

    >>> tail(2, [10, 20, 30, 40, 50])
    [40, 50]

    See Also:
        drop
        take
    """
    try:
        return seq[-n:]
    except (TypeError, KeyError):
        return tuple(collections.deque(seq, n))


def _getter(index):
    if isinstance(index, list):
        if len(index) == 1:
            index = index[0]
            return lambda x: (x[index], )
        elif index:
            return operator.itemgetter(*index)
        else:
            return lambda x: ()
    else:
        return operator.itemgetter(index)


def topk(k, seq, key=None):
    """ Find the k largest elements of a sequence

    Operates lazily in ``n*log(k)`` time

    >>> topk(2, [1, 100, 10, 1000])
    (1000, 100)

    Use a key function to change sorted order

    >>> topk(2, [b'Alice', b'Bob', b'Charlie', b'Dan'], key=len)
    ('Charlie', 'Alice')

    See also:
        heapq.nlargest
    """
    if key is not None and not callable(key):
        key = _getter(key)
    return tuple(heapq.nlargest(k, seq, key=key))


def uniq_iter(seq):
    """
    unique iter while reserving order
    """
    seen = set()
    seen_add = seen.add
    return [x for x in seq if not (x in seen or seen_add(x))]


def filter_iter(iterator, fn):
    """
    if fn(item) return true, keep item
    """
    for x in iterator:
        if fn(x):
            yield x


# port of https://docs.python.org/dev/library/itertools.html#itertools-recipes
def partition(pred, iterable):
    """Use a predicate to partition entries into false entries and true entries
    >>> x, y = partition(lambda x: x % 2, range(10))
    >>> list(x)
    [0, 2, 4, 6, 8]
    >>> list(y)
    [1, 3, 5, 7, 9]
    """
    t1, t2 = itertools.tee(iterable)
    return itertools.ifilterfalse(pred, t1), itertools.ifilter(pred, t2)


# http://docs.python.org/2/library/itertools.html#recipes
def roundrobin(*iterables):
    """轮流拣取

    >>> list(roundrobin(b'ABC', b'D', b'EF'))
    ['A', 'D', 'E', 'B', 'F', 'C']
    """
    # Recipe credited to George Sakkis
    pending = len(iterables)
    nexts = itertools.cycle(iter(it).next for it in iterables)
    while pending:
        try:
            for next in nexts:
                yield next()
        except StopIteration:
            pending -= 1
            nexts = itertools.cycle(itertools.islice(nexts, pending))


# }

###########################################
#             html
###########################################
# {
try:
    from bs4 import BeautifulSoup
    from bs4 import Comment
    from bs4 import CData
    from bs4 import Declaration
    from bs4 import Doctype
    from bs4 import ProcessingInstruction
except:
    pass
else:
    _ignore_html_tags = ("head", "script", "meta", "title", "link", "style")
    _ignore_html_text_classes = (Comment, CData, Declaration, Doctype, ProcessingInstruction)

    def clean_html(html):
        """
        清理html的"head", "script", "meta", "title", "link", "style" 字段, 返回bs4字段
        """
        if not isinstance(html, BeautifulSoup):
            soup = BeautifulSoup(html, 'html.parser')
        else:
            soup = html
        [
            x.append('\n')
            for x in soup(lambda x: hasattr(x, "name") and x.name in ("p", "h1", "h2", "h3", "h4"
                                                                      "br", "center", "hr"))
        ]
        # clean comments
        for node in soup.find_all(string=lambda text: isinstance(text, _ignore_html_text_classes)):
            node.extract()

        for node in soup(_ignore_html_tags):
            node.extract()
        return soup

    def get_text(html, clean=True):
        """
        获得html 的 text, html为soup or
        """
        if not isinstance(html, BeautifulSoup):
            soup = BeautifulSoup(html, 'html.parser')
        else:
            soup = html
        if clean:
            text = clean_html(soup).get_text()
        else:
            [
                x.append('\n') for x in soup(
                    lambda x: hasattr(x, "name") and x.name in ("p", "h1", "h2", "h3", "h4"
                                                                "br", "center", "hr"))
            ]
            text = soup.get_text()
        return text


# }
###########################################
#             utils
###########################################
# {
class Cache(set):
    """类似Set，但使用in 操作符时会自动将key插入

        >>> c = Cache()
        >>> 1 in c
        False
        >>> 1 in c
        True
    """

    def __contains__(self, key):
        if not set.__contains__(self, key):
            self.add(key)
            return False
        return True


class Storage(dict):
    """
    A Storage object is like a dictionary except `obj.foo` can be used
    in addition to `obj['foo']`.
        >>> o = storage(a=1)
        >>> o.a
        1
        >>> o['a']
        1
        >>> o.a = 2
        >>> o['a']
        2
        >>> del o.a
        >>> o.a
        Traceback (most recent call last):
            ...
        AttributeError: 'a'
    """

    def __getattr__(self, key):
        try:
            return self[key]
        except KeyError as k:
            raise AttributeError(k)

    def __setattr__(self, key, value):
        self[key] = value

    def __delattr__(self, key):
        try:
            del self[key]
        except KeyError as k:
            raise AttributeError(k)

    def __repr__(self):
        return '<Storage ' + dict.__repr__(self) + '>'


storage = Storage


class Enum(Storage):
    """
    >>> types = Enum('one', 'two')
    >>> types.one == 0
    True
    >>> 'one' in types
    True
    """

    def __init__(self, *a):
        self.name = tuple(a)
        Storage.__init__(self, ((e, i) for i, e in enumerate(a)))

    def __contains__(self, item):
        if isinstance(item, int):
            return item in self.values()
        else:
            return Storage.__contains__(self, item)


class class_property(object):
    """A decorator that combines @classmethod and @property.
    http://stackoverflow.com/a/8198300/120999
    """

    def __init__(self, function):
        self.function = function

    def __get__(self, instance, cls):
        return self.function(cls)


def md5(string, encoding='utf8', errors='strict'):
    """
    get md5 of str
    """
    if isinstance(string, text_type):
        string = string.encode(encoding, errors=errors)
    m = hashlib.md5()
    m.update(string)
    return m.hexdigest()


def b64_decode(data):
    """
    decode base64
    """
    missing_padding = 4 - len(data) % 4
    if missing_padding:
        data += b'=' * missing_padding
    try:
        out = base64.decodestring(data)
        return out
    except Exception as e:
        error("bad base64 str: %r" % data)
        raise e


d64 = b64_decode


def b64_encode(data):
    """
    encode base64
    """
    return base64.b64encode(data)


e64 = b64_encode


def normalize_url(url, unquote=False):
    """
    normalize url
    """
    if not url:
        return ""
    if unquote:
        url = urllib2.unquote(url)
    url = url.split("#")[0]
    url = url.rstrip("/")
    return url


def normalize_term(term, unquote=False):
    """
    normalize term
    """
    if unquote:
        term = urllib2.unquote(term)
    term = " ".join(term.replace("", ' ').split())
    return term


class ZDX(object):
    """
    展点消 d z x

    >>> sy = ZDX(2, 1, 1)
    >>> dz = ZDX(4, 2, 4)
    >>> sy.label
    [u'show', u'click', u'charge', u'ctr2', u'cpm2', u'acp']
    >>> sy.value
    [2.0, 1.0, 1.0, 0.5, 500.0, 1.0]
    >>> dz.value
    [4.0, 2.0, 4.0, 0.5, 1000.0, 2.0]
    >>> sy.diff(dz, factor=2)
    [u'0.00%', u'0.00%', u'-50.00%', u'0.00%', u'-50.00%', u'-50.00%']

    """
    label = ['show', 'click', 'charge', 'ctr2', 'cpm2', 'acp']
    label_str = '\t'.join(label)

    def __init__(self, z=0, d=0, x=0):
        self.show = float(z)
        self.click = float(d)
        self.charge = float(x)

    def add(self, z, d, x):
        """
        """
        self.show += float(z)
        self.click += float(d)
        self.charge += float(x)

    @property
    def ctr2(self):
        """
        展现点击比率
        """
        return divide(self.click, self.show)

    @property
    def cpm2(self):
        """
        千次展现收入
        """
        return 1000 * divide(self.charge, self.show)

    @property
    def acp(self):
        """
        平均点击价格
        """
        return divide(self.charge, self.click)

    def proportion(self, z=0, d=0, x=0, reverse=False):
        """
        self 在参数dzx的占比
        """
        a = list(self)
        b = [float(z), float(d), float(x)]
        if reverse:
            a, b = b, a
        res = []
        for i, j in zip(a, b):
            res.append(divide(i, j))
        return res

    def diff(self, dzx_obj, factor=1.0):
        """
        self 与 obj 对应的diff。其中factor是self的流量系数
        """

        res = []
        for idx, (i, j) in enumerate(zip(self.value, dzx_obj.value)):
            if idx < 3:
                i = i * factor
            res.append(divide(i - j, j, percent=True))
        return res

    def __iter__(self):
        for e in [self.show, self.click, self.charge]:
            e = float(e)
            yield int(e) if e.is_integer() else e

    def __getitem__(self, key):
        return list(self)[key]

    def __setitem__(self, key, val):
        if key == 0:
            self.show = float(val)
        elif key == 1:
            self.click = float(val)
        elif key == 2:
            self.charge = float(val)
        else:
            raise IndexError('DZX len is 3!')

    def clear(self):
        self.show = 0
        self.click = 0
        self.charge = 0

    def __repr__(self):
        return '<ZDX d=%s z=%s x=%s>' % tuple(self)

    @property
    def value(self):
        value = map(lambda x: getattr(self, x), self.label)
        return value

    @property
    def str(self):
        return '\t'.join(map(str, self.value))


def divide(a, b, percent=False):
    """
    safe a/b
    """
    a = float(a)
    b = float(b)
    try:
        res = a / b
    except ZeroDivisionError:
        return float('nan')
    if percent:
        return '%.2f%%' % (res * 100)
    return round(res, 4)


def lev_dist(source, target, ignore_alnum=True):
    """
    word distance
    """
    if ignore_alnum:
        source = re.sub('[!@#$0-9a-zA-Z \-_]', '', source)
        target = re.sub('[!@#$0-9a-zA-Z \-_]', '', target)

    if source == target:
        return 0

    # Prepare a matrix
    slen, tlen = len(source), len(target)
    dist = [[0 for i in range(tlen + 1)] for x in range(slen + 1)]
    for i in xrange(slen + 1):
        dist[i][0] = i
    for j in xrange(tlen + 1):
        dist[0][j] = j

    # Counting distance, here is my function
    for i in xrange(slen):
        for j in xrange(tlen):
            cost = 0 if source[i] == target[j] else 1
            dist[i + 1][j + 1] = min(
                dist[i][j + 1] + 1,  # deletion
                dist[i + 1][j] + 1,  # insertion
                dist[i][j] + cost  # substitution
            )
    return dist[-1][-1]


# }


def detect_str_encoding(line, try_encodings=None):
    """
    check 字符串编码，检测顺序是utf8, gbk
    """
    if try_encodings is None:
        try_encodings = ("utf8", "gb18030")

    for encoding in try_encodings:
        try:
            line = line.decode(encoding)
        except:
            continue
        return encoding
    return None


def try_decode_str(line, encoding=None, errors=None, try_encodings=None):
    """
    decode str with encoding, if encoding is None, try with try_encodings
    """
    if try_encodings is None:
        try_encodings = ("utf8", "gb18030")

    if isinstance(line, unicode):
        return line

    if not isinstance(line, (str, unicode)):
        return line

    if encoding:
        if not errors:
            errors = "ignore"
        try:
            line = line.decode(encoding, errors=errors)
        except:
            raise UnicodeError("line[%r] decode error, encoding %s" % (line, encoding))
        return line

    if isinstance(try_encodings, str):
        try_encodings = [try_encodings]

    encoding = detect_str_encoding(line, try_encodings)
    if encoding:
        return line.decode(encoding)
    raise UnicodeError("line[%s] decode error, coding list %s" % (line, ", ".join(try_encodings)))


def get_encoding(encoding=None):
    """
    get encoding, if encoding is None, return systerm default encoding
    """
    import locale
    return encoding \
        or locale.getpreferredencoding() or sys.stdin.encoding or sys.getdefaultencoding()


def progressbar(iterable, step=1000, *funcs):
    """every step info reading progress"""
    try:
        name = iterable.name
    except:
        try:
            (filename, line_number, function_name, text) = traceback.extract_stack()[-2]
            begin = text.find('progressbar(') + len('progressbar(')
            name = text[begin:].split(",", 1)[0]
        except:
            name = "%s(<unknown>)" % type(iterable)

    for i, x in enumerate(iterable):
        if i > 0 and i % step == 0:
            info("read iter[{}] {} lines ...".format(name, i))
            for func in funcs:
                info("    %s", func())
        yield x


#stdin = progressbar(sys.stdin, step=5000)


def run_shell(args, cwd=None, env=None, ok_returncodes=None, return_stdout=False):
    """
    执行shell命令

    Args:
    args -- str/tuple/list, 待执行shell cmd，如 'ls -lrt' or ['ls', '-lrt']
    cwd -- 工作目录
    ok_returncodes -- a list/tuple/set of return codes we expect to
        get back from hadoop (e.g. [0,1]). By default, we only expect 0.
        If we get an unexpected return code, we raise a CalledProcessError.
    return_stdout -- return the stdout from the hadoop command
    """
    if isinstance(args, (tuple, list)):
        shell = False
    else:
        shell = True
    root_logger.debug('run shell > %r' % args)
    # return subprocess.check_call(cmd, shell=shell, cwd=cwd, env=env)
    if return_stdout:
        proc = subprocess.Popen(args, shell=shell, cwd=cwd, env=env, stdout=subprocess.PIPE)
    else:
        proc = subprocess.Popen(args, shell=shell, cwd=cwd, env=env)
    stdout, _ = proc.communicate()

    ok_returncodes = ok_returncodes or [0]

    if proc.returncode not in ok_returncodes:
        root_logger.warn('stdout > %s' % stdout)
        raise subprocess.CalledProcessError(proc.returncode, args)

    if return_stdout:
        return stdout
    else:
        return proc.returncode


################################
# date
###############################
class DateUtil(object):
    """
    DateUtil

    >>> d = DateUtil('20190401')

    >>> d + 1
    DateUtil(2019, 4, 2, 0, 0, 0)
    >>> d
    DateUtil(2019, 4, 1, 0, 0, 0)

    >>> d += 1
    >>> d
    DateUtil(2019, 4, 2, 0, 0, 0)

    >>> d -= 2
    >>> d
    DateUtil(2019, 3, 31, 0, 0, 0)

    >>> d - 1
    DateUtil(2019, 3, 30, 0, 0, 0)
    >>> d
    DateUtil(2019, 3, 31, 0, 0, 0)

    >>> map(str, d.span(2))
    ['20190331', '20190401']
    >>> map(str, d.span(-2))
    ['20190330', '20190331']

    >>> d < DateUtil.today()
    True

    """

    def __init__(self, date=None, format="%Y%m%d"):
        if isinstance(date, datetime.datetime):
            self.datetime = date
        elif isinstance(date, self.__class__):
            self.datetime = date.datetime
        elif not date:
            self.datetime = datetime.datetime.today()
        else:
            self.datetime = datetime.datetime.strptime(date, format)

        self.format = format

    def copy(self):
        return self.__class__(self)

    def span(self, n):
        """ 返回以datetime为base的Date list
        """
        start, end = 0, n
        if start > end:
            start, end = end + 1, start + 1

        return [self + x for x in range(start, end)]

    @classmethod
    def now(cls):
        """
        datetime设置为当前time
        """
        return cls()

    @classmethod
    def today(cls):
        """
        datetime只设置年月日
        """
        return cls(str(cls()))

    @classmethod
    def yesterday(cls):
        """
        datetime只设置年月日
        """
        return cls.today() - 1

    @classmethod
    def tommorrow(cls):
        """
        datetime只设置年月日
        """
        return cls.today() + 1

    @classmethod
    def timestamp(cls):
        return cls.now().strftime("%Y%m%d%H%M%S")

    def strftime(self, format=None):
        return self.datetime.strftime(format or self.format)

    def __str__(self):
        return self.datetime.strftime(self.format)

    def __repr__(self):
        return '%s(%s, %s, %s, %s, %s, %s)' % (
            self.__class__.__name__, self.datetime.year, self.datetime.month, self.datetime.day,
            self.datetime.hour, self.datetime.minute, self.datetime.second)

    def __add__(self, other):
        return self.__class__(self.datetime + datetime.timedelta(days=other))

    def __radd__(self, other):
        return self.__class__(self.datetime + datetime.timedelta(days=other))

    def __iadd__(self, other):
        self.datetime += datetime.timedelta(days=other)
        return self

    def __sub__(self, other):
        """ return datetime.timedelta if both are Date obj
        """
        if isinstance(other, int):
            return self.__class__(self.datetime - datetime.timedelta(days=other))
        else:
            return self.datetime - self.__class__(other, self.format).datetime

    def __isub__(self, other):
        self.datetime -= datetime.timedelta(days=other)
        return self

    def __lt__(self, other):
        return self.datetime < self.__class__(other, self.format).datetime

    def __eq__(self, other):
        return self.datetime == self.__class__(other, self.format).datetime

    def __getattr__(self, key):
        return getattr(self.datetime, key)


def load_text(file, *funcs, **kws):
    """
    加载set or dict，根据模板,默认load 整行, return unicode
    paras:
        1. file: 待load text
        2. template: {3}  or  { (1,3) : [4] }
        3. funcs 依次执行每一行，如果返回为 True/False， 则执行过滤(False的过滤)
           如果返回的为list, 则执行modify 操作
        4. delim: 输入分隔符
        5. encoding: 输入编码，默认为 ut8
    note: 先modify 再filter

    example:
        [line]
            key1,key2,value1
            key1,key2,value2
        [input]
            load_text(file, delim=",",
                      template={ (0,1) : 2},
                      filter=lambda x: x[2] == value2, modify=lambda x: x[2]=value; x)
        [return]
            { (key1,key2) : value}

    """
    delimiter = kws.get("delim", "\t")
    encoding = kws.get("encoding", 'utf8')
    template = kws.get("template", {"all"})
    info("loads text file[%s] with template[%s]", file, str(template))
    if isinstance(template, set):
        res = set()
        key = template.pop()
        if key == "all":

            def _add_result(res, ll):
                res.add(delimiter.join(ll))
        elif isinstance(key, tuple):

            def _add_result(res, ll):
                res.add(tuple([ll[i] for i in key]))
        else:

            def _add_result(res, ll):
                res.add(ll[key])
    else:
        res = {}
        key, value = template.popitem()
        if isinstance(key, tuple):
            if isinstance(value, tuple):
                # { (0,1) : (2,3)}
                def _add_result(res, ll):
                    res[tuple([ll[i] for i in key])] = tuple([ll[i] for i in value])
            elif isinstance(value, set):
                assert len(value) == 1, "value is set type, size should be 1"
                value_in_value = value.pop()
                if isinstance(value_in_value, tuple):
                    # { (0,1) : {(2,3)} }
                    def _add_result(res, ll):
                        tmp = tuple([ll[i] for i in key])
                        if tmp not in res:
                            res[tmp] = set()
                        res[tmp].add(tuple([ll[i] for i in value_in_value]))
                else:
                    # { (0,1) : {3} }
                    def _add_result(res, ll):
                        tmp = tuple([ll[i] for i in key])
                        if tmp not in res:
                            res[tmp] = set()
                        res[tmp].add(ll[value_in_value])
            elif isinstance(value, list):
                # { (0,1) : [3, 4] }
                def _add_result(res, ll):
                    res[tuple([ll[i] for i in key])] = [ll[i] for i in value]
            else:
                # { (0,1) : 3 }
                def _add_result(res, ll):
                    res[tuple([ll[i] for i in key])] = ll[value]

        else:
            if isinstance(value, tuple):
                # { (0,1) : (2,3)}
                def _add_result(res, ll):
                    res[ll[key]] = tuple([ll[i] for i in value])
            elif isinstance(value, set):
                assert len(value) == 1, "value is set type, size should be 1"
                value_in_value = value.pop()
                if isinstance(value_in_value, tuple):
                    # { (0,1) : {(2,3)} }
                    def _add_result(res, ll):
                        tmp = ll[key]
                        if tmp not in res:
                            res[tmp] = set()
                        res[tmp].add(tuple([ll[i] for i in value_in_value]))
                else:
                    # { (0,1) : {3} }
                    def _add_result(res, ll):
                        tmp = ll[key]
                        if tmp not in res:
                            res[tmp] = set()
                        res[tmp].add(ll[value_in_value])
            elif isinstance(value, list):
                # {1 : [3, 4] }
                def _add_result(res, ll):
                    res[ll[key]] = [ll[i] for i in value]
            else:
                # { 1 : 3 }
                def _add_result(res, ll):
                    res[ll[key]] = ll[value]

    for line in progressbar(open(file), step=5000):
        ll = split_str(line, encoding=encoding, delim=delimiter)
        for func in funcs:
            _ret = func(ll)
            if isinstance(_ret, bool):
                if not _ret:
                    break
        else:
            _add_result(res, ll)

    # info("loads text file[%s] done .. ", file)
    return res


########################################
# =====>  debug
########################################


def initLogger(name=None, level=logging.DEBUG, console=False, log_dir='log'):
    logger = logging.getLogger(name)
    logger.setLevel(level)

    if len(logger.handlers) != 0:
        for hdlr in logger.handlers:
            logger.removeHandler(hdlr)

    if console:
        console_hdlr = logging.StreamHandler()
        console_hdlr.setFormatter(formatter)
        console_hdlr.setLevel(logging.DEBUG)
        logger.addHandler(console_hdlr)

    if log_dir:
        while True:
            if not isabs(log_dir):
                try:
                    script_dir = get_main_dir()
                    script_file = basename(get_main_file())
                except IOError:
                    break
                else:
                    log_dir = os.path.join(script_dir, log_dir)
            else:
                log_dir = log_dir
            if not os.path.exists(log_dir):
                os.makedirs(log_dir)
            if name:
                log_file = os.path.join(log_dir, name + '.log')
            else:
                script_file_no_ext = os.path.splitext(script_file)[0]
                log_file = os.path.join(log_dir, script_file_no_ext + '.log')

            file_hdlr = logging.handlers.TimedRotatingFileHandler(
                log_file, when="M", interval=10, backupCount=20)
            file_hdlr.setFormatter(formatter)
            file_hdlr.setLevel(logging.DEBUG)
            logger.addHandler(file_hdlr)

            break

    return logger


def getLogger(name=None, level=logging.DEBUG):
    if name is None:
        caller_frm = inspect.stack()[1]
        caller_mod = inspect.getmodule(caller_frm[0])
        logger_name = caller_mod.__name__
    else:
        logger_name = name

    logger = logging.getLogger(logger_name)
    logger.setLevel(level)
    return logger


def progress(it, verbosity=100, key=repr, estimate=None, persec=True):
    """An iterator that yields everything from `it', but prints progress
       information along the way, including time-estimates if
       possible"""
    from itertools import islice
    from datetime import datetime
    import sys

    now = start = datetime.now()
    elapsed = start - start

    # try to guess at the estimate if we can
    if estimate is None:
        try:
            estimate = len(it)
        except:
            pass

    def timedelta_to_seconds(td):
        return td.days * (24 * 60 * 60) + td.seconds + (float(td.microseconds) / 1000000)

    def format_timedelta(td, sep=''):
        ret = []
        s = timedelta_to_seconds(td)
        if s < 0:
            neg = True
            s *= -1
        else:
            neg = False

        if s >= (24 * 60 * 60):
            days = int(s // (24 * 60 * 60))
            ret.append('%dd' % days)
            s -= days * (24 * 60 * 60)
        if s >= 60 * 60:
            hours = int(s // (60 * 60))
            ret.append('%dh' % hours)
            s -= hours * (60 * 60)
        if s >= 60:
            minutes = int(s // 60)
            ret.append('%dm' % minutes)
            s -= minutes * 60
        if s >= 1:
            seconds = int(s)
            ret.append('%ds' % seconds)
            s -= seconds

        if not ret:
            return '0s'

        return ('-' if neg else '') + sep.join(ret)

    def format_datetime(dt, show_date=False):
        if show_date:
            return dt.strftime('%Y-%m-%d %H:%M')
        else:
            return dt.strftime('%H:%M:%S')

    def deq(dt1, dt2):
        "Indicates whether the two datetimes' dates describe the same (day,month,year)"
        d1, d2 = dt1.date(), dt2.date()
        return (d1.day == d2.day and d1.month == d2.month and d1.year == d2.year)

    sys.stderr.write('Starting at %s\n' % (start, ))

    # we're going to islice it so we need to start an iterator
    it = iter(it)

    seen = 0
    while True:
        this_chunk = 0
        thischunk_started = datetime.now()

        # the simple bit: just iterate and yield
        for item in islice(it, verbosity):
            this_chunk += 1
            seen += 1
            yield item

        if this_chunk < verbosity:
            # we're done, the iterator is empty
            break

        now = datetime.now()
        elapsed = now - start
        thischunk_seconds = timedelta_to_seconds(now - thischunk_started)

        if estimate:
            # the estimate is based on the total number of items that
            # we've processed in the total amount of time that's
            # passed, so it should smooth over momentary spikes in
            # speed (but will take a while to adjust to long-term
            # changes in speed)
            remaining = ((elapsed / seen) * estimate) - elapsed
            completion = now + remaining
            count_str = ('%d/%d %.2f%%' % (seen, estimate, float(seen) / estimate * 100))
            completion_str = format_datetime(completion, not deq(completion, now))
            estimate_str = (
                ' (%s remaining; completion %s)' % (format_timedelta(remaining), completion_str))
        else:
            count_str = '%d' % seen
            estimate_str = ''

        if key:
            key_str = ': %s' % key(item)
        else:
            key_str = ''

        # unlike the estimate, the persec count is the number per
        # second for *this* batch only, without smoothing
        if persec and thischunk_seconds > 0:
            persec_str = ' (%.1f/s)' % (float(this_chunk) / thischunk_seconds, )
        else:
            persec_str = ''

        sys.stderr.write('%s%s, %s%s%s\n' % (count_str, persec_str, format_timedelta(elapsed),
                                             estimate_str, key_str))

    now = datetime.now()
    elapsed = now - start
    elapsed_seconds = timedelta_to_seconds(elapsed)
    if persec and seen > 0 and elapsed_seconds > 0:
        persec_str = ' (@%.1f/sec)' % (float(seen) / elapsed_seconds)
    else:
        persec_str = ''
    sys.stderr.write('Processed %d%s items in %s..%s (%s)\n' %
                     (seen, persec_str, format_datetime(start, not deq(start, now)),
                      format_datetime(now, not deq(start, now)), format_timedelta(elapsed)))


def exponential_retrier(func_to_retry,
                        exception_filter=lambda *args, **kw: True,
                        retry_min_wait_ms=500,
                        max_retries=5):
    """Call func_to_retry and return it's results.
    If func_to_retry throws an exception, retry.
    :param Function func_to_retry: Function to execute
        and possibly retry.
    :param exception_filter:  Only retry exceptions for
        which this function returns True.  Always returns True by default.
    :param int retry_min_wait_ms: Initial wait period
        if an exception happens in milliseconds.
        After each retry this value will be multiplied by 2
        thus achieving exponential backoff algorithm.
    :param int max_retries:  How many times to wait before
        just re-throwing last exception.
        Value of zero would result in no retry attempts.
    """
    sleep_time = retry_min_wait_ms
    num_retried = 0
    while True:
        try:
            return func_to_retry()
        # StopIteration should never be retried as its part of regular logic.
        except StopIteration:
            raise
        except Exception as e:
            g.log.exception("%d number retried" % num_retried)
            num_retried += 1
            # if we ran out of retries or this Exception
            # shouldnt be retried then raise the exception instead of sleeping
            if num_retried > max_retries or not exception_filter(e):
                raise

            # convert to ms.  Use floating point literal for int -> float
            time.sleep(sleep_time / 1000.0)
            sleep_time *= 2


def rate_limited(max_per_second):
    """Rate-limits the decorated function locally, for one process."""
    lock = threading.Lock()
    min_interval = 1.0 / max_per_second

    def decorate(func):
        last_time_called = [time.time()]

        @wraps(func)
        def rate_limited_function(*args, **kwargs):
            lock.acquire()
            try:
                elapsed = time.time() - last_time_called[0]
                left_to_wait = min_interval - elapsed
                if left_to_wait > 0:
                    time.sleep(left_to_wait)

                return func(*args, **kwargs)
            finally:
                last_time_called[0] = time.time()
                lock.release()

        return rate_limited_function

    return decorate


###########################################
# ======> init
###########################################
# {

initLogger(name=None, level=logging.WARNING, console=True, log_dir='log')
root_logger = getLogger()


def get_log_level_by_argv():
    """
    set log level by sys.argv, --debug --info ...
    """
    target_level_name = None
    for argv in sys.argv[1:]:
        if argv.startswith("--") and hasattr(logging, argv[2:].upper()):
            target_level_name = argv[2:].upper()
            sys.argv.remove(argv)

    if target_level_name:
        print >> sys.stderr, ">>> set root log level to %s\n" % target_level_name
        root_logger.setLevel(getattr(logging, target_level_name))


def dvars(*args):
    """
    debug value of args, the args must be in same line with funcname
    """
    if root_logger.level > logging.DEBUG:
        return
    (filename, line_number, function_name, text) = traceback.extract_stack()[-2]
    this_func_name = traceback.extract_stack()[-1][2]
    begin = text.find('%s(' % this_func_name) + len('%s(' % this_func_name)
    end = text.find(')', begin)
    texts = split_str(text[begin:end], ',')
    for name, value in zip(texts, args):
        if function_name != '<module>':
            root_logger.debug('%s:%s -> %s@%s = %s %r', filename, line_number, name, function_name,
                              type(value), value)
        else:
            root_logger.debug('%s:%s -> %s = %s %r', filename, line_number, name, type(value),
                              value)
        """
        TODO
        value_type = None
        if isinstance(value, text_type):
            # unicode
            value_str = value
            value_str = "u'" + value_str[:length] + "'" + (value_str[length:] and ' ..')
        elif isinstance(value, string_types):
            try:
                value_str = value.decode('utf8')
                value_type = "<type 'utf-8 str'>"
            except UnicodeDecodeError:
                try:
                    value_str = value.decode('gb18030')
                    value_type = "<type 'gb18030 str'>"
                except UnicodeDecodeError:
                    value_str = '%r' % value
            # value_str = '%r' % value
            value_str = "b'" + value_str[:length] + "'" + (value_str[length:] and '..')
        else:
            try:
                value_str = dumpu(value)
            except:
                value_str = '%r' % value
        if value_type is None:
            value_type = type(value)

        if hasattr(value, '__len__'):
            value_len = "L" + str(len(value))
        else:
            value_len = ''
        print type(value_str)
        if function_name != '<module>':
            root_logger.debug('%s:%s -> %s@%s = %s%s %s', filename, line_number, name,
                              function_name, value_len, value_type, value_str)
        else:
            root_logger.debug('%s:%s -> %s = %s%s %r', filename, line_number, name, value_type,
                              value_len, value_str)
        """


get_log_level_by_argv()


def replace_excepthook():
    old_hook = sys.excepthook

    def myexcepthook(exc_type, exc_value, tb):
        print "hello**************\n"
        print exc_value
        traceback.print_tb(tb)
        print

        while tb:
            frame = tb.tb_frame
            print 'locals --->', frame.f_locals
            print 'globals -->', frame.f_globals, "\n"

            tb = tb.tb_next

        print "goodbye************"

        old_hook(exc_type, exc_value, tb)

    sys.excepthook = myexcepthook


replace_excepthook()
# }
if __name__ == "__main__":
    res = locals()[sys.argv[1]](*sys.argv[2:])
    if isinstance(res, types.GeneratorType):
        res = list(res)
    if res is not None:
        print res
