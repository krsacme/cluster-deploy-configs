Jenkins Configuration
=====================

Below credentials configurations are required to deploy OCP cluster, using the Jenkinsfile in this repo.

* Beaker Credentials (skramaja)
* Beaker Root Password (skramaja-beaker-root-password)
* Pull Secrent JSON file (skramja-pull-secret)
* OC token from cloud.openshift.com (skramaja-ci-token)



```
./scripts/render-ifcfg --default-interfaces enp6s0f1,enp130s0f1 --interfaces enp6s0f0,enp130s0f0 -c dell-r730-024.dsal.lab.eng.rdu2.redhat.com
```
