import numpy as np
import pandas as pd
from pipetools import *


def p(idx=0):
    """percentile of sys.stdin"""
    ps = range(0, 100, 5)
    for p, reuslt in zip(np.percentile(list(map(float, stdin)), ps)):
        print(p, result, sep="\t")


def split(line):
    return list(map(str.strip, line.strip().split("\t")))


def divide(p1, p2, percentage=False):
    if p2 == 0:
        return "nan"
    if percentage:
        return f"{{:.{2}%}}".format(float(p1) / float(p2))
    return f"{{:.{2}f}}".format(float(p1) / float(p2))


n = int(x)
j = json.loads(stdin)
f = x.split()
ll = split(x)
d = defaultdict(list)
c = Counter()
desc = pd.read_csv(stdin, sep="\t").describe()
