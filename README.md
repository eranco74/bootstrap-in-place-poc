See https://github.com/openshift/enhancements/pull/565

Check out the `bootstrap-in-place` installer branch:

```
$> cd ~/go/src/github.com/openshift/installer
$> git remote add -f eranco74 git@github.com:eranco74/installer.git
$> git checkout -b bootstrap-in-place eranco74/bootstrap-in-place
```

- Patch and build the installer - `make installer`
- Copy `./install-config.yaml.tmpl` to ./install-config.yaml` and add your ssh key and pull secret to it
- Generate ignition - `make generate`
- Set up networking - `make network` (provides DNS for `Cluster name: test-cluster, Base DNS: redhat.com`)
- Download rhcos image - `make embed` (download RHCOS liveCD and embed the bootstrap Ignition)
- Spin up a VM with the the liveCD - `make start-iso`
- Monitor the progress using `make ssh` and `journalctl -f -u bootkube.service` or `kubectl --kubeconfig ./mydir/auth/kubeconfig get clusterversion`
