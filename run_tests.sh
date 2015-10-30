#!/bin/bash

postgrest_bin='unknown'
unamestr=`uname`
ver='0.2.12.0'
dir='postgrest'

if [[ "$unamestr" == 'Linux' ]]; then
  postgrest_bin="postgrest-$ver-linux"
elif [[ "$unamestr" == 'Darwin' ]]; then
  postgrest_bin="postgrest-$ver-osx"
fi

if [[ "$postgrest_bin" == "unknown" ]]; then
  echo "Platform $unamestr is not supported by the postgrest binaries."
fi

echo "Initiating PostgREST server..."
./$dir/$postgrest_bin -d $1 -U diogo -a diogo -p 8888 --jwt-secret segredo > logs/postgrest.log 2>&1 &
echo "Running tests"
sleep 1
echo "Terminating PostgREST server..."
killall $postgrest_bin
echo "Done."
