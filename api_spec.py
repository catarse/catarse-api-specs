import subprocess
import click


@click.group()
def cli():
    pass


@cli.command()
@click.argument('name', default='api_test')
def run_tests(name):
    subprocess.call(['./run_tests.sh', name])


@cli.command()
@click.option('--name', help='database name')
def recreate_schema(name):
    subprocess.call(['./database/recreate_schema.sh', name])


@cli.command()
@click.option('--name', help='spec name')
def generate_test(name):
    subprocess.call(['./generate_test.sh', name])


if __name__ == '__main__':
    cli()
