image_date := $(shell date +'%Y-%mt%d-%H-%M')

pre-commit:
	yamllint -c .yamllint-cirrus .cirrus.yml
#	FreeBSD
	packer validate \
	  -var gcp_project=pg-ci-images-dev \
	  -var "image_date=$(image_date)" \
	  -var "task_name=freebsd-13" \
	  packer/freebsd.pkr.hcl
#	Debian
	packer validate \
	  -var gcp_project=pg-ci-images-dev \
	  -var "image_date=$(image_date)" \
	  -var "task_name=bullseye" \
	  packer/linux_debian.pkr.hcl
#	Windows VS-2019 VM
	packer validate \
	  -var gcp_project=pg-ci-images-dev \
	  -var "image_date=$(image_date)" \
	  -var "task_name=windows-ci-vs-2019" \
	  packer/windows.pkr.hcl
#	Windows MinGW64 VM
	packer validate \
	  -var gcp_project=pg-ci-images-dev \
	  -var "image_date=$(image_date)" \
	  -var "task_name=windows-ci-mingw64" \
	  packer/windows.pkr.hcl
#	Windows VS-2019 Container
	packer validate \
	  -var gcp_project=pg-ci-images-dev \
	  -var "image_date=$(image_date)" \
	  -var "gcp_password=TEMPLATE_PASSWORD" \
	  -var "task_name=windows_ci_vs_2019" \
	  -var "docker_repo=us-docker.pkg.dev/pg-ci-images-dev/ci" \
	  -var "docker_server=us-docker.pkg.dev" \
	  -var "build_type=docker" \
	  packer/windows.pkr.hcl
#	Windows MinGW64 Container
	packer validate \
	  -var gcp_project=pg-ci-images-dev \
	  -var "image_date=$(image_date)" \
	  -var "gcp_password=TEMPLATE_PASSWORD" \
	  -var "task_name=windows_ci_mingw64" \
	  -var "docker_repo=us-docker.pkg.dev/pg-ci-images-dev/ci" \
	  -var "docker_server=us-docker.pkg.dev" \
	  -var "build_type=docker" \
	  packer/windows.pkr.hcl
#	NetBSD Vanilla
	packer validate \
	  -only "vanilla.*" \
	  -var-file=packer/netbsd.pkrvars.hcl \
	  -var gcp_project=pg-ci-images-dev \
	  -var "image_date=$(image_date)" \
	  -var "image_name=netbsd-vanilla" \
	  -var "bucket=somebucket" \
	  packer/netbsd_openbsd.pkr.hcl
#	NetBSD Postgres
	packer validate \
	  -only "postgres.*" \
	  -var-file=packer/netbsd.pkrvars.hcl \
	  -var gcp_project=pg-ci-images-dev \
	  -var "image_date=$(image_date)" \
	  -var "image_name=netbsd-postgres" \
	  -var "bucket=somebucket" \
	  packer/netbsd_openbsd.pkr.hcl
#	OpenBSD Vanilla
	packer validate \
	  -only "vanilla.*" \
	  -var-file=packer/openbsd.pkrvars.hcl \
	  -var gcp_project=pg-ci-images-dev \
	  -var "image_date=$(image_date)" \
	  -var "image_name=openbsd-vanilla" \
	  -var "bucket=somebucket" \
	  packer/netbsd_openbsd.pkr.hcl
#	OpenBSD Postgres
	packer validate \
	  -only "postgres.*" \
	  -var-file=packer/openbsd.pkrvars.hcl \
	  -var gcp_project=pg-ci-images-dev \
	  -var "image_date=$(image_date)" \
	  -var "image_name=openbsd-postgres" \
	  -var "bucket=somebucket" \
	  packer/netbsd_openbsd.pkr.hcl
