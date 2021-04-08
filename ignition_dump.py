#!/usr/bin/env python3

# Mostly copied from https://gist.github.com/sjenning/04dedeff2594c09ef1d8292e7b1eaae7

import json
import os
import sys
import base64
from urllib.parse import unquote

ign_file = open(sys.argv[1])
ign_json = json.load(ign_file)
ign_file.close()
for file in ign_json['storage']['files']:
    path = file['path']
    if 'contents' in file:
        datatype, data = file['contents']['source'].split(',')
        os.makedirs('ign-root' + os.path.dirname(path), exist_ok=True)
        out_file = open('ign-root' + path, "wb")
        try:
            if datatype == "data:text/plain" or datatype == 'data:':
                out_file.write(unquote(data).encode('utf-8'))
            else:
                out_file.write(base64.b64decode(data))
        except:
            print(out_file, "failed", datatype)
        out_file.close()
