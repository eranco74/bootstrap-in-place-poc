See https://github.com/openshift/enhancements/pull/565

- Copy ./install-config.yaml.tmpl` to ./install-config.yaml` and add your ssh key and pull secret to it
- Extract the openshift-installer from the release image and generate ignition - `make generate`
- Set up networking - `make network` (provides DNS for `Cluster name: test-cluster, Base DNS: redhat.com`)
- Download rhcos image - `make embed` (download RHCOS liveCD and embed the bootstrap Ignition)
- Spin up a VM with the the liveCD - `make start-iso`
- Monitor the progress using `make ssh` and `journalctl -f -u bootkube.service` or `kubectl --kubeconfig ./mydir/auth/kubeconfig get clusterversion`

Default release image is quay.io/eranco74/ocp-release:bootstrap-in-place, you can override it using RELEASE_IMAGE env var
