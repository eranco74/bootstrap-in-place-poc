#
# You may override any of these variables on the command line e.g.
#
#  $> make generate COREOS_INSTALLER_ARGS=
#
# will cause coreos-installer not to be executed at the end of bootkube

COREOS_INSTALLER_ARGS = /dev/vda
INSTALLER_SRCDIR = ~/go/src/github.com/openshift/installer
INSTALLER_BINDIR = $(INSTALLER_SRCDIR)/bin
RELEASE_IMAGE := $(or $(RELEASE_IMAGE), "quay.io/eranco74/ocp-release:bootstrap-in-place-poc")

clean: destroy
	rm -rf mydir

destroy:
	./hack/virt-delete-sno.sh || true

generate:
	mkdir -p mydir
	cp ./install-config.yaml mydir/
	OPENSHIFT_INSTALL_EXPERIMENTAL_BOOTSTRAP_IN_PLACE=true OPENSHIFT_INSTALL_EXPERIMENTAL_BOOTSTRAP_IN_PLACE_COREOS_INSTALLER_ARGS="$(COREOS_INSTALLER_ARGS)" OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE="$(RELEASE_IMAGE)" $(INSTALLER_BINDIR)/openshift-install create single-node-ignition-config --dir=mydir

embed: download-iso
	sudo podman run --pull=always --privileged --rm -v /dev:/dev -v /run/udev:/run/udev -v .:/data -w /data quay.io/coreos/coreos-installer:release iso ignition embed /data/installer-image.iso -f --ignition-file /data/mydir/bootstrap-in-place-for-live-iso.ign -o /data/installer-SNO-image.iso
	mkdir -p /tmp/images
	mv -f installer-SNO-image.iso /tmp/images/installer-SNO-image.iso

download-iso:
	./hack/download_live_iso.sh &

start-iso:
	./hack/virt-install-sno-iso-ign.sh

patch:
	cd $(INSTALLER_SRCDIR) && git am -3 $(CURDIR)/installer-patches/*.patch

installer: patch
	cd $(INSTALLER_SRCDIR) && hack/build.sh

network:
	./hack/virt-create-net.sh

ssh:
	ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no core@192.168.126.10
