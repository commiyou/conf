# -*- coding: utf-8 -*-
from __future__ import unicode_literals

import collections
import datetime
import fnmatch
import functools
import glob
import itertools
import json
import logging
import os
import pipes
import re
import subprocess
import sys
import tempfile
import urllib2
from io import BytesIO

logging.basicConfig()
LOGGER = logging.getLogger(__name__)
LOGGER.setLevel(logging.DEBUG)

__STREAMING_JOB_PARAMS = {}


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
        except KeyError, k:
            raise AttributeError(k)

    def __setattr__(self, key, value):
        self[key] = value

    def __delattr__(self, key):
        try:
            del self[key]
        except KeyError, k:
            raise AttributeError(k)

    def __repr__(self):
        return '<Storage ' + dict.__repr__(self) + '>'


storage = Storage


def add_param(k, v):
    LOGGER.debug('add job paras "%s" => "%s', k, v)
    __STREAMING_JOB_PARAMS[k] = v


# def map(memory, capacity, tasks, extras=None):
# def decorater_map(func):
# @functools.wraps(func)
# def wrapper_map(*args, **kwargs):
# add_param('-D mapred.map.memory.limit', memory)
# add_param('-D mapred.job.map.capacity', capacity)
# add_param('-D mapred.reduce.tasks', tasks)
# return func(*args, **kwargs)

# return wrapper_map

# return decorater_map


class MRJob(object):
    """
    bin/hadoop command [genericOptions] [streamingOptions]
    generic options:
        -conf configuration_file
        -D property=value
        -fs host:port or local
        -jt host:port or local
        -files hdfs://host:fs_port/user/testfile.txt#testfile
        -libjars
        -archives  hdfs://host:fs_port/user/testfile.tgz#tgzdir

    streaming options:
        -input directoryname or filename
        -output directoryname
        -mapper executable or JavaClassName
        -reducer executable or JavaClassName
        -file filename	Optional
        -inputformat JavaClassName
        -outputformat JavaClassName
        -partitioner JavaClassName
        -combiner streamingCommand or JavaClassName
        -cmdenv name=value
        -inputreader
        -verbose
        -lazyOutput
        -numReduceTasks
        -mapdebug
        -reducedebug
    """

    # generic options useful -D
    D_GENERIC_OPTIONS = {
        'name': 'mapred.job.name',
        'queue': 'mapred.job.queue.name',
        'priority': 'mapred.job.priority',
        'sort_keys': 'stream.num.map.output.key.fields',
        'partition_keys': 'num.key.fields.for.partition',
        'map_capacity': 'mapred.job.map.capacity',
        'map_memory': 'mapred.map.memory.limit',
        'map_tasks': 'mapred.map.tasks',
        'reduce_capacity': 'mapred.job.reduce.capacity',
        'reduce_memory': 'mapred.reduce.memory.limit',
        'reduce_tasks': 'mapred.reduce.tasks',
        'map_failures_percent': 'mapred.max.map.failures.percent',
        'reduce_failures_percent': 'mapred.max.map.failures.percent',
        'compress': 'mapred.output.compress'
    }

    def __init__(self,
                 inputs=None,
                 input_dones=None,
                 local_inputs=None,
                 mapper=None,
                 reducer=None,
                 output_path=None,
                 output_done=None,
                 partition_keys=None,
                 sort_keys=None,
                 map_memory=None,
                 map_capacity=None,
                 map_tasks=None,
                 reduce_memory=None,
                 reduce_capacity=None,
                 reduce_tasks=None,
                 cmdenvs=None,
                 files=None,
                 dirs=None,
                 archives=None,
                 name=None,
                 queue=None,
                 owner=None,
                 priority=None,
                 compress=None,
                 map_failures_percent=None,
                 reduce_failures_percent=None,
                 partitioner="org.apache.hadoop.mapred.lib.KeyFieldBasedPartitioner",
                 outputformat="org.apache.hadoop.mapred.lib.SuffixMultipleTextOutputFormat",
                 hadoop=None,
                 hadoop_bin=None,
                 extra=None,
                 python_bin=None,
                 hdfs_python_bin=None,
                 local_python_bin=None):
        """TODO: to be defined1. """
        self.build = None

        self.inputs = util.to_list(inputs) or []
        self.input_dones = util.to_list(input_dones) or []
        self.local_inputs = util.to_list(local_inputs) or []

        self.mapper_cmd = mapper
        self.mapper_func = []
        self.map_memory = map_memory
        self.map_capacity = map_capacity
        self.map_tasks = map_tasks
        self.sort_keys = sort_keys

        self.reducer_cmd = reducer
        self.reducer_func = None
        self.reduce_memory = reduce_memory
        self.reduce_capacity = reduce_capacity
        self.reduce_tasks = reduce_tasks
        self.partition_keys = partition_keys
        self.output_path = output_path
        self.output_done = output_done

        self.cmdenvs = cmdenvs
        self.files = util.to_list(files) or []
        self.dirs = util.to_list(dirs) or []
        self.archives = util.to_list(archives) or []
        self.name = name
        self.owner = owner
        self.priority = priority
        self.compress = compress
        self.map_failures_percent = map_failures_percent
        self.reduce_failures_percent = reduce_failures_percent
        self.partitioner = partitioner
        self.outputformat = outputformat
        self.hadoop_bin = hadoop_bin
        self.extra = util.to_list(extra)
        self.python_bin = python_bin
        self.hdfs_python_bin = hdfs_python_bin or self.python_bin
        self.local_python_bin = local_python_bin or self.python_bin
        self.queue = queue

        self._script_file = os.path.realpath(sys.argv[0])
        self._script_file_name = os.path.basename(self._script_file)

    def build(self, func):
        self.build = func

    def map(self,
            inputs=None,
            local_inputs=None,
            dones=None,
            path_regex=None,
            memory=None,
            capacity=None,
            tasks=None,
            sort_keys=None,
            pattern=None):
        inputs = util.to_list(inputs)
        if inputs:
            self.inputs += inputs

        self.map_memory = memory or self.map_memory
        self.map_capacity = capacity or self.map_capacity
        self.map_tasks = tasks or self.map_tasks
        self.sort_keys = sort_keys or self.sort_keys

        def bind_mapper(func):
            func._pattern = pattern
            func._inputs = util.to_list(inputs)
            func._local_inputs = util.to_list(local_inputs)
            self.mapper_func.append(func)
            util.debug('binding func<%s> on mapper', func.func_name)
            return func

        return bind_mapper

    def reduce(self,
               partition_keys=None,
               memory=None,
               capacity=None,
               tasks=None,
               output_path=None,
               output_done=None):
        self.reduce_memory = memory or self.reduce_memory
        self.reduce_capacity = capacity or self.reduce_capacity
        self.reduce_tasks = tasks or self.reduce_tasks
        self.partition_keys = partition_keys or self.partition_keys
        self.output_done = output_done or self.output_done
        self.output_path = output_path or self.output_path

        def bind_reducer(func):
            self.reducer_func = func
            util.debug('binding func<%s> on reducer', func.func_name)
            return func

        return bind_reducer

    def local(self, cwd='./'):
        if not os.path.exists(cwd):
            os.makedirs(cwd)
        args = []
        if self.mapper_cmd:
            if not self.local_inputs:
                util.warn('no local inputs, use stdin')
            else:
                args += ['cat']
                args += (self.local_inputs)
            args += ['|', self.local_python_bin or 'python', self._script_file_name, 'mapper']
        elif self.mapper_func:
            args += ['{']
            for func in self.mapper_func:
                if func._local_inputs:
                    args += ['cat']
                    util.info("inputs %s", func._local_inputs)
                    args += (func._local_inputs)
                    args += [
                        '|', self.local_python_bin or 'python', self._script_file_name, 'run',
                        func.func_name
                    ]
                    args += [';']
            args += ['}']
        else:
            raise Exception('no mapper')

        args += ['|', 'tee', 'md']
        args += ['|', 'sort', '-k', '1,%s' % self.sort_keys, '-t', r"$'\t'"]
        args += ['|', 'tee', 'ri']
        args += [
            '|', self.local_python_bin or 'python', self._script_file_name, 'reducer', '>', 'rd'
        ]

        util.info('run local> %s', ' '.join(args))
        util.run_shell(' '.join(args), cwd=cwd)

    def mapper(self):
        if self.mapper_cmd:
            util.run_shell(self.mapper_cmd)
        elif self.mapper_func:
            if len(self.mapper_func) == 1:
                return self.mapper_func[0]()
            else:
                if util.map_input_file():
                    for func in self.mapper_func:
                        if func._pattern and re.search(func._pattern, util.map_input_file()):
                            util.debug('mif<%s> match func<%s> by pattern<%s>',
                                       util.map_input_file(), func.func_name, func._pattern)
                            return func()
                        if func._inputs:
                            for _input in func._inputs:
                                if _input in util.map_input_file() or fnmatch.fnmatch(
                                        util.map_input_file(), _input):
                                    util.debug('mif<%s> match func<%s> by input<%s>',
                                               util.map_input_file(), func.func_name, _input)
                                    return func()

                    else:
                        raise Exception("map_input_file<%s> not match and mapper func's pattern",
                                        util.map_input_file())

    def reducer(self):
        if self.reducer_cmd:
            return util.run_shell(self.reducer_cmd)
        elif self.reducer_func:
            return self.reducer_func()

    def hadoop(self):
        if not os.path.isfile(self.hadoop_bin):
            raise Exception('hadoop bin<%r> is invalid', self.hadoop_bin)
        args = [self.hadoop_bin, "streaming"]
        for variable_name in self.D_GENERIC_OPTIONS:
            if not hasattr(self, variable_name):
                util.warn('job has no option %s', variable_name)
                continue
            variable_value = getattr(self, variable_name)
            if variable_value is None:
                util.warn('job option %s is None', variable_name)
                continue
            util.info('job option %s => %s', variable_name, variable_value)
            args += ['-D', '%s=%s' % (self.D_GENERIC_OPTIONS[variable_name], variable_value)]

        if self.extra:
            self.extra.sorted(key=lambda x: 0 if x.startswith('-D') else 1)
            args += self.extra

        self.files += ['*.py', "*.sh", "*.conf"]
        files_set = set()
        for filename in self.files:
            file_list = glob.glob(os.path.expanduser(filename))
            for f in file_list:
                files_set.add(f)
        args += ["-files", ",".join(files_set)]

        if self.dirs:
            # TODO
            pass
        if self.archives:
            for f in self.archives:
                args += ['-cacheArchive', f]

        if self.partitioner:
            args += ['-partitioner', self.partitioner]

        if self.cmdenvs:
            if 'PYTHONPATH' not in self.cmdenvs:
                args += ["-cmdenv", 'PYTHONPATH=.']

            for key, value in sorted(self.cmdenvs.items()):
                if key == "PYTHONPATH" and {'.', './'} & set(util.split_str(value, ':')):
                    value = ":".join([value, "."])
                args += ["-cmdenv", '%s=%s' % (key, value)]
        else:
            args += ["-cmdenv", 'PYTHONPATH=.']

        for _input in self.inputs:
            args += ["-input", _input]
        args += ["-output", self.output_path]
        mapper = util.cmd_line(
            [self.hdfs_python_bin or 'python', self._script_file_name, 'mapper'])
        args += ['-mapper', mapper]

        reducer = util.cmd_line(
            [self.hdfs_python_bin or 'python', self._script_file_name, 'reducer'])
        args += ['-reducer', reducer]

        hdfs.rmr(self.hadoop_bin, self.output_path)
        util.info('run hadoop> %s', util.cmd_line(args))
        util.run_shell(args)

    def cli(self):
        pass

    def run(self):
        if sys.argv[1] == 'mapper':
            return self.mapper()
        elif sys.argv[1] == 'reducer':
            return self.reducer()
        elif sys.argv[1] == 'run':
            if self.mapper_func:
                for func in self.mapper_func:
                    if func.func_name == sys.argv[2]:
                        return func()
            elif self.reducer_func and self.reducer_func.func_name == sys.argv[2]:
                return self.reducer_func()
        elif sys.argv[1] == 'hadoop':
            self.hadoop()
        elif sys.argv[1] == 'local':
            self.local()

    def schedule(self):
        self.build()
        self.streaming()
        self.make_done()
        self.finish()


class SetEncoder(json.JSONEncoder):
    """

    >>> json.dumps({"key": [{1,2,3}, 1], "key2": None},
                ensure_ascii=False, cls=SetEncoder).encode("gb18030")
    '{"key2": null, "key": [[1, 2, 3], 1]}'

    """

    def default(self, obj):
        if isinstance(obj, set):
            return list(obj)
        if not isinstance(obj, (int, float, list, tuple, dict, str, unicode)):
            return repr(obj)
        return json.JSONEncoder.default(self, obj)


class Util(object):
    @staticmethod
    def split_str(s, delim='\t', encoding='utf8', errors='strict', columns=None):
        if not isinstance(s, unicode):
            us = s.decode(encoding, errors)

        result = map(lambda x: x.strip(), us.rstrip('\n').split(delim))
        if columns:
            if isinstance(columns, (str, unicode)):
                if ',' in columns:
                    columns = util.split_str(columns, delim=',')
                else:
                    columns = util.split_str(columns, delim=' ')
            result = storage(zip(columns, result))
        return result

    @staticmethod
    def iter_and_split(fd=sys.stdin,
                       delim='\t',
                       encoding='utf8',
                       errors='strict',
                       max_failures_cnt=5):
        for line in fd:
            try:
                ll = util.split_str(line, delim=delim, encoding=encoding, errors=errors)
            except Exception as e:
                util.warn('fd<%s> read line error.\n line > %r\n%s', fd.name, line, e)
                max_failures_cnt -= 1
                continue
            if max_failures_cnt <= 0:
                raise Exception("fd<%s> read line error too much!")
            yield ll

    @staticmethod
    def get_path_from_done_file(done_file):
        pass

    @staticmethod
    def to_list(x):
        if x is None or isinstance(x, list):
            return x
        return [x]

    @staticmethod
    def debug(*args):
        LOGGER.debug(*args)

    @staticmethod
    def info(*args):
        LOGGER.info(*args)

    @staticmethod
    def warn(*args):
        LOGGER.warning(*args)

    @staticmethod
    def error(*args):
        LOGGER.fatal(*args)

    @staticmethod
    def timestamp():
        return datetime.datetime.today().strftime("%Y%m%d%H%M%S")

    @staticmethod
    def cmd_line(args):
        """build a command line that works in a shell.
        """
        args = [str(x) for x in args]

        return ' '.join(pipes.quote(x) for x in args)

    @staticmethod
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
        # return subprocess.check_call(cmd, shell=shell, cwd=cwd, env=env)
        proc = subprocess.Popen(args, shell=shell, cwd=cwd, env=env, stdout=subprocess.PIPE)
        stdout, _ = proc.communicate()

        ok_returncodes = ok_returncodes or [0]

        if proc.returncode not in ok_returncodes:
            util.warn('stdout > %s' % stdout)
            raise subprocess.CalledProcessError(proc.returncode, args)

        if return_stdout:
            return stdout
        else:
            return proc.returncode

    @staticmethod
    def map_input_file():
        return os.getenv('map_input_file', None)

    @staticmethod
    def dumpu(obj):
        """
        dump obj to unicode, obj is unicode
        """
        string = json.dumps(obj, ensure_ascii=False, cls=SetEncoder)
        return string

    @staticmethod
    def dumps(obj, encoding=None, errors="strict"):
        """
        dump obj to string, obj is unicode
        """
        if encoding is None:
            encoding = 'utf8'
        return util.dumpu(obj).encode(encoding=encoding, errors=errors)

    @staticmethod
    def format_args(*args, **kws):
        """
        return str of args joined by delim
        """
        encoding = kws.get("encoding", 'utf8')
        errors = kws.get('errors', 'strict')
        suffix = kws.get('suffix', "")
        delim = kws.get("delim", "\t")
        flatten = kws.get("flatten", True)
        if flatten:
            tmp = []
            for arg in args:
                if isinstance(arg, (tuple, list)):
                    tmp += list(arg)
                else:
                    tmp.append(arg)
            args = tmp
        tmp = []
        for arg in args:
            if isinstance(arg, (dict, set, tuple, list)):
                tmp.append(util.dumpu(arg, encoding=None))
            elif isinstance(arg, (int, float)):
                tmp.append(str(arg))
            else:
                tmp.append(arg)

        s = "%s%s" % (delim.join(tmp), suffix)
        return s.encode(encoding=encoding, errors=errors)

    @staticmethod
    def print_args(*args, **kws):
        """
        return str of args joined by delim
        """
        fd = kws.get("fd", sys.stdout)
        print >> fd, util.format_args(*args, **kws)

    @staticmethod
    def to_unicode(s):
        """Convert ``bytes`` to unicode.

        Use this if you need to ``print()`` or log bytes of an unknown encoding,
        or to parse strings out of bytes of unknown encoding (e.g. a log file).

        This hopes that your bytes are UTF-8 decodable, but if not, falls back
        to latin-1, which always works.
        """

        if isinstance(s, bytes):
            try:
                return s.decode('utf_8')
            except UnicodeDecodeError:
                return s.decode('gb18030')
        elif isinstance(s, basestring):  # e.g. is unicode
            return s
        else:
            raise TypeError


util = Util


class HDFS(object):
    def __init__(self, hadoop_clients):
        self._hadoops = hadoop_clients

    def __getattr__(self, key):
        if key not in self._hadoops:
            raise AttributeError('hadoop client %s nof found' % key)
        return self.decorate_prefix(key)

    def decorate_prefix(self, hdfs_name):
        def prefix(path):
            if isinstance(path, (str, unicode)):
                if path.startswith('hdfs://'):
                    return path
                else:
                    return self._hadoops[hdfs_name].fs + path
            else:
                return map(prefix, path)

        return prefix

    @staticmethod
    def rmr(hadoop_bin, path):
        util.run_shell([hadoop_bin, 'fs', '-rmr', path], ok_returncodes=[0, 255])


class Hadoop(object):
    def __init__(self, bin_path):
        self.bin = bin_path
        self.conf = os.path.join(
            os.path.dirname(os.path.dirname(self.bin)), 'conf', 'hadoop-site.xml')

    @property
    def name(self):
        """
        return [queue@]fsname
        """
        queue = self.queue + "@" if self.queue != 'default' else ""
        return queue + self.fs.split('-')[1]

    @property
    def fs(self):
        return self.property['fs.default.name']

    @property
    def queue(self):
        return self.property.get('mapred.job.queue.name', 'default')

    @property
    def ugi(self):
        return self.property['hadoop.job.ugi']

    @property
    def job_tracker(self):
        return self.property['mapred.job.tracker']

    @property
    def property(self):
        import xml.etree.ElementTree as ET
        tree = ET.ElementTree(file=self.conf)
        properties = {}
        for p in tree.findall('property'):
            k = None
            v = None
            for element in p.getchildren():
                if element.tag == 'name':
                    k = element.text
                elif element.tag == 'value':
                    v = element.text
            if k is not None and v is not None:
                properties[k] = v
        return properties

    def __repr__(self):
        tmp = dict(name=self.name, fs=self.fs, queue=self.queue)
        return '<Hadoop ' + dict.__repr__(tmp) + '>'

    def _invoke_hadoop(self, args, ok_returncodes=None, return_stdout=False):
        util.debug('hadoop %s start to run cmd > %s' % (self.name, util.cmd_line(args)))
        args = [self.bin] + args
        return util.run_shell(args, ok_returncodes=ok_returncodes, return_stdout=return_stdout)

    def hdfs_path(self, path):
        """get hdfs:// format of path"""
        return getattr(hdfs, self.name)(path)

    def ls(self, path, return_file=True, return_dir=True):
        """
        return list of paths which started with hdfs://xxx
        """
        stdout = self._invoke_hadoop(['fs', '-ls', path], return_stdout=True)
        result_files = []
        if not return_file:
            util.info('hadoop %s won\'t return dirs' % self.fs)
        if not return_dir:
            util.info('hadoop %s won\'t return files' % self.fs)

        for line in BytesIO(stdout):
            file_type = 'file'
            line = line.rstrip(b'\r\n')

            # ignore total item count

            if line.startswith(b'Found '):
                continue

            fields = line.split(b' ')

            # Throw out directories

            if fields[0].startswith(b'd'):
                file_type = 'dir'

            # Try to figure out which part of the line is the path
            # Expected lines:
            #
            # HDFS:
            # -rw-r--r--   3 dave users       3276 2010-01-13 14:00 /foo/bar
            #
            # S3:
            # -rwxrwxrwx   1          3276 010-01-13 14:00 /foo/bar
            path_index = None

            for index, field in enumerate(fields):
                # look for time field, and pick one after that
                # (can't use field[2] because that's an int in Python 3)

                if len(field) == 5 and field[2:3] == b':':
                    path_index = (index + 1)

            if not path_index:
                raise IOError("Could not locate path in string %r" % line)

            path = util.to_unicode(line.split(b' ', path_index)[-1])
            # handle fully qualified URIs from newer versions of Hadoop ls
            # (see Pull Request #577)

            if return_file and file_type == 'file':
                result_files.append(self.hdfs_path(path))
            if return_dir and file_type == 'dir':
                result_files.append(self.hdfs_path(path))
        return result_files

    def mkdir(self, path):
        self._invoke_hadoop(['fs', '-mkdir', path])

    def rmr(self, path):
        self._invoke_hadoop(['fs', '-rmr', path], ok_returncodes=[0, 255])

    def mv(self, src_path, dst_path):
        """raise exception when src_path not exist or dst exists"""
        self._invoke_hadoop(['fs', '-mv', src_path, dst_path])

    def cp(self, src_path, dst_path):
        """raise exception when src_path not exist or dst exists"""
        self._invoke_hadoop(['fs', '-cp', src_path, dst_path])

    def cat(self, filename):
        """
        文件不能过大，content会缓存在内存中
        """
        return util.to_unicode(self._invoke_hadoop(['fs', '-cat', filename], return_stdout=True))

    def readlines(self, filename):
        return self.cat(filename).splitlines()

    def size(self, path_glob):
        """Get the size of a file or directory (recursively), or 0 if it doesn't exist."""
        try:
            stdout = self._invoke_hadoop(
                ['fs', '-du', path_glob], return_stdout=True, ok_returncodes=[0, 1, 255])
        except subprocess.CalledProcessError:
            return 0

        try:
            return sum(
                int(line.split()[0]) for line in stdout.splitlines()
                if line.strip() and not re.match(r'^Found \d+ items\s*$', line))
        except (ValueError, TypeError, IndexError):
            raise IOError('Unexpected output from hadoop fs -du: %r' % stdout)

    def put(self, local_path, target):
        """raise exception when src_path not exist or dst exists"""
        self._invoke_hadoop(['fs', '-put', local_path, target])

    def get(self, path, local_path='.'):
        """raise exception when src_path not exist or dst exists"""
        self._invoke_hadoop(['fs', '-get', path, local_path])

    def getmerge(self, path, local_path='.'):
        """raise exception when src_path not exist or dst exists"""
        self._invoke_hadoop(['fs', '-get', path, local_path])

    def exists(self, path_glob):
        """Does the given path exist?

        If dest is a directory (ends with a "/"), we check if there are
        any files starting with that path.
        """
        try:
            return_code = self._invoke_hadoop(
                ['fs', '-ls', path_glob],
                ok_returncodes=[0, -1, 255],
            )

            return (return_code == 0)
        except subprocess.CalledProcessError:
            raise IOError("Could not check path %s" % path_glob)

    def touchz(self, dest):
        try:
            self._invoke_hadoop(['fs', '-touchz', dest])
        except subprocess.CalledProcessError:
            raise IOError("Could not touchz %s" % dest)

    def backup(self, path, dst_path=None):
        if dst_path is None:
            dst_path = path + '.bak'
        if self.exists(path):
            self.rmr(dst_path)
            self.mv(path, dst_path)

    def mkdone(self, paths, done_path, as_json=False, append=False, **kwargs):
        """make done to done_path, by paths"""
        fd = tempfile.NamedTemporaryFile(suffix="done.txt")
        if "id" not in kwargs:
            kwargs["id"] = util.timestamp()
        if as_json:
            content = dict(kwargs)
            content.update(input=paths)
            content_str = util.dumpu(content)
        else:
            if set(kwargs.keys()) - {'id'}:
                util.warn('mkdone %s has unused kwargs %r' % (done_path, kwargs))
            if not isinstance(paths, (tuple, list)):
                paths = [paths]
            content_str = ','.join(paths) + "\t" + str(kwargs['id'])

        if append and self.exists(done_path):
            last_line = None
            for line in self.readlines(done_path):
                print >> fd, line
                last_line = line
            if last_line:
                util.info('done %s last line> %s' % (done_path, last_line))
        if append:
            util.info('done %s append new line> %s' % (done_path, content_str))
        else:
            util.info('done %s new content> %s' % (done_path, content_str))
        print >> fd, content_str
        fd.flush()

        self.backup(done_path)
        self.put(fd.name, done_path)
        fd.close()

    def readdone(self, done_path):
        """
        按照done顺序返回每一行中的input，a list
        """
        lines = []
        for line in self.readlines(done_path):
            try:
                js = json.loads(line)
            except ValueError:
                ll = map(lambda x: x.strip(), line.split("\t"))
                if len(ll) > 2:
                    raise Exception("parse done %s error. line  %r" % (done_path, line))
                lines.append(ll[0].split(','))
            else:
                if "input" not in js:
                    raise Exception("parse done %s error. line  %r" % (done_path, line))

                inputs = js['input']
                if not isinstance(inputs, list):
                    inputs = [inputs]
                lines.append(inputs)
        return lines


hadoop = Storage()


def find_hadoop_clients(start_path='~'):
    """
    从start_path目录中寻找符合条件的(bin/hadoop且有conf/hadoop-site.xml) hadoop
    寻找到的hadoop以 name: Hadoop obj存放在hadoop变量中
    常用的name有 khan, taihang, mulan ..
    """
    for path in glob.iglob(os.path.expanduser(os.path.join(start_path, '*hadoop*'))):
        if not os.path.isdir(path):
            continue
        for dirpath, dirnames, filenames in os.walk(path):
            if not dirpath.endswith('bin'):
                continue
            if 'hadoop' in filenames and os.path.isfile(
                    os.path.join(dirpath, '..', 'conf', 'hadoop-site.xml')):
                bin_path = os.path.join(dirpath, 'hadoop')
                LOGGER.info('find hadoop %s' % bin_path)
                a_hadoop = Hadoop(bin_path)
                hadoop[a_hadoop.name] = a_hadoop


find_hadoop_clients()

hdfs = HDFS(hadoop)
