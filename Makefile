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
	  -only "vanilla.*" \
	  -var-file=packer/netbsd.pkrvars.hcl \
	  -var gcp_project=pg-ci-images-dev \
	  -var "image_date=$(image_date)" \
	  -var "image_name=openbsd-vanilla" \
	  -var "bucket=somebucket" \
	  packer/netbsd_openbsd.pkr.hcl
	packer validate \
	  -only "postgres.*" \
	  -var-file=packer/netbsd.pkrvars.hcl \
	  -var gcp_project=pg-ci-images-dev \
	  -var "image_date=$(image_date)" \
	  -var "image_name=openbsd-postgres" \
	  -var "bucket=somebucket" \
	  packer/netbsd_openbsd.pkr.hcl
	packer validate \
	  -only "vanilla.*" \
	  -var-file=packer/openbsd.pkrvars.hcl \
	  -var gcp_project=pg-ci-images-dev \
	  -var "image_date=$(image_date)" \
	  -var "image_name=netbsd-vanilla" \
	  -var "bucket=somebucket" \
	  packer/netbsd_openbsd.pkr.hcl
	packer validate \
	  -only "postgres.*" \
	  -var-file=packer/openbsd.pkrvars.hcl \
	  -var gcp_project=pg-ci-images-dev \
	  -var "image_date=$(image_date)" \
	  -var "image_name=netbsd-postgres" \
	  -var "bucket=somebucket" \
	  packer/netbsd_openbsd.pkr.hcl
