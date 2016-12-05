#!/bin/bash

adduser ubuntu
passwd ubuntu
usermod -aG wheel ubuntu
cd /home/ubuntu
mkdir -p  Desktop  Documents  Downloads  Music  Pictures  Public  Templates  Videos
chown ubuntu:ubuntu Desktop  Documents  Downloads  Music  Pictures  Public  Templates  Videos

