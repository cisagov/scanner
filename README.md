# pshtt, trustymail, and sslyze Scanner #

[![GitHub Build Status](https://github.com/cisagov/scanner/workflows/build/badge.svg)](https://github.com/cisagov/scanner/actions/workflows/build.yml)
[![CodeQL](https://github.com/cisagov/scanner/workflows/CodeQL/badge.svg)](https://github.com/cisagov/scanner/actions/workflows/codeql-analysis.yml)
[![Known Vulnerabilities](https://snyk.io/test/github/cisagov/scanner/badge.svg)](https://snyk.io/test/github/cisagov/scanner)

## Docker Image ##

[![Docker Pulls](https://img.shields.io/docker/pulls/cisagov/scanner)](https://hub.docker.com/r/cisagov/scanner)
[![Docker Image Size (latest by date)](https://img.shields.io/docker/image-size/cisagov/scanner)](https://hub.docker.com/r/cisagov/scanner)
[![Platforms](https://img.shields.io/badge/platforms-amd64-blue)](https://hub.docker.com/r/cisagov/scanner/tags)

This is a Docker container that uses
[domain-scan](https://github.com/18F/domain-scan) to scan domains
using [pshtt](https://github.com/cisagov/pshtt),
[trustymail](https://github.com/cisagov/trustymail), and
[sslyze](https://github.com/nabla-c0d3/sslyze).

This Docker container is intended to be run via
[cisagov/orchestrator](https://github.com/cisagov/orchestrator).

**N.B.:** The secrets in the `src/secrets` directory are only used
when testing via the `docker-compose.yml` composition.  Normally this
Docker container is run via the Docker composition in
[cisagov/orchestrator](https://github.com/cisagov/orchestrator), which
expects the secrets in a different location.

## Running ##

### Running with Docker ###

To run the `cisagov/scanner` image via Docker:

```console
docker run cisagov/scanner:1.3.6-rc.1
```

### Running with Docker Compose ###

1. Create a `docker-compose.yml` file similar to the one below to use [Docker Compose](https://docs.docker.com/compose/).

    ```yaml
    ---
    version: "3.7"

    services:
      scanner:
        image: cisagov/scanner:1.3.6-rc.1
        volumes:
          - type: bind
            source: <your_log_dir>
            target: /home/cisa/shared
    ```

1. Start the container and detach:

    ```console
    docker compose up --detach
    ```

## Using secrets with your container ##

This container also supports passing sensitive values via [Docker
secrets](https://docs.docker.com/engine/swarm/secrets/).  Passing sensitive
values like your credentials can be more secure using secrets than using
environment variables.  See the
[secrets](#secrets) section below for a table of all supported secret files.

1. To use secrets, create an `aws_config` file in [this
   format](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html):

    ```ini
    [default]
    aws_access_key_id=AKIAIOSFODNN7EXAMPLE
    aws_secret_access_key=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
    region=us-east-1
    output=json
    ```

1. Then add the secrets to your `docker-compose.yml` file:

    ```yaml
    ---
    version: "3.7"

    secrets:
      aws_config:
        file: ./secrets/aws_config

    services:
      scanner:
        image: cisagov/scanner:1.3.6-rc.1
        volumes:
          - type: bind
            source: <your_log_dir>
            target: /home/cisa/shared
        secrets:
          - source: aws_config
            target: aws_config
    ```

## Updating your container ##

### Docker Compose ###

1. Pull the new image from Docker Hub:

    ```console
    docker compose pull
    ```

1. Recreate the running container by following the [previous instructions](#running-with-docker-compose):

    ```console
    docker compose up --detach
    ```

### Docker ###

1. Stop the running container:

    ```console
    docker stop <container_id>
    ```

1. Pull the new image:

    ```console
    docker pull cisagov/scanner:1.3.6-rc.1
    ```

1. Recreate and run the container by following the [previous instructions](#running-with-docker).

## Image tags ##

The images of this container are tagged with [semantic
versions](https://semver.org) of the underlying example project that they
containerize.  It is recommended that most users use a version tag (e.g.
`:1.3.6-rc.1`).

| Image:tag | Description |
|-----------|-------------|
|`cisagov/scanner:1.3.6-rc.1`| An exact release version. |
|`cisagov/scanner:1.3`| The most recent release matching the major and minor version numbers. |
|`cisagov/scanner:1`| The most recent release matching the major version number. |
|`cisagov/scanner:edge` | The most recent image built from a merge into the `develop` branch of this repository. |
|`cisagov/scanner:nightly` | A nightly build of the `develop` branch of this repository. |
|`cisagov/scanner:latest`| The most recent release image pushed to a container registry.  Pulling an image using the `:latest` tag [should be avoided.](https://vsupalov.com/docker-latest-tag/) |

See the [tags tab](https://hub.docker.com/r/cisagov/scanner/tags) on Docker
Hub for a list of all the supported tags.

## Volumes ##

| Mount point | Purpose        |
|-------------|----------------|
| `/home/cisa/shared` |  Output |

## Ports ##

There are no ports exposed by this container.

<!-- The following ports are exposed by this container: -->

<!-- | Port | Purpose        | -->
<!-- |------|----------------| -->
<!-- | 8080 | Example only; nothing is actually listening on the port | -->

<!-- The sample [Docker composition](docker-compose.yml) publishes the -->
<!-- exposed port at 8080. -->

## Environment variables ##

### Required ###

There are no required environment variables.

<!--
| Name  | Purpose | Default |
|-------|---------|---------|
| `REQUIRED_VARIABLE` | Describe its purpose. | `null` |
-->

### Optional ###

| Name  | Purpose | Default |
|-------|---------|---------|
| `AWS_CONFIG_FILE` | The path to the configuration file containing the AWS credentials. | `null` |
| `AWS_PROFILE` | The AWS profile to use. | `null` |

## Secrets ##

| Filename     | Purpose |
|--------------|---------|
| aws_config | AWS credentials allowing read-only access to the Elasticsearch DMARC database in [this format](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html) |

## Building from source ##

Build the image locally using this git repository as the [build context](https://docs.docker.com/engine/reference/commandline/build/#git-repositories):

```console
docker build \
  --build-arg VERSION=1.3.6-rc.1 \
  --tag cisagov/scanner:1.3.6-rc.1 \
  https://github.com/cisagov/scanner.git#develop
```

## Cross-platform builds ##

To create images that are compatible with other platforms, you can use the
[`buildx`](https://docs.docker.com/buildx/working-with-buildx/) feature of
Docker:

1. Copy the project to your machine using the `Code` button above
   or the command line:

    ```console
    git clone https://github.com/cisagov/scanner.git
    cd scanner
    ```

1. Create the `Dockerfile-x` file with `buildx` platform support:

    ```console
    ./buildx-dockerfile.sh
    ```

1. Build the image using `buildx`:

    ```console
    docker buildx build \
      --file Dockerfile-x \
      --platform linux/amd64 \
      --build-arg VERSION=1.3.6-rc.1 \
      --output type=docker \
      --tag cisagov/scanner:1.3.6-rc.1 .
    ```

## Contributing ##

We welcome contributions!  Please see [`CONTRIBUTING.md`](CONTRIBUTING.md) for
details.

## License ##

This project is in the worldwide [public domain](LICENSE).

This project is in the public domain within the United States, and
copyright and related rights in the work worldwide are waived through
the [CC0 1.0 Universal public domain
dedication](https://creativecommons.org/publicdomain/zero/1.0/).

All contributions to this project will be released under the CC0
dedication. By submitting a pull request, you are agreeing to comply
with this waiver of copyright interest.
