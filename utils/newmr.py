# -*- coding: utf-8 -*-
from __future__ import unicode_literals

import collections
import ConfigParser
import datetime
import glob
import itertools
import json
import logging
import os
import pipes
import re
import subprocess
import sys
import tarfile
import tempfile
from collections import defaultdict
from io import BytesIO

logging.basicConfig()
LOGGER = logging.getLogger(__name__)
LOGGER.setLevel(logging.DEBUG)

__STREAMING_JOB_PARAMS = {}


class _Missing(object):
    def __repr__(self):
        return "no value"

    def __reduce__(self):
        return "_missing"


_missing = _Missing()


class cached_property(property):
    """A decorator that converts a function into a lazy property.  The
    function wrapped is called the first time to retrieve the result
    and then that calculated result is used the next time you access
    the value::
        class Foo(object):
            @cached_property
            def foo(self):
                # calculate something important here
                return 42
    The class has to have a `__dict__` in order for this property to
    work.
    """

    # implementation detail: A subclass of python's builtin property
    # decorator, we override __get__ to check for a cached value. If one
    # chooses to invoke __get__ by hand the property will still work as
    # expected because the lookup logic is replicated in __get__ for
    # manual invocation.

    def __init__(self, func, name=None, doc=None):
        self.__name__ = name or func.__name__
        self.__module__ = func.__module__
        self.__doc__ = doc or func.__doc__
        self.func = func

    def __set__(self, obj, value):
        obj.__dict__[self.__name__] = value

    def __get__(self, obj, type=None):
        if obj is None:
            return self
        value = obj.__dict__.get(self.__name__, _missing)
        if value is _missing:
            value = self.func(obj)
            obj.__dict__[self.__name__] = value
        return value


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
    """
    使用 keys, capacity, memory, tasks, failures_percent 来设置，根据mapper/reducer自动设置
    """
    D_GENERIC_OPTIONS = {
        'job_name': 'mapred.job.name',
        'job_queue': 'mapred.job.queue.name',
        'job_priority': 'mapred.job.priority',
        'partition_keys': 'num.key.fields.for.partition',
        'compress': 'mapred.output.compress',
    }

    def __init__(
            self,
            enable=None,
            owner=None,
            files=None,
            dirs=None,
            archives=None,
            cmdenvs=None,
            partitioner=None,
            hadoop=None,
            python_bin=None,
            hdfs_python_bin=None,
            local_python_bin=None,
            multiple_output=None,
            generic_options=None,  # list of args. [ '-libjars 1.jar', ... ]
            streaming_options=None,
            **kwargs):
        """TODO: to be defined1. """

        assert owner

        self.owner = owner
        self.enable = enable

        self._files = files
        self._dirs = dirs or []
        self._archives = archives or []
        self._hadoop = hadoop

        self._python_bin = python_bin
        self._hdfs_python_bin = hdfs_python_bin
        self._local_python_bin = local_python_bin
        self.generic_options = generic_options
        self.streaming_options = streaming_options
        self._kwargs = kwargs
        self._cmdenvs = cmdenvs
        self._partitioner = partitioner
        self.multiple_output = multiple_output or False

        self._script_file_name = util.filename()
        self.dag = DAG(self)
        self.time = date.current()
        self.date = date.today()
        self._finish = None
        self._build = None

    def build(self, func):
        self._build = func

    def finish(self, func):
        self._finish = func

    @cached_property
    def partitioner(self):
        return self._partitioner or 'org.apache.hadoop.mapred.lib.KeyFieldBasedPartitioner'

    @cached_property
    def outputformat(self):
        if self.multiple_output:
            return 'org.apache.hadoop.mapred.lib.SuffixMultipleTextOutputFormat'
        return None

    @property
    def python_bin(self):
        if util.is_mrjob():
            return self.hdfs_python_bin
        else:
            return self.local_python_bin

    @cached_property
    def hdfs_python_bin(self):
        return self._hdfs_python_bin or self._python_bin or 'python'

    @cached_property
    def local_python_bin(self):
        return self._local_python_bin or self._python_bin or 'python'

    @property
    def dirs(self):
        return util.to_list(self._dirs)

    @property
    def files(self):
        files_set = set()
        files = util.to_list(self._files) + ['*.py', "*.sh", "*.conf"]
        for filename in files:
            if '*' in filename or '[' in filename or '?' in filename:
                file_list = glob.glob(os.path.expanduser(filename))
                for f in file_list:
                    files_set.add(f)
            else:
                if not os.path.isfile(filename):
                    raise IOError("No such file or directory: '%s'" % filename)
                files_set.add(filename)

        return sorted(files_set)

    @cached_property
    def hadoop(self):
        if self._hadoop and os.path.isfile(self._hadoop):
            return Hadoop(self._hadoop)
        elif self._hadoop:
            return HADOOP_CLIENTS.get(self._hadoop, None)
        else:
            return None

    @cached_property
    def archives(self):
        """
        -archives
        There is bug with passing symlink name for -files and -archives options.
        See MAPREDUCE-787
        """
        archives_set = set([x for x in util.to_list(self._archives) if "#" not in x])
        for _dir in self.dirs:
            archives_set.add(util.make_archive(_dir))
        return sorted(archives_set)

    @cached_property
    def cache_archives(self):
        """
        """
        archives_set = set([x for x in self._archives if "#" in x])
        return sorted(archives_set)

    def vertex(self,
               name=None,
               successors=None,
               inputs=None,
               input_dones=None,
               output=None,
               output_done=None,
               generic_options=None,
               streaming_options=None,
               enable=None,
               python_bin=None,
               local_python_bin=None,
               hdfs_python_bin=None,
               **kwargs):
        """
        cat_output, 忽略其他参数，只设置cat output, 用于这一步有output时,跳过执行
        """

        def bind_func(func):
            self.dag.add_vertex(
                name=name,
                func=func,
                successors=successors,
                inputs=inputs,
                input_dones=input_dones,
                output=output,
                output_done=output_done,
                enable=enable,
                python_bin=python_bin,
                local_python_bin=local_python_bin,
                hdfs_python_bin=hdfs_python_bin,
                **kwargs)
            return func

        return bind_func

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

    @cached_property
    def inputs(self):
        return self.dag.inputs

    @cached_property
    def outputs(self):
        return self.dag.outputs

    @cached_property
    def output(self):
        return self.dag.outputs[-1]

    @cached_property
    def output_done(self):
        return self.dag.vertexes[-1].output_done

    @cached_property
    def cmdenvs(self):
        cmdenvs = dict(self._cmdenvs or {})
        if 'PYTHONPATH' not in cmdenvs:
            cmdenvs['PYTHONPATH'] = '.'
        else:
            cmdenvs['PYTHONPATH'] = cmdenvs['PYTHONPATH'] + ":."

        return cmdenvs

    @cached_property
    def job_project(self):
        return self._kwargs.get('job_project', util.filename(util.dirname()))

    @cached_property
    def job_module(self):
        return self._kwargs.get('job_module', util.filename())

    @cached_property
    def job_type(self):
        return self._kwargs.get('job_type', 'diaoyan')

    @cached_property
    def job_name(self):
        return "[%s][%s][%s][%s]@%s" % (self.job_type, self.job_project, self.job_module,
                                        self.owner, self.date)

    def hadoop_args(self):
        args = [self.hadoop.bin, "streaming"]
        for k in self.D_GENERIC_OPTIONS:
            if k in self._kwargs:
                args += ['-D', '%s=%s' % (self.D_GENERIC_OPTIONS[k], self._kwargs[k])]
            elif hasattr(self, k):
                args += ['-D', '%s=%s' % (self.D_GENERIC_OPTIONS[k], getattr(self, k))]

        args += self.dag.hadoop_args()

        if self.generic_options:
            args += self.generic_options

        # resource probe  http://wiki.baidu.com/pages/viewpage.action?pageId=144094629
        args += ["-D", 'abaci.squeezer.resource.probe.log.enable=true']
        args += ["-D", 'abaci.squeezer.enable=true']
        args += ["-D", 'abaci.squeezer.resource.probe=true']

        if self.files:
            args += ["-files", ",".join(self.files)]

        if self.archives:
            args += ["-archives", ','.join(self.archives)]
        """
        if self.partitioner:
            args += ['-partitioner', self.partitioner]

        """
        if self.streaming_options:
            args += self.streaming_options

        if self.cache_archives:
            args += itertools.chain(*map(lambda x: ['-cacheArchive', x], self.cache_archives))

        for k, v in self.cmdenvs.iteritems():
            args += ['-cmdenv', '%s=%s' % (k, v)]

        args += ['-partitioner', self.partitioner]
        if self.outputformat:
            args += ['-outputformat', self.outputformat]

        args += ['-input', self.inputs[-1]]
        # use the last node's output
        args += ['-output', self.output]
        args += ['-mapper', 'cat']
        args += ['-reducer', 'cat']
        return args

    def run_hadoop(self):

        self.status = 'prepare hadoop'
        args = self.hadoop_args()
        util.info('run hadoop> %s', util.cmd_line(args))
        for _output in self.outputs:
            self.hadoop.rmr(_output)
        self.status = 'run hadoop'
        util.run_shell(args)
        self.status = 'touch manifest'
        for _output in self.outputs:
            self.hadoop.touchz(_output + '/@manifest')
        self.status = 'make done'
        for vertex in self.dag.vertexes:
            vertex.mkdone()

        self.status = 'run finish'
        if self._finish:
            self._finish()
        self.status = 'done'

    def cli(self):
        pass

    def _fix_MAPREDUCE_787(self):
        for _dir in self.dirs:
            _dirname = os.path.basename(_dir)
            util.info('fix mapreduce787, creating dir %s' % _dirname)
            if os.path.exists(_dirname):
                util.warn('dir %s already exists' % _dirname)
                continue
            elif os.path.exists(_dirname + '.tar.gz'):
                util.run_shell('ln -s %s.tar.gz/%s %s' % (_dirname, _dirname, _dirname))
            else:
                util.warn('dir %s or is archive not exists' % _dirname)

        for _archive in self._archives:
            if '#' in _archive:
                continue
            _archive_name = os.path.basename(_archive)
            for tar_suffix in ('.tar.gz', '.tar.Z', '.tar.bz2', '.tar.lzma', '.tar.xz'):
                if _archive_name.endswith(tar_suffix):
                    _target_name = '.'.join(_archive_name.split('.')[:-2])
                else:
                    _target_name = '.'.join(_archive_name.split('.')[:-1])
            if os.path.exists(_target_name):
                util.warn('dir %s already exists' % _target_name)
                continue
            elif os.path.exists(_archive_name):
                util.run_shell('ln -s %s/%s %s' % (_archive_name, _target_name, _target_name))
            else:
                util.warn('dir %s or is archive not exists' % _target_name)

    def run(self):
        if sys.argv[1] == 'run':
            vertex_name = sys.argv[2]
            util.info('run vertex %s' % vertex_name)
            if util.is_mrjob():
                self._fix_MAPREDUCE_787()
            return self.dag.run(vertex_name, sys.argv[3:])
        elif sys.argv[1] == 'hadoop':
            util.info('run hadoop')
            return self.run_hadoop()
        elif sys.argv[1] == 'hadoop_cmd':
            print util.cmd_line(self.hadoop_args())
        elif sys.argv[1] == 'local':
            self.run_local()
        elif sys.argv[1] == 'vertex':
            if len(sys.argv) > 2:
                vertex_name = sys.argv[2]
                if len(sys.argv) > 3:
                    op = sys.argv[3]
                    attr = getattr(self.dag.all_vertexes[vertex_name], op)
                    if hasattr(attr, '__call__'):
                        attr()
                    else:
                        print attr
                else:
                    self.dag.all_vertexes[vertex_name].show()
            else:
                for vertex in self.dag.vertexes:
                    vertex.show()
        elif sys.argv[1] == 'output':
            if len(sys.argv) > 2:
                vertex_name = sys.argv[2]
                output_done = self.dag.all_vertexes[vertex_name].output_done
                output = self.hadoop.readdone(output_done)[-1]
                if len(sys.argv) > 3:
                    suffix = sys.argv[3]
                    self.hadoop.cat2file(os.path.join(output, 'part*' + suffix))
                else:
                    self.hadoop.cat2file(output)

            else:
                vertex_name = self.out
                if len(sys.argv) > 3:
                    op = sys.argv[3]
                    attr = getattr(self.dag.all_vertexes[vertex_name], op)
                    if hasattr(attr, '__call__'):
                        attr()
                    else:
                        print attr
                else:
                    self.dag.all_vertexes[vertex_name].show()
        else:
            print self.finish
            print getattr(self, sys.argv[1])
            try:
                attr = getattr(self, sys.argv[1])
            except AttributeError:
                raise Exception('error args %r' % sys.argv)
            attr()

    def schedule(self):
        self.build()
        self.run_local()
        self.run_hadoop()
        self.finish()


class Vertex(object):
    D_GENERIC_OPTIONS = dict(MRJob.D_GENERIC_OPTIONS)
    D_GENERIC_OPTIONS.update(
        dict(
            partitioner='mapred.hce.partitioner',
            input='mapred.input.dir',
            output='mapred.output.dir',
            mapper='stream.reduce.streamprocessor',
            reducer='stream.map.streamprocessor'))

    def __init__(self,
                 dag,
                 name=None,
                 func=None,
                 inputs=None,
                 input_dones=None,
                 output_root=None,
                 output=None,
                 output_done=None,
                 successors=None,
                 enable=None,
                 python_bin=None,
                 local_python_bin=None,
                 hdfs_python_bin=None,
                 **kwargs):
        """
        args:
            func : python func or None
            su
        """
        self._name = name
        self.dag = dag
        self.func = func
        self._successors = successors
        self._inputs = inputs
        self._input_dones = input_dones
        self._output_root = output_root
        self._output = output
        self._output_done = output_done
        self._enable = enable
        self._kwargs = kwargs
        self._python_bin = python_bin
        self._hdfs_python_bin = hdfs_python_bin
        self._local_python_bin = local_python_bin

    def show(self):
        print 'vertex %s, "%s", enabled %s, args:' % (self.id, self.name, self.enable)
        print '\tnode_type -> %s' % self.node_type
        print '\tsuccessors -> %s' % self.successors
        print '\tcmd -> %s' % self.streamprocessor
        print '\tinputs -> %s' % self.inputs
        print '\toutput -> %s' % self.output
        print '\toutput_done -> %s' % self.output_done
        print '\thadoop_args -> %s' % self.hadoop_args()

    @cached_property
    def python_bin(self):
        if util.is_mrjob():
            return self.hdfs_python_bin
        else:
            return self.local_python_bin

    @property
    def cat_output(self):
        """
        如果有设置了output,且cat_output为True，则跳过执行func，执行cat output
        """
        return self._kwargs.get('cat_output', None) and (self._output or self._output_root)

    @property
    def enable(self):
        """
        vertex 默认使用job初始化的enbale参数，若都未设置，默认True
        """
        enable = self._enable
        if enable is None:
            enable = self.dag.job.enable
        if enable is None:
            enable = True

        return enable

    @cached_property
    def hdfs_python_bin(self):
        return self._hdfs_python_bin or \
            self.dag.job.hdfs_python_bin \
            or self._python_bin or 'python'

    @cached_property
    def local_python_bin(self):
        return self._local_python_bin or \
            self.dag.job.local_python_bin or \
            self._python_bin or 'python'

    @cached_property
    def name(self):
        return self._name or self.func.func_name

    @property
    def node_type(self):
        if self.dag.in_degree_count[self.name] == 0:
            return 'map'
        else:
            return 'reduce'

    def __repr__(self):
        tmp = dict(name=self.name, enable=self.enable)
        return '<Vetex ' + dict.__repr__(tmp) + '>'

    @cached_property
    def successors(self):
        return util.to_list(self._successors)

    @cached_property
    def inputs(self):
        """
        inputs/dones 可以是一个函数
        """
        if self.cat_output:
            _path = self.dag.hadoop.readdone(self.output_done)[-1]
            util.info('vertext %s use cat output, %s => %s' % (_path, self.output_done))
            return _path

        if hasattr(self._inputs, '__call__'):
            inputs = util.to_list(self._inputs())
        else:
            inputs = list(util.to_list(self._inputs))
        util.debug('vertex %s get input from dones >' % self.name)
        if hasattr(self._input_dones, '__call__'):
            input_dones = util.to_list(self._input_dones())
        else:
            input_dones = util.to_list(self._input_dones)
        for _done in input_dones:
            _path = self.dag.hadoop.readdone(_done)[-1]
            util.debug('%s => %s' % (_path, _done))
            inputs.append(_path)
        return inputs

    @cached_property
    def output(self):
        if self.cat_output:
            return None

        if hasattr(self._output, '__call__'):
            return self._output()
        elif self._output:
            return self._output
        if self._output_root:
            return os.path.join(self._output_root, util.filename(util.dirname()),
                                os.path.splitext(util.filename())[0], self.name,
                                str(self.dag.job.date))
        return None

    @cached_property
    def output_done(self):
        if not self._output and not self._output_root:
            return None
        if self._output_done:
            return self._output_done
        if self._output_done is None:
            base_dir = util.dirname(self.output)
            if self.name in base_dir.rstrip('/').split('/')[-1]:
                # output path有区分度，可以辨识done
                return os.path.join(base_dir, 'done.txt')
            else:
                return os.path.join(base_dir, self.name + '_done.txt')
        return None

    def mkdone(self):
        if not self.output_done:
            return
        if hasattr(self.output_done, '__call__'):
            return self.output_done()
        else:
            self.dag.hadoop.mkdone(self.output, self.output_done)

    @property
    def streamprocessor(self):
        if self.cat_output:
            return 'cat'
        else:
            return util.hadoop_cmd_line(
                [self.hdfs_python_bin,
                 util.filename(), 'run', self.func.func_name])

    @property
    def id(self):
        return [x.name for x in self.dag.vertexes].index(self.name)

    def hadoop_args(self):
        args = []
        vertex_id = self.id
        args += [
            '-D',
            'stream.%s.streamprocessor.%s=%s' % (self.node_type, vertex_id, self.streamprocessor)
        ]
        if self.successors:
            successors_id = map(
                str, [[x.name for x in self.dag.vertexes].index(y) for y in self.successors])
            args += [
                '-D',
                'abaci.dag.next.vertex.list.%s=%s' % (vertex_id, ','.join(successors_id))
            ]

        keys = self._kwargs.get('keys', None)
        if keys is not None:
            args += [
                '-D',
                'stream.num.%s.output.key.fields.%s=%s' % (self.node_type, vertex_id, keys)
            ]

        capacity = self._kwargs.get('capacity', None)
        if capacity is not None:
            args += ['-D', 'mapred.job.%s.capacity.%s=%s' % (self.node_type, vertex_id, capacity)]

        memory = self._kwargs.get('memory', None)
        if memory is not None:
            args += ['-D', 'mapred.%s.memory.limit.%s=%s' % (self.node_type, vertex_id, memory)]
            # fix streamoverhce job, http://wiki.baidu.com/pages/viewpage.action?pageId=144094629
            args += ['-D', 'hadoop.hce.memory.limit.%s=%s' % (vertex_id, memory)]

        tasks = self._kwargs.get('tasks', None)
        if tasks is not None:
            args += ['-D', 'mapred.%s.tasks.%s=%s' % (self.node_type, vertex_id, tasks)]

        failures_percent = self._kwargs.get('failures_percent', None)
        if failures_percent is not None:
            args += [
                '-D',
                'mapred.max.%s.failures.percent.%s=%s' % (self.node_type, vertex_id,
                                                          failures_percent)
            ]

        for k in self._kwargs:
            if k in self.D_GENERIC_OPTIONS:
                args += [
                    '-D',
                    '%s.%s=%s' % (self.D_GENERIC_OPTIONS[k], vertex_id, self._kwargs[k])
                ]

        if self.inputs:
            args += [
                '-D',
                '%s.%s=%s' % (self.D_GENERIC_OPTIONS['input'], vertex_id, ','.join(self.inputs))
            ]
        if self.output:
            args += ['-D', 'abaci.dag.vertex.commit.output.%s=true' % vertex_id]
            args += ['-D', '%s.%s=%s' % (self.D_GENERIC_OPTIONS['output'], vertex_id, self.output)]

        util.debug("vertex %s, %s, %s' hadoop args >\n %s" % (vertex_id, self.node_type, self.name,
                                                              util.cmd_line(args)))
        return args

    def run(self, args=[]):
        # TODO, func with args
        return self.func(*args)


class DAG(object):
    def __init__(self, job):
        # adjacency list
        self.all_vertexes = {}
        self.job = job
        self.in_degree_count = defaultdict(int)
        self.out_degree_count = defaultdict(int)

    @property
    def hadoop(self):
        return self.job.hadoop

    def add_vertex(self,
                   name=None,
                   successors=None,
                   func=None,
                   inputs=None,
                   input_dones=None,
                   output=None,
                   output_done=None,
                   generic_options=None,
                   streaming_options=None,
                   enable=None,
                   hadoop=None,
                   **kwargs):
        vertex = Vertex(
            dag=self,
            name=name,
            func=func,
            successors=successors,
            inputs=inputs,
            input_dones=input_dones,
            output=output,
            output_done=output_done,
            enable=enable,
            hadoop=hadoop,
            **kwargs)
        if vertex.name in self.all_vertexes:
            raise Exception('vertex %s is already defined!' % vertex.name)
        self.all_vertexes[vertex.name] = vertex
        if vertex.enable and successors:
            successors = util.to_list(successors)
            for n in successors:
                self.out_degree_count[vertex.name] += 1
                self.in_degree_count[n] += 1

    @cached_property
    def vertexes(self):
        """
        enable的vertex list, 按照拓扑排序
        """
        visited_nodes = set()
        li = []

        def dfs(graph, start_node_name):
            for end_node_name in graph[start_node_name].successors:
                if graph[end_node_name].enable and end_node_name not in visited_nodes:
                    visited_nodes.add(end_node_name)
                    dfs(graph, end_node_name)
            li.append(start_node_name)

        for start_node_name, start_node in self.all_vertexes.iteritems():
            if start_node.enable and start_node_name not in visited_nodes:
                visited_nodes.add(start_node_name)
                dfs(self.all_vertexes, start_node_name)

        li.reverse()
        return map(lambda x: self.all_vertexes[x], li)

    @cached_property
    def vertex_ids(self):
        vertex_names = sorted([x.name for x in self.all_vertexes.values() if x.enable])
        return {name: index for (index, name) in enumerate(vertex_names)}

    @cached_property
    def undirected_adjacency_matrix(self):
        vertex_ids = self.vertex_ids
        uam = [[0] * len(vertex_ids)] * len(vertex_ids)
        for vertex_name, idx in vertex_ids.iteritems():
            vertex = self.all_vertexes[vertex_name]
            for adjacent_vertex_name in vertex.successors:
                adjacent_vertex_idx = vertex_ids[adjacent_vertex_name]
                uam[idx][adjacent_vertex_idx] = 1
                uam[adjacent_vertex_idx][idx] = 1

        return uam

    @cached_property
    def directed_adjacency_matrix(self):
        vertex_ids = self.vertex_ids
        dam = [[0] * len(vertex_ids)] * len(vertex_ids)
        for vertex_name, idx in vertex_ids.iteritems():
            vertex = self.all_vertexes[vertex_name]
            for adjacent_vertex_name in vertex.successors:
                adjacent_vertex_idx = vertex_ids[adjacent_vertex_name]
                dam[idx][adjacent_vertex_idx] = 1

        return dam

    @cached_property
    def weakly_connected_components(self):
        pass

    @cached_property
    def inputs(self):
        return reduce(lambda x, y: x + y, (x.inputs for x in self.vertexes), [])

    @cached_property
    def outputs(self):
        return [x.output for x in self.vertexes if x.output]

    def hadoop_args(self):
        args = []
        args += ['-D', 'abaci.is.dag.job=true']
        args += ['-D', 'abaci.dag.vertex.num=%s' % len(self.vertexes)]
        for i, vertex in enumerate(self.vertexes):
            args += vertex.hadoop_args()
        return args

    def run(self, vertex_name, args=[]):
        return self.all_vertexes[vertex_name].run(args)


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
        else:
            us = s

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
        if isinstance(fd, (str, unicode)):
            fd = open(fd)

        for line in fd:
            try:
                ll = util.split_str(line, delim=delim, encoding=encoding, errors=errors)
            except Exception as e:
                util.warn('fd<%s> read line error.\n line > %r\n%s', fd.name, line, e)
                max_failures_cnt -= 1
                if max_failures_cnt <= 0:
                    raise Exception("fd<%s> read line error too much!")

                continue
            yield ll

    def groupbyN(N, fd=sys.stdin, delim="\t", encoding="utf8", errors="strict"):
        def _key(x):
            k = x[:N]
            if N == 1:
                return k[0]
            else:
                return k

        return itertools.groupby(
            util.iter_and_split(fd=fd, delim=delim, encoding=encoding, errors=errors), key=_key)

    @staticmethod
    def get_path_from_done_file(done_file):
        pass

    @staticmethod
    def to_list(x):
        if x is None:
            return []
        if isinstance(x, list):
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
    def cmd_line(args):
        """build a command line that works in a shell.
        """
        args = [str(x) for x in args]

        return ' '.join(pipes.quote(x) for x in args)

    @staticmethod
    def hadoop_cmd_line(args):
        """Escape args of a command line in a way that Hadoop can process
        them."""

        return ' '.join(util.hadoop_escape_arg(arg) for arg in args)

    _HADOOP_SAFE_ARG_RE = re.compile(r'^[\w\./=-]*$')

    @staticmethod
    def hadoop_escape_arg(arg):
        """Escape a single command argument in a way that Hadoop can process it."""

        if util._HADOOP_SAFE_ARG_RE.match(arg):
            return arg
        else:
            return "'%s'" % arg.replace("'", r"'\''")

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
        util.debug('run shell > %r' % args)
        # return subprocess.check_call(cmd, shell=shell, cwd=cwd, env=env)
        if return_stdout:
            proc = subprocess.Popen(args, shell=shell, cwd=cwd, env=env, stdout=subprocess.PIPE)
        else:
            proc = subprocess.Popen(args, shell=shell, cwd=cwd, env=env)
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
    def is_mrjob():
        return os.getenv('mapred_job_name', None) is not None

    @staticmethod
    def dumpu(obj, indent=None):
        """
        dump obj to unicode, obj is unicode
        """
        string = json.dumps(obj, ensure_ascii=False, cls=SetEncoder, indent=indent)
        return string

    @staticmethod
    def dumps(obj, encoding=None, errors="strict", indent=None):
        """
        dump obj to string, obj is unicode
        """
        if encoding is None:
            encoding = 'utf8'
        return util.dumpu(obj, indent=indent).encode(encoding=encoding, errors=errors)

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
                tmp.append(util.dumpu(arg))
            elif isinstance(arg, (int, float)):
                tmp.append(str(arg))
            elif arg is None:
                tmp.append(str(arg))
            else:
                tmp.append(arg)

        s = "%s%s" % (delim.join(tmp), suffix)
        return s.encode(encoding=encoding, errors=errors)

    @staticmethod
    def divide(a, b, default="null", percent=False):
        """
        safe a/b
        """
        a = float(a)
        b = float(b)
        try:
            res = a / b
        except ZeroDivisionError:
            return default
        if percent:
            return '%.2f%%' % (res * 100)
        return '%.2f' % res

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

    @staticmethod
    def make_archive(path, archive_path=None):
        """
        make archive to archive_path or under current path
        ~/dir  => ./dir.tar.gz ( dir/xxx...)
        """
        path = os.path.expanduser(path)
        if not archive_path:
            archive_path = os.path.basename(path) + ".tar.gz"
        else:
            archive_path = os.path.expanduser(archive_path)

        tar = tarfile.open(archive_path, "w:gz", dereference=True, debug=3)
        tar.add(path, arcname=os.path.basename(path))
        tar.close()

        return archive_path

    @staticmethod
    def filename(path=None):
        if not path:
            path = os.path.abspath(sys.argv[0])
        return os.path.basename(path)

    @staticmethod
    def dirname(path=None):
        if not path:
            path = os.path.abspath(sys.argv[0])
        target = os.path.dirname(path)
        if target.startswith('./'):
            target = os.path.abspath(target)
        return target


util = Util


class date(object):
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
            start, end = end, start

        return [self + x for x in range(start, end)]

    @classmethod
    def current(cls):
        """
        datetime只设置为当前time
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
        return cls.current().strftime("%Y%m%d%H%M%S")

    def strftime(self, format=None):
        return self.datetime.strftime(format or self.format)

    def __str__(self):
        return self.datetime.strftime(self.format)

    def __repr__(self):
        return '%s(%s,%s,%s,%s,%s,%s)' % (
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


cluster_conf = """
[adx]
ugi = 
fs = 
queue = 
prefix = 

"""


class Hadoop(object):
    def __init__(self, bin_path=None, **kwargs):
        self.bin = bin_path
        self._kwargs = kwargs

    def __eq__(self, other):
        return self.ugi == other.ugi and self.fs == other.fs and self.queue == other.queue

    @cached_property
    def conf(self):
        if not self.bin:
            return None
        return os.path.join(util.dirname(util.dirname(self.bin)), 'conf', 'hadoop-site.xml')

    @cached_property
    def name(self):
        """
        return usr@fsname[#queue]
        """
        if 'name' in self._kwargs:
            return self._kwargs['name']

        cluster_name = "-".join(self.fs.split('/')[-1].split('-')[:-1])

        name = self.user + "@" + cluster_name
        if self.queue and self.queue != 'default':
            name += "#" + self.queue
        return name

    @cached_property
    def fs(self):
        return self._kwargs.get('fs', self.property.get('fs.default.name', None))

    @cached_property
    def queue(self):
        return self._kwargs.get('queue', self.property.get('mapred.job.queue.name', 'default'))

    @cached_property
    def ugi(self):
        return self._kwargs.get('ugi', self.property.get('hadoop.job.ugi', None))

    @cached_property
    def prefix(self):
        return self._kwargs.get('prefix', None)

    @cached_property
    def user(self):
        return self.ugi.split(",")[0]

    @cached_property
    def password(self):
        return self.ugi.split(",")[1]

    @cached_property
    def property(self):
        if not self.conf:
            return {}
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
        return '<Hadoop %s bin=%s>' % (self.name, self.bin)

    def _invoke_hadoop(self, args, ok_returncodes=None, return_stdout=False):
        util.debug('hadoop %s start to run cmd > %s' % (self.name, util.cmd_line(args)))
        args = [self.bin] + args
        return util.run_shell(args, ok_returncodes=ok_returncodes, return_stdout=return_stdout)

    def path(self, paths):
        """get hdfs:// format of path"""
        if isinstance(paths, (str, unicode)):
            if paths.startswith('hdfs://'):
                # hdfs://xxxxxx.com/app/ecom/fcr/youbin/test
                return paths
            elif paths.startswith('/'):
                # /app/ecom/fcr/youbin/test
                return self.fs + paths
            else:
                #  youbin/test
                return self.fs + os.path.join(self.prefix, paths)
        else:
            # [ /app/ecom/fcr/youbin/test, youbin/test, .. ]
            return map(self.path, paths)

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
                result_files.append(self.path(path))
            if return_dir and file_type == 'dir':
                result_files.append(self.path(path))
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

    def cat2file(self, filename, target_file=None):
        """
        cat 到 target_file/stdout 中
        """
        if not target_file:
            return self._invoke_hadoop(['fs', '-cat', filename])
        else:
            return util.run_shell(' '.join([self.bin, 'fs', '-cat', filename, '>', target_file]))

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
        self._invoke_hadoop(['fs', '-getmerge', path, local_path])

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
        paths = util.to_list(paths)
        fd = tempfile.NamedTemporaryFile(suffix="done.txt")
        if "id" not in kwargs:
            kwargs["id"] = date.timestamp()
        if as_json:
            content = dict(kwargs)
            content.update(input=paths)
            content_str = util.dumpu(content)
        else:
            if set(kwargs.keys()) - {'id'}:
                util.warn('mkdone %s has unused kwargs %r' % (done_path, kwargs))
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
                inputs = map(self.path, ll[0].split(','))
                lines.append(','.join(inputs))
            else:
                if "input" not in js:
                    raise Exception("parse done %s error. line  %r" % (done_path, line))

                inputs = js['input']
                inputs = util.to_list(inputs)
                inputs = map(self.path, inputs)
                lines.append(",".join(inputs))
        return lines


hadoop = HADOOP_CLIENTS = Storage()


def find_hadoop_clients(start_path='~'):
    """
    从start_path目录中寻找符合条件的(bin/hadoop且有conf/hadoop-site.xml) hadoop
    寻找到的hadoop以 name: Hadoop obj存放在hadoop变量中
    常用的name有 khan, taihang, mulan ..
    """
    import io
    config = ConfigParser.ConfigParser()
    config.readfp(io.StringIO(cluster_conf))
    tmp_hadoops = []
    for _name in config.sections():
        _kwargs = dict(config.items(_name))
        _kwargs['name'] = _name
        _hadoop = Hadoop(**_kwargs)
        tmp_hadoops.append(_hadoop)

    for path in glob.iglob(os.path.expanduser(os.path.join(start_path, '*hadoop*'))):
        if not os.path.isdir(path):
            continue
        for dirpath, dirnames, filenames in os.walk(path):
            if not dirpath.endswith('bin'):
                continue
            if 'hadoop' in filenames and os.path.isfile(
                    os.path.join(dirpath, '..', 'conf', 'hadoop-site.xml')):
                bin_path = os.path.join(dirpath, 'hadoop')
                _hadoop = Hadoop(bin_path)
                for _tmp_hadoop in tmp_hadoops:
                    if _tmp_hadoop == _hadoop:
                        _hadoop = Hadoop(bin_path, name=_tmp_hadoop.name)
                hadoop[_hadoop.name] = _hadoop

    for _hadoop in tmp_hadoops:
        if _hadoop.name not in hadoop:
            hadoop[_hadoop.name] = _hadoop


find_hadoop_clients()
util.info(util.dumpu(hadoop, indent=4))
