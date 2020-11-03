clean: destroy
	rm -rf mydir

destroy:
	./hack/virt-delete-sno.sh || true

generate:
	mkdir -p mydir
	cp ./install-config.yaml mydir/
	OPENSHIFT_INSTALL_EXPERIMENTAL_BOOTSTRAP_IN_PLACE=true OPENSHIFT_INSTALL_EXPERIMENTAL_BOOTSTRAP_IN_PLACE_COREOS_INSTALLER_ARGS=/dev/vda OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE="quay.io/eranco74/ocp-release:bootstrap-in-place" ./bin/openshift-install create ignition-configs --dir=mydir

embed: download-iso
	sudo podman run --pull=always --privileged --rm -v /dev:/dev -v /run/udev:/run/udev -v .:/data -w /data quay.io/coreos/coreos-installer:release iso ignition embed /data/installer-image.iso -f --ignition-file /data/mydir/bootstrap-in-place-for-live-iso.ign -o /data/installer-SNO-image.iso
	mkdir -p /tmp/images
	mv installer-SNO-image.iso /tmp/images/installer-SNO-image.iso

download-iso:
	./hack/download_live_iso.sh &

start-iso:
	./hack/virt-install-sno-iso-ign.sh

network:
	./hack/virt-create-net.sh

ssh:
	ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no core@192.168.126.10
