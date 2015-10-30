#!/bin/bash

db=${1-'catarse_api_test'}
user=`whoami`
port=8888
exit_code=0

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

echo "Initiating database schema..."
dropdb --if-exists $db
createdb $db
psql $db < ./database/schema.sql > logs/schema_load.log 2>&1
psql $db < ./database/data.sql > logs/schema_load.log 2>&1

echo "Initiating PostgREST server..."
./$dir/$postgrest_bin -d $db -U $user -a $user -p $port --jwt-secret iksjhdfsdk > logs/postgrest.log 2>&1 &

echo "Running tests"
sleep 1
for f in test/*.yml
do
    echo "Running $f tests..."
    pyresttest http://localhost:$port $f
    if [[ $? -eq 1 ]]; then
        exit_code=1
    fi
done

echo "Terminating PostgREST server..."
killall $postgrest_bin
echo "Done."
exit $exit_code
