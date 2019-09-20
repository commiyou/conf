##!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import unicode_literals

import collections
import itertools
import json
import logging
import os
import sys
import urllib2
from collections import defaultdict

logging.basicConfig()
LOGGER = logging.getLogger(__name__)
LOGGER.setLevel(logging.DEBUG)
