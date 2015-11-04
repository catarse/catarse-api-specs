import subprocess
import click


@click.group()
def cli():
    pass


@cli.command()
def run_tests():
    subprocess.call(['./run_tests.sh'])


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
