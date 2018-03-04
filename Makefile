# This Makefile is used to build a DreamPi/DreamVM image.

# Binaries, override in your environment if needed
PACKER_BUILD_VBOX = ./vendor/packer-build/scripts/vbox.sh

# Variables
HEADLESS = true
VERSION  = 1.6

# Set the default target to help
MAIN = help

# This prints out usage information.
# NB: 208,51,8 is the RGB code for the red Dreamcast logo
help:
	@echo $$'\x1b[38;2;208;51;8mDreamPi/DreamVM v$(VERSION) Image Building System\x1b[0m'
	@echo ""
	@echo $$'\x1b[1m\x1b[4mImage building targets:\x1b[0m'
	@echo "    rpi                $(rpi?)"
	@echo "    vbox-amd64         $(vbox-amd64?)"
	@echo "    vbox-x86           $(vbox-x86?)"
	@echo ""
	@echo $$'\x1b[1m\x1b[4mTool targets:\x1b[0m'
	@echo "    preflight          $(preflight?)"
	@echo ""

# This makes sure that your system works as expected
preflight? = Checks that your system is capable of building an image
preflight:
	@echo -n "Looking for packer... "
	@which packer
	@echo -n "Looking for jq... "
	@which jq
	@echo "You're all set to build!"

# This builds a Raspberry Pi image
rpi? = Build an image compatible with the Raspberry Pi
rpi:
	$(error Sorry, this is not yet supported.)

# This builds an amd64 VirtualBox image.
vbox-amd64? = Build a VirtualBox image compatible with AMD64/x86_64 processors. Windows users: Hyper-V must be disabled or VirtualBox cannot build this image.
vbox-amd64:
	# Amend the packer template with additional provisioners
	cat ./vendor/packer-build/debian/jessie/base.json ./dreamvm/provisioners.json | jq -rs ".[0].provisioners = .[1].provisioners + .[0].provisioners | .[0]" > ./tmp/vbox-amd64.json

	# Set the description field to something including spaces because space-escaping is not working properly
	jq -rn '{ description: "DreamVM $(VERSION) for AMD64/x86_64" }' > ./tmp/vbox-amd64-vars.json

	# Build the image
	$(PACKER_BUILD_VBOX) \
		-var-file ./tmp/vbox-amd64-vars.json \
		-var 'country=US' \
		-var 'headless=$(HEADLESS)' \
		-var 'locale=en_US.UTF-8' \
		-var 'preseed_file=dreamvm/amd64.preseed' \
		-var 'ssh_password=dreamvm' \
		-var 'ssh_username=dreamvm' \
		-var 'vagrantfile_template=vendor/packer-build/debian/jessie/base.vagrant' \
		-var 'vm_name=dreamvm-amd64-$(shell echo '$(VERSION)' | tr . -)' \
		./tmp/vbox-amd64.json

# This builds an x86 VirtualBox image.
vbox-x86? = Build a VirtualBox image compatible with x86 processors (also runs on AMD64/x86_64 processors).
vbox-x86:
	$(error Sorry, this is not yet supported.)

.PHONY: default preflight rpi vbox-amd64 vbox-x86
