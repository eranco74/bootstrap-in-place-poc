See https://github.com/openshift/enhancements/pull/565

# How to run
- Set PULL_SECRET environment variable to your pull secret
- `make start-iso` - Spins up a VM with the the liveCD. This will automatically perform the following actions:
	- Clone the installer repo with the boostrap-in-place branch
	- Apply the patches in the patches directory to that repo
	- Build the openshift installer
	- Generate the install-config.yaml 
	- Execute the openshift-installer `create single-node-ignition-config` command to generate the bootstrap-in-place-for-live-iso.ign.
	- Download the RHCOS live ISO
	- Embed the bootstrap-in-place Ignition to the ISO.
	- Create a libvirt network & VM
	- Boot the VM with that ISO
- You can now monitor the progress using `make ssh` and `journalctl -f -u bootkube.service` or `kubectl --kubeconfig ./sno-workdir/auth/kubeconfig get clusterversion`

Default release image is quay.io/eranco74/ocp-release:bootstrap-in-place, you can override it using RELEASE_IMAGE env var
make will execute the openshift-installer with OPENSHIFT_INSTALL_EXPERIMENTAL_BOOTSTRAP_IN_PLACE_COREOS_INSTALLER_ARGS=/dev/vda
if you’re running the installatin on a BM environment, it should be updated.

This POC currently mitigating some gaps by patching etcd, Authentication and Ingress, allowing single node installation.
See installer-patches/
This won't be required after [single-node production deployment](https://github.com/openshift/enhancements/pull/560) is implemented.
