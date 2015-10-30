#!/bin/bash

endpoint=$1

echo "
---
- config:
  - testset: "${endpoint}"

- test:
  - name: "Basic get"
  - url: "/${endpoint}"
" > test/${endpoint}.yml
