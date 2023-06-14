#!/usr/bin/env python3

# Delete leftover runnings older than 23 hour

import os
import subprocess
import sys


def delete_leftover_running(type: str):
    base_cmd = ['gcloud', 'compute', '--project',
                os.environ['GCP_PROJECT'], type]

    # get objects older than 23 hours with their names and zones
    # 23 hour is used instead of 1 day because cron job runs daily,
    # so there could be race conditions
    get_cmd = base_cmd + ['list', '--format', 'object value(name, zone)',
                          '--filter', 'creationTimestamp < -P23H']
    res = subprocess.run(get_cmd, capture_output=True,
                         check=True, text=True)

    delete_list = []
    for line in res.stdout.strip().split('\n'):
        # check if line is not empty
        if line:
            linesplit = line.split()
            delete_list.append({'name': linesplit[0],
                               'zone': linesplit[1]})

    if delete_list:
        print(f"{type} to be deleted: ", ', '.join(
            disk['name'] for disk in delete_list))
    else:
        print(f"no {type} to delete")

    for elem in delete_list:
        print(f'Deleting {type} = {elem["name"]}')
        delete_cmd = base_cmd + ['delete', elem['name'],
                                 '--zone', elem['zone'], '--quiet']
        subprocess.run(delete_cmd, check=True)


def main():
    if 'GCP_PROJECT' not in os.environ:
        print("GCP_PROJECT not set", file=sys.stderr)
        sys.exit(1)

    delete_leftover_running('instances')
    delete_leftover_running('disks')


if __name__ == "__main__":
    main()
