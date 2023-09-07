# Postgres CI Image Creation

Builds VM and container images for PostgreSQL CI, currently utilizing
[cirrus-ci](https://cirrus-ci.org/). See
[src/tools/ci/README](https://github.com/postgres/postgres/blob/master/src/tools/ci/README)
for more details.

An example cirrus-ci use of these images is Postgres' [.cirrus.yml](
https://github.com/postgres/postgres/blob/master/.cirrus.yml)


## How to use

If you are contributing to Postgres, Postgres' CI
[README](https://github.com/postgres/postgres/blob/master/src/tools/ci/README)
explains how to enable CI utilizing these image for a repository.

If you are developing a different project that uses Cirrus CI, you might be
interested in using one of the BSD images. Here is an example using the NetBSD
image without Postgres:

```yaml
foo_task:
  compute_engine_instance:
    image_project: pg-ci-images
    image: family/pg-ci-netbsd-vanilla-9-2
    platform: netbsd
```

The following images are available:

-   FreeBSD images with Postgres are available in the family `pg-ci-freebsd-13`.
    (If you are looking for images without Postgres, just use FreeBSD's
    [official GCP images](https://cloud.google.com/compute/docs/images#freebsd).)

-   NetBSD and OpenBSD images are available both with and without Postgres,
    in families `pg-ci-{net,open}bsd-{vanilla,postgres}`.


## How it works

The VM images are built using [packer](https://www.packer.io/), the container images using docker. The
built images are then stored within google cloud services, as cirrus-ci runs most of its instances within google cloud.


## Google Cloud Setup

Instructions for setting up this build pipeline are in [gcp_project_setup.txt](gcp_project_setup.txt).
