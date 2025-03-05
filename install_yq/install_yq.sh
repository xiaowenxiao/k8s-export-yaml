#!/bin/bash

tar -zxvf yq_linux_amd64.tar.gz
chmod 744 yq_linux_amd64
mv yq_linux_amd64 /usr/bin/
ln -s /usr/bin/yq_linux_amd64 /usr/bin/yq
yq -V
