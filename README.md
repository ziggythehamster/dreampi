# dreampi

A daemon that creates a bridge between a Dreamcast's Dial-up Modem, and the Internet via the Pi (and an x86 virtual machine)

# DreamVM

## Dev notes

The DreamVM images are built using Packer and a collection of pre-built Packer templates called packer-build (in `vendor/packer-build`). Many different options are configurable in these templates, like the Debian preseed file to use, the name, and so on. But not everything is customiziable, so we maintain a JSON file for each image with some customiziations that we merge into the upstream file when you make the image.
