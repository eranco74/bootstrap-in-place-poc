include Makefile.vsphere

# Disable built-in rules
MAKEFLAGS += --no-builtin-rules

SNO_DIR = .

########################
# User variables
########################

checkenv:
ifndef PULL_SECRET
	$(error PULL_SECRET must be defined)
endif

INSTALLATION_DISK ?= /dev/vda
RELEASE_IMAGE ?= quay.io/openshift-release-dev/ocp-release:4.13.5-x86_64


########################

INSTALLER_WORKDIR = sno-workdir
INSTALLER_BIN = bin/openshift-install
LIVE_ISO_IGNITION_NAME = bootstrap-in-place-for-live-iso.ign
BIP_LIVE_ISO_IGNITION = $(INSTALLER_WORKDIR)/$(LIVE_ISO_IGNITION_NAME)

LIBVIRT_ISO_PATH = /var/lib/libvirt/images
INSTALLER_ISO_PATH = $(SNO_DIR)/installer-image.iso
INSTALLER_ISO_PATH_SNO = $(SNO_DIR)/installer-SNO-image.iso
INSTALLER_ISO_PATH_SNO_IN_LIBVIRT = $(LIBVIRT_ISO_PATH)/installer-SNO-image.iso

MACHINE_NETWORK ?= 192.168.126.0/24
CLUSTER_NETWORK ?= 10.128.0.0/14
CLUSTER_SVC_NETWORK ?= 172.30.0.0/16
CLUSTER_NAME ?= test-cluster
BASE_DOMAIN ?= redhat.com
RAM_MB ?= 16384
CPU_CORE ?= 8

INSTALL_CONFIG_TEMPLATE = $(SNO_DIR)/install-config.yaml.template
INSTALL_CONFIG = $(SNO_DIR)/install-config.yaml
INSTALL_CONFIG_IN_WORKDIR = $(INSTALLER_WORKDIR)/install-config.yaml

ABI_ISO_PATH = $(INSTALLER_WORKDIR)/agent.x86_64.iso
ABI_ISO_PATH_IN_LIBVIRT = $(LIBVIRT_ISO_PATH)/agent.x86_64.iso
AGENT_CONFIG_IN_WORKDIR = $(INSTALLER_WORKDIR)/agent-config.yaml


NET_CONFIG_TEMPLATE = $(SNO_DIR)/net.xml.template
NET_CONFIG = $(SNO_DIR)/net.xml

NET_NAME = test-net
VM_NAME ?= sno-test
VOL_NAME = $(VM_NAME).qcow2
POOL ?= default
SSH_KEY_DIR = $(SNO_DIR)/ssh-key
SSH_KEY_PUB_PATH = $(SSH_KEY_DIR)/key.pub
SSH_KEY_PRIV_PATH = $(SSH_KEY_DIR)/key

SSH_FLAGS = -o IdentityFile=$(SSH_KEY_PRIV_PATH) \
 			-o UserKnownHostsFile=/dev/null \
 			-o StrictHostKeyChecking=no

HOST_IP = 192.168.126.10
SSH_HOST = core@$(HOST_IP)

$(SSH_KEY_DIR):
	@echo Creating SSH key dir
	mkdir $@

$(SSH_KEY_PRIV_PATH): $(SSH_KEY_DIR)
	@echo "No private key $@ found, generating a private-public pair"
	# -N "" means no password
	ssh-keygen -f $@ -N ""
	chmod 400 $@

$(SSH_KEY_PUB_PATH): $(SSH_KEY_PRIV_PATH)

.PHONY: gather checkenv clean destroy-libvirt start-iso network ssh

# $(INSTALL_CONFIG) is also PHONY to force the makefile to regenerate it with new env vars
.PHONY: $(INSTALL_CONFIG)

# $(INSTALLER_WORKDIR) is also PHONY because "installer create single-node-ignition-config" doesn't regenerate
# if some of the files in the folder already exist
.PHONY: $(INSTALLER_WORKDIR)

.SILENT: destroy-libvirt

clean: destroy-libvirt
	rm -rf $(INSTALLER_WORKDIR)
	rm -rf registry-config.json
	$(SNO_DIR)/bm-dell-clean.sh || true

destroy-libvirt:
	echo "Destroying previous libvirt resources"
	NET_NAME=$(NET_NAME) \
	VM_NAME=$(VM_NAME) \
	VOL_NAME=$(VOL_NAME) \
	POOL=$(POOL) \
	$(SNO_DIR)/virt-delete-sno.sh || true

# Render the install config from the template with the correct pull secret and SSH key
$(INSTALL_CONFIG): $(INSTALL_CONFIG_TEMPLATE) checkenv $(SSH_KEY_PUB_PATH)
	sed -e 's/YOUR_PULL_SECRET/$(PULL_SECRET)/' \
	    -e 's|YOUR_SSH_KEY|$(shell cat $(SSH_KEY_PUB_PATH))|' \
	    -e 's|INSTALLATION_DISK|$(INSTALLATION_DISK)|' \
	    -e 's|CLUSTER_NAME|$(CLUSTER_NAME)|' \
	    -e 's|BASE_DOMAIN|$(BASE_DOMAIN)|' \
	    -e 's|CLUSTER_NETWORK|$(CLUSTER_NETWORK)|' \
	    -e 's|MACHINE_NETWORK|$(MACHINE_NETWORK)|' \
	    -e 's|CLUSTER_SVC_NETWORK|$(CLUSTER_SVC_NETWORK)|' \
	    $(INSTALL_CONFIG_TEMPLATE) > $(INSTALL_CONFIG)

# Render the libvirt net config file with the network name and host IP
$(NET_CONFIG): $(NET_CONFIG_TEMPLATE)
	sed -e 's/REPLACE_NET_NAME/$(NET_NAME)/' \
	    -e 's|CLUSTER_NAME|$(CLUSTER_NAME)|' \
	    -e 's|BASE_DOMAIN|$(BASE_DOMAIN)|' \
		-e 's/REPLACE_HOST_IP/$(HOST_IP)/' \
	    $(NET_CONFIG_TEMPLATE) > $@

network: destroy-libvirt $(NET_CONFIG)
	NET_XML=$(NET_CONFIG) \
	HOST_IP=$(HOST_IP) \
	CLUSTER_NAME=$(CLUSTER_NAME) \
	BASE_DOMAIN=$(BASE_DOMAIN) \
	$(SNO_DIR)/virt-create-net.sh

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

# Get the openshift-installer from the release image
$(INSTALLER_BIN): registry-config.json
	oc adm release extract --registry-config=registry-config.json --command=openshift-install --to ./bin $(RELEASE_IMAGE)

.PHONY: registry-config.json
registry-config.json:
	jq -n -c '$(PULL_SECRET)' > registry-config.json

# Allow user to define custom manifests in ./manifests/*.yaml
$(INSTALLER_WORKDIR)/manifests: $(INSTALL_CONFIG_IN_WORKDIR) $(INSTALLER_BIN) $(SNO_DIR)/manifests
	RELEASE_IMAGE=$(RELEASE_IMAGE) \
	INSTALLER_BIN=$(INSTALLER_BIN) \
	INSTALLER_WORKDIR=$(INSTALLER_WORKDIR) \
	$(SNO_DIR)/manifests.sh 
	@echo Copying user manifests...
	$(shell echo 'cp -v $(SNO_DIR)/manifests/*.yaml $(INSTALLER_WORKDIR)/manifests/ || true')
	$(shell echo 'cp -v $(SNO_DIR)/manifests/*.yml $(INSTALLER_WORKDIR)/manifests/ || true')

# Use the openshift-installer to generate BiP Live ISO ignition file
$(BIP_LIVE_ISO_IGNITION): $(INSTALLER_WORKDIR)/manifests
	RELEASE_IMAGE=$(RELEASE_IMAGE) \
	INSTALLER_BIN=$(INSTALLER_BIN) \
	INSTALLER_WORKDIR=$(INSTALLER_WORKDIR) \
	$(SNO_DIR)/generate.sh 

# Embed the ignition file in the CoreOS ISO
$(INSTALLER_ISO_PATH_SNO): $(BIP_LIVE_ISO_IGNITION) $(INSTALLER_ISO_PATH)
	# openshift-install will not overwrite existing ISOs, so we delete it beforehand
	rm -f $@

	ISO_PATH=$(INSTALLER_ISO_PATH) \
	IGNITION_PATH=$(BIP_LIVE_ISO_IGNITION) \
	OUTPUT_PATH=$@ \
	$(SNO_DIR)/embed.sh 

$(INSTALLER_ISO_PATH_SNO_IN_LIBVIRT): $(INSTALLER_ISO_PATH_SNO)
	sudo cp $< $@
	sudo chown qemu:qemu $@

# Destroy previously created VMs/Networks and create a VM/Network with an ISO containing the BiP embedded ignition file
start-iso: $(INSTALLER_ISO_PATH_SNO_IN_LIBVIRT) network
	RHCOS_ISO=$(INSTALLER_ISO_PATH_SNO_IN_LIBVIRT) \
	VM_NAME=$(VM_NAME) \
	NET_NAME=$(NET_NAME) \
	POOL=$(POOL) \
	$(SNO_DIR)/virt-install-sno-iso-ign.sh

$(AGENT_CONFIG_IN_WORKDIR): agent-config.yaml $(INSTALLER_WORKDIR)
	sudo cp $< $@

# Generate an agent based ISO
$(ABI_ISO_PATH): $(INSTALLER_BIN) $(AGENT_CONFIG_IN_WORKDIR) $(INSTALL_CONFIG_IN_WORKDIR)
	# openshift-install will not overwrite existing ISOs, so we delete it beforehand
	rm -f $@
	@echo Copying user manifests...
	mkdir -p $(INSTALLER_WORKDIR)/openshift/
	$(shell echo 'cp -v $(SNO_DIR)/manifests/*.yaml $(INSTALLER_WORKDIR)/openshift/ || true')
	$(shell echo 'cp -v $(SNO_DIR)/manifests/*.yml $(INSTALLER_WORKDIR)/openshift/ || true')
	RELEASE_IMAGE=$(RELEASE_IMAGE) \
	INSTALLER_BIN=$(INSTALLER_BIN) \
	INSTALLER_WORKDIR=$(INSTALLER_WORKDIR) \
	$(SNO_DIR)/create-abi-image.sh

$(ABI_ISO_PATH_IN_LIBVIRT): $(ABI_ISO_PATH)
	sudo cp $< $@
	sudo chown qemu:qemu $@

# Destroy previously created VMs/Networks and create a VM/Network with an ISO containing the BiP embedded ignition file
# ABI validates minimum disk space and CPU resources so we need to override the default
start-iso-abi: $(ABI_ISO_PATH_IN_LIBVIRT) network
	RHCOS_ISO=$(ABI_ISO_PATH_IN_LIBVIRT) \
	VM_NAME=$(VM_NAME) \
	NET_NAME=$(NET_NAME) \
	DISK_GB=130 \
	CPU_CORE=$(CPU_CORE) \
	RAM_MB=$(RAM_MB) \
	$(SNO_DIR)/virt-install-sno-iso-ign.sh

ssh: $(SSH_KEY_PRIV_PATH)
	ssh $(SSH_FLAGS) $(SSH_HOST) $(CMD)

dump_ignition:
	@[ ! -f $(BIP_LIVE_ISO_IGNITION) ] && echo $(BIP_LIVE_ISO_IGNITION) does not exist && exit 1 || true
	@echo Dumping ignition into ./ign-root/
	rm -rf ./ign-root/
	python3 $(SNO_DIR)/ignition_dump.py $(BIP_LIVE_ISO_IGNITION)

gather:
	@echo Gathering logs...
	@echo If this fails, try killing running SSH agent instances. Installer will prefer those \
over your explicitly provided key file
	$(INSTALLER_BIN) gather bootstrap \
	--bootstrap $(HOST_IP) \
	--master $(HOST_IP) \
	--key $(SSH_KEY_PRIV_PATH)
