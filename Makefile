# This Makefile is used to build a DreamPi/DreamVM image.

# Binaries, override in your environment if needed
PACKER_BUILD_VBOX = ./vendor/packer-build/scripts/vbox.sh

# Variables
HEADLESS = true
VERSION  = $(shell cat dreampi-version.txt)

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

# This builds a VirtualBox image. We have to do some stuff to the upstream Packer
# template to make it work for us, but that's done with jq rather than keeping a
# copy of the template in the repo. Also, we build an x86 image because many crappy
# WinModems only have x86 drivers available and because users running Hyper-V (whether
# they realize it or not) will not be able to run a 64-bit OS in VirtualBox
vbox:
	# Amend the packer template
	cat ./vendor/packer-build/debian/jessie/base.json ./x86_provisioners.json | \
	sed 's/install\.amd/install\.386/' | \
	jq -rs "\
		.[0].provisioners = .[1].provisioners + .[0].provisioners | \
		del(.[0][\"post-processors\"][0, 3]) | \
		.[0].builders[0].guest_os_type = \"Debian\" | \
		.[0].builders[0].export_opts = [ \
			\"--options\", \"manifest,nomacs\", \
			\"--vsys\", \"0\", \
			\"--product\", \"DreamVM\", \
			\"--version\", \"$(VERSION)\", \
			\"--description\", \"{{user \`description\`}}\" \
		] | \
		.[0].builders[0].vboxmanage = .[0].builders[0].vboxmanage + [ \
			[ \
				\"modifyvm\", \
				\"{{.Name}}\", \
				\"--vram\", \
				\"64\" \
			], \
			[ \
				\"modifyvm\", \
				\"{{.Name}}\", \
				\"--usb\", \
				\"on\" \
			] \
		] | \
		.[0]" > ./tmp/vbox.json

	# Set the description field to something including spaces because space-escaping is not working properly
	jq -rn '{ description: "DreamVM $(VERSION)" }' > ./tmp/vbox-vars.json

	# Build the image
	$(PACKER_BUILD_VBOX) \
		-var-file ./tmp/vbox-vars.json \
		-var 'country=US' \
		-var 'headless=$(HEADLESS)' \
		-var 'iso_checksum=d60ba9bf74ca3db95cb57bf7524d39487f541d28ba403a238996b9b4dca1b9103a0c0c82379d7c68b506cff589845b73bf0497311dd549b6854e21cddd03a8f8' \
		-var 'iso_file=debian-8.10.0-i386-netinst.iso' \
		-var 'iso_path_external=http://cdimage.debian.org/cdimage/archive/latest-oldstable/i386/iso-cd' \
		-var 'locale=en_US.UTF-8' \
		-var 'preseed_file=dreamvm.preseed' \
		-var 'ssh_password=dreamvm' \
		-var 'ssh_username=dreamvm' \
		-var 'vagrantfile_template=vendor/packer-build/debian/jessie/base.vagrant' \
		-var 'vm_name=dreamvm-$(shell echo '$(VERSION)' | tr . -)' \
		./tmp/vbox.json

.PHONY: default preflight rpi vbox
