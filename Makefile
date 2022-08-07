image_date := $(shell date +'%Y-%mt%d-%H-%M')

pre-commit:
	yamllint -c .yamllint-cirrus .cirrus.yml
	packer validate \
	  -var gcp_project=pg-ci-images-dev \
	  -var "image_date=$(image_date)" \
	  -var "task_name=freebsd-13" \
	  packer/freebsd.pkr.hcl
	packer validate \
	  -var gcp_project=pg-ci-images-dev \
	  -var "image_date=$(image_date)" \
	  -var "task_name=bullseye" \
	  packer/linux_debian.pkr.hcl
	packer validate \
	  -var gcp_project=pg-ci-images-dev \
	  -var "image_date=$(image_date)" \
	  -var "image_name=openbsd-9-vanilla" \
	  -var "bucket=somebucket" \
	  packer/bsd/openbsd_vanilla.pkr.hcl
	packer validate \
	  -var gcp_project=pg-ci-images-dev \
	  -var "image_date=$(image_date)" \
	  -var "image_name=openbsd-9-postgres" \
	  -var "bucket=somebucket" \
	  packer/bsd/openbsd_postgres.pkr.hcl
	packer validate \
	  -var gcp_project=pg-ci-images-dev \
	  -var "image_date=$(image_date)" \
	  -var "image_name=netbsd-9-vanilla" \
	  -var "bucket=somebucket" \
	  packer/bsd/netbsd_vanilla.pkr.hcl
	packer validate \
	  -var gcp_project=pg-ci-images-dev \
	  -var "image_date=$(image_date)" \
	  -var "image_name=netbsd-9-postgres" \
	  -var "bucket=somebucket" \
	  packer/bsd/netbsd_postgres.pkr.hcl
