SNO_DIR = .
########################
# User variables
########################

checkenv:
ifndef PULL_SECRET
	$(error PULL_SECRET must be defined)
endif

INSTALLATION_DISK ?= /dev/vda
RELEASE_IMAGE ?= quay.io/eranco74/ocp-release:bootstrap-in-place

########################

INSTALLER_REPO_REMOTE = https://github.com/eranco74/installer
INSTALLER_REPO_BRANCH = bootstrap-in-place
INSTALLER_REPO = $(SNO_DIR)/installer
INSTALLER_BIN = $(INSTALLER_REPO)/bin/openshift-install
INSTALLER_PATCHES = $(SNO_DIR)/installer-patches

INSTALLER_WORKDIR = sno-workdir
BIP_LIVE_ISO_IGNITION = $(INSTALLER_WORKDIR)/bootstrap-in-place-for-live-iso.ign

LIBVIRT_ISO_PATH = /var/lib/libvirt/images
INSTALLER_ISO_PATH = $(SNO_DIR)/installer-image.iso
INSTALLER_ISO_PATH_SNO = $(SNO_DIR)/installer-SNO-image.iso
INSTALLER_ISO_PATH_SNO_IN_LIBVIRT = $(LIBVIRT_ISO_PATH)/installer-SNO-image.iso

INSTALL_CONFIG_TEMPLATE = $(SNO_DIR)/install-config.yaml.template
INSTALL_CONFIG = $(SNO_DIR)/install-config.yaml
INSTALL_CONFIG_IN_WORKDIR = $(INSTALLER_WORKDIR)/install-config.yaml

NET_CONFIG_TEMPLATE = $(SNO_DIR)/net.xml.template
NET_CONFIG = $(SNO_DIR)/net.xml

NET_NAME = test-net
VM_NAME = sno-test
VOL_NAME = $(VM_NAME).qcow2

SSH_KEY_DIR = $(SNO_DIR)/ssh-key
SSH_KEY_PUB_PATH = $(SSH_KEY_DIR)/key.pub
SSH_KEY_PRIV_PATH = $(SSH_KEY_DIR)/key

SSH_FLAGS = -o IdentityFile=$(SSH_KEY_PRIV_PATH) \
 			-o UserKnownHostsFile=/dev/null \
 			-o StrictHostKeyChecking=no

HOST_IP = 192.168.126.10
SSH_HOST = core@$(HOST_IP)

define generate-keypair =
endef

$(SSH_KEY_DIR):
	@echo Creating SSH key dir
	mkdir $@

$(SSH_KEY_PRIV_PATH): $(SSH_KEY_DIR)
	@echo "No private key $@ found, generating a private-public pair"
	# -N "" means no password
	ssh-keygen -f $@ -N ""
	chmod 400 $@

$(SSH_KEY_PUB_PATH): $(SSH_KEY_PRIV_PATH)

.PHONY: gather checkenv clean destroy-libvirt start-iso network ssh patched_installer

# $(INSTALL_CONFIG) is also PHONY to force the makefile to regenerate it with new env vars
.PHONY: $(INSTALL_CONFIG)

# $(INSTALLER_WORKDIR) is also PHONY because "installer create single-node-ignition-config" doesn't regenerate
# if some of the files in the folder already exist
.PHONY: $(INSTALLER_WORKDIR)

.SILENT: destroy-libvirt

clean: destroy-libvirt
	rm -rf $(INSTALLER_WORKDIR)

$(INSTALLER_REPO): 
	git clone $(INSTALLER_REPO_REMOTE) $@ -b $(INSTALLER_REPO_BRANCH)

patches = $(wildcard $(INSTALLER_PATCHES)/*.patch)
patched_installer: $(INSTALLER_REPO) $(patches)
	git -C $(INSTALLER_REPO) stash
	git -C $(INSTALLER_REPO) reset --hard origin/$(INSTALLER_REPO_BRANCH)
	for patch in $(patches); do \
		echo Patching $$patch ; \
		cat $$patch | git -C $(INSTALLER_REPO) am -3 ; \
	done

$(INSTALLER_BIN): patched_installer
	cd $(INSTALLER_REPO) && \
	./hack/build.sh

destroy-libvirt:
	echo "Destroying previous libvirt resources"
	NET_NAME=$(NET_NAME) \
        VM_NAME=$(VM_NAME) \
        VOL_NAME=$(VOL_NAME) \
	$(SNO_DIR)/virt-delete-sno.sh || true

# Render the install config from the template with the correct pull secret and SSH key
$(INSTALL_CONFIG): $(INSTALL_CONFIG_TEMPLATE) checkenv $(SSH_KEY_PUB_PATH)
	sed -e 's/YOUR_PULL_SECRET/$(PULL_SECRET)/' \
	    -e 's|YOUR_SSH_KEY|$(shell cat $(SSH_KEY_PUB_PATH))|' \
	    $(INSTALL_CONFIG_TEMPLATE) > $(INSTALL_CONFIG)

# Render the libvirt net config file with the network name and host IP
$(NET_CONFIG): $(NET_CONFIG_TEMPLATE)
	sed -e 's/REPLACE_NET_NAME/$(NET_NAME)/' \
		-e 's/REPLACE_HOST_IP/$(HOST_IP)/' \
	    $(NET_CONFIG_TEMPLATE) > $@

network: destroy-libvirt $(NET_CONFIG)
	NET_XML=$(NET_CONFIG) $(SNO_DIR)/virt-create-net.sh

# Create a working directory for the openshift-installer `--dir` parameter
$(INSTALLER_WORKDIR):
	@echo Overwriting previous working directory $@
	rm -rf $@
	mkdir $@

# The openshift-installer expects the install config file to be in its working directory
$(INSTALL_CONFIG_IN_WORKDIR): $(INSTALLER_WORKDIR) $(INSTALL_CONFIG)
	cp $(INSTALL_CONFIG) $@

# Original CoreOS ISO
$(INSTALLER_ISO_PATH): 
	$(SNO_DIR)/download_live_iso.sh $@

# Use the openshift-installer to generate BiP Live ISO ignition file
$(BIP_LIVE_ISO_IGNITION): $(INSTALL_CONFIG_IN_WORKDIR) $(INSTALLER_BIN)
	OPENSHIFT_INSTALL_EXPERIMENTAL_BOOTSTRAP_IN_PLACE=true \
	OPENSHIFT_INSTALL_EXPERIMENTAL_BOOTSTRAP_IN_PLACE_COREOS_INSTALLER_ARGS=$(INSTALLATION_DISK) \
	OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE="$(RELEASE_IMAGE)" \
	$(INSTALLER_BIN) create single-node-ignition-config --dir=$(INSTALLER_WORKDIR)

# Embed the ignition file in the CoreOS ISO
$(INSTALLER_ISO_PATH_SNO): $(BIP_LIVE_ISO_IGNITION) $(INSTALLER_ISO_PATH)
	# openshift-install will not overwrite existing ISOs, so we delete it beforehand
	rm -f $@

	sudo podman run \
		--pull=always \
		--privileged \
		--rm \
		-v /dev:/dev \
		-v /run/udev:/run/udev \
		-v $(SNO_DIR):/data \
		--workdir /data \
		quay.io/coreos/coreos-installer:release \
		iso ignition embed /data/$(INSTALLER_ISO_PATH) \
		--force \
		--ignition-file /data/$(BIP_LIVE_ISO_IGNITION) \
		--output /data/$@

$(INSTALLER_ISO_PATH_SNO_IN_LIBVIRT): $(INSTALLER_ISO_PATH_SNO)
	sudo cp $< $@
	sudo chown qemu:qemu $@

# Destroy previously created VMs/Networks and create a VM/Network with an ISO containing the BiP embedded ignition file
start-iso: $(INSTALLER_ISO_PATH_SNO_IN_LIBVIRT) network
	RHCOS_ISO=$(INSTALLER_ISO_PATH_SNO_IN_LIBVIRT) \
	VM_NAME=$(VM_NAME) \
	NET_NAME=$(NET_NAME) \
	$(SNO_DIR)/virt-install-sno-iso-ign.sh

ssh: $(SSH_KEY_PRIV_PATH)
	ssh $(SSH_FLAGS) $(SSH_HOST)

gather:
	@echo Gathering logs...
	@echo If this fails, try killing running SSH agent instances. Installer will prefer those \
over your explicitly provided key file
	$(INSTALLER_BIN) gather bootstrap \
	--bootstrap $(HOST_IP) \
	--master $(HOST_IP) \
	--key $(SSH_KEY_PRIV_PATH)
