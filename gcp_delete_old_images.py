#!/usr/bin/env python3

# Delete images older than 2 weeks, except if an image is the newest image in
# an image family

import json
import os
import subprocess
import sys


def delete_old_vm_images():
    print("Deleting VM images")

    base_cmd = ['gcloud', 'compute', '--project',
                os.environ['GCP_PROJECT'], 'images']

    # determine all families, no smarter way than
    # listing all images seems to exist
    families_cmd = base_cmd + ['list', '--format',
                               'object value(family)', '--no-standard-images']
    res = subprocess.run(families_cmd, capture_output=True,
                         check=True, text=True)
    families = set(res.stdout.split())

    # find the newest image for each family
    newest_family_members = set()
    for family in families:
        newest_cmd = base_cmd + ['describe-from-family', '--format',
                                 'object value(name)', family]
        res = subprocess.run(newest_cmd, capture_output=True,
                             check=True, text=True)
        newest_family_members.add(res.stdout.strip())

    # get all old images, including the newest image in a
    # family (will be skipped below)
    old_images_cmd = base_cmd + ['list', '--format', 'object value(name)',
                                 '--no-standard-images', '--filter',
                                 'creationTimestamp < -P2W']
    res = subprocess.run(old_images_cmd, capture_output=True,
                         check=True, text=True)
    old_images = res.stdout.split()

    # filter to-be-deleted images by the newest image in a family
    delete_images = []
    for old_image in old_images:
        if old_image in newest_family_members:
            print(f"not deleting {old_image}, it's the newest family member")
        else:
            delete_images.append(old_image)

    if len(delete_images) == 0:
        print("no VM images to delete")
        return

    print("deleting images: ", ', '.join(delete_images))

    # finally delete old images
    delete_cmd = base_cmd + ['delete', '--quiet'] + delete_images
    subprocess.run(delete_cmd, check=True)


def delete_old_docker_images_helper(delete_images, base_cmd,
                                    latest_images_manifests,
                                    with_tags=False):
    if not delete_images:
        print('no docker images to delete ' +
              ('with tags' if with_tags else 'without tags'))
        return

    delete_images = [f"{image['package']}@{image['version']}" for
                     image in delete_images]

    print('deleting docker images ' +
          ('with tags' if with_tags else 'without tags') +
          ':\n' + '\n'.join(delete_images))

    for image in delete_images:
        # Add '--delete-tags' when deleting images with tags, otherwise don't
        delete_cmd = base_cmd + ['delete', '--quiet'] + \
            (['--delete-tags', image] if with_tags else [image])
        subprocess.run(delete_cmd, check=True)


def get_manifests(images):
    latest_images_manifests = set()
    for image in images:
        podman_cmd = ['podman', 'manifest', 'inspect',
                      f'{image["package"]}@{image["version"]}']
        res = subprocess.run(podman_cmd, capture_output=True,
                             check=True, text=True)
        manifest = json.loads(res.stdout)

        if manifest.get('manifests', False):
            image_manifests = manifest['manifests']
            for image_manifest in image_manifests:
                latest_images_manifests.add(image_manifest['digest'])

    return latest_images_manifests


def delete_old_docker_images():
    print("\nDeleting docker images")
    base_cmd = ['gcloud', 'artifacts', 'docker', 'images']
    get_images_cmd = base_cmd + ['list',
                                 '--include-tags', '--format',
                                 'json(package,version,tags)',
                                 '--filter', 'createTime < -P2W',
                                 os.environ['GCP_REPO']]
    res = subprocess.run(get_images_cmd, capture_output=True,
                         check=True, text=True)
    old_images = json.loads(res.stdout)

    if len(old_images) == 0:
        print("no docker images to delete")
        return

    images_with_tags = []
    images_without_tags = []
    latest_images = []
    for image in old_images:
        if 'latest' in image['tags']:
            latest_images.append(image)
        elif image['tags']:
            images_with_tags.append(image)
        else:
            images_without_tags.append(image)

    # find the latest images' manifests
    latest_images_manifests = get_manifests(latest_images)

    # filter to-be-deleted images by the latest images' manifests
    images_without_tags_filtered = []
    for image in images_without_tags:
        if image['version'] in latest_images_manifests:
            print(f"Not deleting {image['package']}@{image['version']} " +
                  "because it is manifest of one of the latest images'")
        else:
            images_without_tags_filtered.append(image)

    # first we need to call delete images function with images_with_tags
    # because, images_without_tags depends on the images_with_tags and can't
    # be deleted if dependent image is not deleted yet.
    # So, first delete images_with_tags; then images_without_tags.
    delete_old_docker_images_helper(images_with_tags, base_cmd,
                                    latest_images_manifests,
                                    with_tags=True)
    delete_old_docker_images_helper(images_without_tags_filtered, base_cmd,
                                    latest_images_manifests)


def main():
    if 'GCP_PROJECT' not in os.environ or 'GCP_REPO' not in os.environ:
        print("GCP_PROJECT or GCP_REPO are not set", file=sys.stderr)
        sys.exit(1)

    delete_old_vm_images()
    delete_old_docker_images()


if __name__ == "__main__":
    main()
