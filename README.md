# Postgres CI Image Creation

Builds VM and container images for postgres CI, currently utilizing
[cirrus-ci](https://cirrus-ci.org/).

These images are used for, currently inofficial, postgres CI (see
https://github.com/anarazel/postgres/tree/ci and
https://github.com/anarazel/postgres/tree/aio)


## How to utilize

An example cirrus-ci use of these images is https://github.com/anarazel/postgres/tree/ci/.cirrus.yml


## How

The VM images are built using [packer](https://www.packer.io/), the container images using docker. The
built images are then stored within google cloud services, as cirrus-ci runs most of its instances within google cloud.


## Google Cloud Setup

Instructions for setting up this build pipeline are in [gcp_project_setup.txt](gcp_project_setup.txt).
