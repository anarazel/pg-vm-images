IMAGE_DATE := $(shell date +'%Y-%mt%d-%H-%M')
PREFIX := pg-ci

pre-commit:
	yamllint -c .yamllint-cirrus .cirrus.yml
#	FreeBSD
	packer validate \
	  -var gcp_project=pg-ci-images-dev \
	  -var "image_date=$(IMAGE_DATE)" \
	  -var "image_name=freebsd" \
	  packer/freebsd.pkr.hcl
#	Debian Bullseye
	packer validate \
	  -var gcp_project=pg-ci-images-dev \
	  -var "image_date=$(IMAGE_DATE)" \
	  -var "image_name=bullseye" \
	  packer/linux_debian.pkr.hcl
#	Debian Bookworm
	packer validate \
	  -var gcp_project=pg-ci-images-dev \
	  -var "image_date=$(IMAGE_DATE)" \
	  -var "image_name=bookworm" \
	  packer/linux_debian.pkr.hcl
#	Debian Trixie
	packer validate \
	  -var gcp_project=pg-ci-images-dev \
	  -var "image_date=$(IMAGE_DATE)" \
	  -var "image_name=trixie" \
	  packer/linux_debian.pkr.hcl
#	Windows VM
	packer validate \
	  -var gcp_project=pg-ci-images-dev \
	  -var "image_date=$(IMAGE_DATE)" \
	  -var "image_name=windows-ci-vs" \
	  packer/windows.pkr.hcl
#	NetBSD Vanilla
	packer validate \
	  -only "vanilla.*" \
	  -var-file=packer/netbsd.pkrvars.hcl \
	  -var gcp_project=pg-ci-images-dev \
	  -var "image_date=$(IMAGE_DATE)" \
	  -var "image_name=netbsd-vanilla" \
	  -var "prefix=${PREFIX}" \
	  -var "bucket=somebucket" \
	  packer/netbsd_openbsd.pkr.hcl
#	NetBSD Postgres
	packer validate \
	  -only "postgres.*" \
	  -var-file=packer/netbsd.pkrvars.hcl \
	  -var gcp_project=pg-ci-images-dev \
	  -var "image_date=$(IMAGE_DATE)" \
	  -var "image_name=netbsd-postgres" \
	  -var "prefix=${PREFIX}" \
	  -var "bucket=somebucket" \
	  packer/netbsd_openbsd.pkr.hcl
#	OpenBSD Vanilla
	packer validate \
	  -only "vanilla.*" \
	  -var-file=packer/openbsd.pkrvars.hcl \
	  -var gcp_project=pg-ci-images-dev \
	  -var "image_date=$(IMAGE_DATE)" \
	  -var "image_name=openbsd-vanilla" \
	  -var "prefix=${PREFIX}" \
	  -var "bucket=somebucket" \
	  packer/netbsd_openbsd.pkr.hcl
#	OpenBSD Postgres
	packer validate \
	  -only "postgres.*" \
	  -var-file=packer/openbsd.pkrvars.hcl \
	  -var gcp_project=pg-ci-images-dev \
	  -var "image_date=$(IMAGE_DATE)" \
	  -var "image_name=openbsd-postgres" \
	  -var "prefix=${PREFIX}" \
	  -var "bucket=somebucket" \
	  packer/netbsd_openbsd.pkr.hcl
