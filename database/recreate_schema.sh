#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pg_dump -O -s $1 > $DIR/schema.sql
