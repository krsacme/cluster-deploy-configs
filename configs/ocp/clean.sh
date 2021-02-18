#!/bin/bash

oc -n example-cnf delete testpmd --all
oc -n example-cnf delete trexconfig --all
oc -n example-cnf delete loadbalancer --all

if [[ $1 == "all" ]]; then
  oc -n example-cnf delete sub --all
  oc -n example-cnf delete csv --all
  
  oc -n example-cf delete deployment --all
  oc -n example-cf delete replicaset --all

  oc -n openshift-marketplace delete catalogsource nfv-example-cnf-catalog

  oc delete crds testpmds.examplecnf.openshift.io
  oc delete crds testpmdmacs.examplecnf.openshift.io
  oc delete crds trexconfigs.examplecnf.openshift.io
fi

