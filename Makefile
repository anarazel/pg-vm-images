image_date := $(shell date +'%Y-%mt%d-%H-%M')

pre-commit:
	packer validate \
	  -var gcp_project=pg-vm-images-aio \
	  -var "image_date=$(image_date)" \
	  googlecompute/freebsd.pkr.hcl
	packer validate \
	  -var gcp_project=pg-vm-images-aio \
	  -var "image_date=$(image_date)" \
	  googlecompute/linux.pkr.hcl
	yamllint -c .yamllint-cirrus .cirrus.yml
