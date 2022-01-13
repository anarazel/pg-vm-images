# Postgres CI Image Creation

Builds VM and container images for PostgreSQL CI, currently utilizing
[cirrus-ci](https://cirrus-ci.org/). See
[src/tools/ci/README](https://github.com/postgres/postgres/blob/master/src/tools/ci/README)
for more details.

An example cirrus-ci use of these images is Postgres' [.cirrus.yml](
https://github.com/postgres/postgres/blob/master/.cirrus.yml)


## How to use

Postgres' CI [README](https://github.com/postgres/postgres/blob/master/src/tools/ci/README)
explains how to enable CI utilizing these image for a repository.


## How it works

The VM images are built using [packer](https://www.packer.io/), the container images using docker. The
built images are then stored within google cloud services, as cirrus-ci runs most of its instances within google cloud.


## Google Cloud Setup

Instructions for setting up this build pipeline are in [gcp_project_setup.txt](gcp_project_setup.txt).
