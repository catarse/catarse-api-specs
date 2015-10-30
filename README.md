# Catarse API specification [![Circle CI](https://circleci.com/gh/catarse/catarse-api-specs.svg?style=svg)](https://circleci.com/gh/catarse/catarse-api-specs)

## Requirements

* Mac OS X or Ubuntu Linux
* PostgreSQL 9.4+ with default contrib extensions
* Python 2.7.10+
* [pyresttest](https://github.com/svanoort/pyresttest)

The scripts assume that you have a PostgreSQL running in your local environment
and that you have a database superuser with the same name as the user running the script.

You also need to be able to connect with any arbitrary PostgreSQL user without a password.

If you need to use a password to connect try setting up a [pgpass](http://www.postgresql.org/docs/current/static/libpq-pgpass.html) file.

## Running tests

If everything is installed and configured properly you should be able to run the entire suite
using the command:

```
./run_tests.sh
```

You can also pass one parameter with a different database name to use for testing.
The default name is **catarse_api_test**.

## Updating the database schema

There is a script recreate_schema.sh in the database directory
that will read a given database and store its schema in the file database/schema.sql
After modifying the development database you should run this script
and run the tests to check if everything is still working.

```
database/recreate_schema.sh database_name
```

## Adding tests

The tests are organized in files by endpoint, so you should
never test more than one endpoint per yml file.
Add the test file named after the endpoint you are testing, if you are
testing the endpoint **foo**, the test file will be **test/foo.yml**.

To bootstrap a basic get test against the foo endpoint use the command:

```
./generate_test.sh foo
```

