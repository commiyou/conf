#!/bin/bash
ping -c 5 baidu.com && exit 0
nmcli radio wifi off
sleep 0.1
nmcli radio wifi on
