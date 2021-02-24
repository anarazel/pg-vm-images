image_date := $(shell date +'%Y-%mt%d-%H-%M')

pre-commit:
	packer validate -var "image_date=$(image_date)" googlecompute/images.json
