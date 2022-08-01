#!/usr/bin/env python3

# Delete images older than 2 weeks, except if an image is the newest image in
# an image family

import os
import subprocess
import sys

if 'GCP_PROJECT' not in os.environ:
    print("GCP_PROJECT not set", file=sys.stderr)
    sys.exit(1)

base_cmd = ['gcloud', 'compute', '--project', os.environ['GCP_PROJECT'], 'images']

# determine all families, no smarter way than listing all images seems to exist
families_cmd = base_cmd + ['list', '--format', 'object value(family)', '--no-standard-images']
res = subprocess.run(families_cmd, capture_output = True, check=True, text=True)
families = set(res.stdout.split())

# find the newest image for each family
newest_family_members = set()
for family in families:
    newest_cmd = base_cmd + ['describe-from-family', '--format', 'object value(name)', family]
    res = subprocess.run(newest_cmd, capture_output = True, check=True, text=True)
    newest_family_members.add(res.stdout.strip())

# get all old images, including the newest image in a family (will be skipped below)
old_images_cmd = base_cmd + ['list', '--format', 'object value(name)', '--no-standard-images', '--filter', 'creationTimestamp < -P2W']
res = subprocess.run(old_images_cmd, capture_output = True, check=True, text=True)
old_images = res.stdout.split()

# filter to-be-deleted images by the newest image in a family
delete_images = []
for old_image in old_images:
    if old_image in newest_family_members:
        print(f"not deleting {old_image}, it's the newest family member")
    else:
        delete_images.append(old_image)

if len(delete_images) == 0:
    print("no images to delete")
    sys.exit(0)

print("deleting images: ", ', '.join(delete_images))

# finally delete old images
delete_cmd = base_cmd + ['delete', '--quiet'] + delete_images
subprocess.run(delete_cmd, check=True)
