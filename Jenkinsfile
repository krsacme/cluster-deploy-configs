def branches = [:]
def stagelst='baremetal'

pipeline {
  agent {
    node {
      label 'master'
      customWorkspace "${JENKINS_HOME}/workspace/${JOB_NAME}/${BUILD_NUMBER}"
    }
  }
  /*options {
    lock resource: "${params.server}"
  }*/
  parameters {
    choice(name: 'server', choices: ['dell-r640-oss-10.lab.eng.brq.redhat.com'], description: 'Pick something')
    string(name: 'beaker_user', defaultValue: 'skramaja', description: 'Beaker username')
  }
  stages {
    stage('Install Baremetal') {
      when {
        expression {
          false
        }
      }
      environment {
        SERVICE_CREDS = credentials("${params.beaker_user}")
      }
      steps {
        sh '''
        rm -rf $HOME/infrared;
        mkdir $HOME/infrared;
        git clone https://github.com/redhat-openstack/infrared.git $HOME/infrared;
        cd $HOME/infrared/;
        virtualenv-3 .venv;
        echo "export IR_HOME=`pwd`" >> .venv/bin/activate;
        source .venv/bin/activate;
        pip3 install ansible==2.9
        pip3 install -U pip;
        pip3 install .;
        ansible --version;
        which ansible;
        infrared plugin add all
        '''
        writeFile file: '/var/lib/jenkins/infrared/plugins/beaker/vars/image/centos-8.yml', text: '---\ndistro_id: 110991'

        withCredentials([
            usernamePassword(credentialsId: "${params.beaker_user}", passwordVariable: 'beaker_password_var', usernameVariable: 'beaker_username_var'),\
            usernamePassword(credentialsId: "${params.beaker_user}-beaker-root-password", passwordVariable: 'host_password_var', usernameVariable: '')]) {
          sh '''
          cd $HOME/infrared/;
          source .venv/bin/activate;
          ir beaker -vvvv --url="https://beaker.engineering.redhat.com" --beaker-user="$beaker_username_var" \
              --beaker-password="${beaker_password_var}" --host-address="$server" --image="centos-8"  \
              --host-pubkey "/opt/jenkins/.ssh/id_rsa.pub" --host-privkey "/opt/jenkins/.ssh/id_rsa" \
              --web-service "rest" --host-password="${host_password_var}"  --host-user="root"  --release="True"
          ir beaker -vvvv --url="https://beaker.engineering.redhat.com" --beaker-user="$beaker_username_var" \
              --beaker-password="${beaker_password_var}" --host-address="$server" --image="centos-8"  \
              --host-pubkey "/opt/jenkins/.ssh/id_rsa.pub" --host-privkey "/opt/jenkins/.ssh/id_rsa" \
              --web-service "rest" --host-password="${host_password_var}"  --host-user="root"
          '''
        }
      }
    }
    stage('Configure Hypervisor') {
      when {
        expression {
          false
        }
      }
      steps {
        sh '''
        alias ssht="ssh  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i /opt/jenkins/.ssh/id_rsa root@${server} "
        ssht 'yum install -y git python3 python3-virtualenv python3-libselinux git make wget jq'
        ssht 'yes|ssh-keygen -t rsa -q -f "$HOME/.ssh/id_rsa" -N ""; cat $HOME/.ssh/id_rsa.pub >> $HOME/.ssh/authorized_keys '
        '''
      }
    }

    stage('Setup OCP requirements') {
      when {
        expression {
          true
        }
      }
      steps {
        sh '''
        alias ssht="ssh  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i /opt/jenkins/.ssh/id_rsa root@${server} "
        ssht 'useradd kni; cp /root/.ssh /home/kni/ -rf; echo "kni ALL=(ALL) NOPASSWD: ALL" >/etc/sudoers.d/kni'
        ssht 'rm -rf /home/kni/pull-secret.json'
        '''

        withCredentials([file(credentialsId: 'skramaja-pull-secret', variable: 'pull_secret_file')]) {
          sh '''
          alias scpk="scp  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i /opt/jenkins/.ssh/id_rsa "
          scpk ${pull_secret_file} kni@${server}:/home/kni/pull-secret.json
          '''
        }

        sh '''
        alias sshk="ssh  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i /opt/jenkins/.ssh/id_rsa kni@${server} "
        sshk 'rm -rf $HOME/dev-scripts; git clone https://github.com/openshift-metal3/dev-scripts'
        sshk 'cd $HOME/dev-scripts; cp config_example.sh config_$USER.sh;'
        sshk 'echo "export OPENSHIFT_RELEASE_TYPE=ga">>$HOME/dev-scripts/config_kni.sh'
        sshk 'echo "export OPENSHIFT_VERSION=4.5.0">>$HOME/dev-scripts/config_kni.sh'
        sshk 'echo "export PERSONAL_PULL_SECRET=$HOME/pull-secret.json">>$HOME/dev-scripts/config_kni.sh'
        sshk 'echo "export IP_STACK=v4">>$HOME/dev-scripts/config_kni.sh'
        sshk 'echo "export NUM_WORKERS=0">>$HOME/dev-scripts/config_kni.sh'
        sshk 'echo "export PRO_IF=eno2">>$HOME/dev-scripts/config_kni.sh'
        sshk 'echo "export INT_IF=eno3">>$HOME/dev-scripts/config_kni.sh'
        sshk 'echo "export CLUSTER_NAME=vnf">>$HOME/dev-scripts/config_kni.sh'
        sshk 'echo "export BASE_DOMAIN=krs.metal3.io">>$HOME/dev-scripts/config_kni.sh'
        sshk 'echo "export PROVISIONING_NETWORK=172.51.0.0/16">>$HOME/dev-scripts/config_kni.sh'
        sshk 'echo "export MASTER_MEMORY=16384">>$HOME/dev-scripts/config_kni.sh'
        sshk 'echo "export MASTER_DISK=40">>$HOME/dev-scripts/config_kni.sh'
        sshk 'echo "export MASTER_VCPU=8">>$HOME/dev-scripts/config_kni.sh'
        sshk 'echo "export EXTERNAL_SUBNET_V4=192.168.212.0/24">>$HOME/dev-scripts/config_kni.sh'
        sshk 'echo "export WORKING_DIR=/home/dev-scripts">>$HOME/dev-scripts/config_kni.sh'
        '''

        withCredentials([string(credentialsId: 'skramaja_ci_token', variable: 'ci_token')]) {
          sh '''
          ENTRY="export CI_TOKEN=${ci_token}"
          echo $ENTRY>/tmp/test.txt
          cat /tmp/test.txt
          alias sshk="ssh  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i /opt/jenkins/.ssh/id_rsa kni@${server} "
          sshk 'echo "export CI_TOKEN='${ci_token}'">>$HOME/dev-scripts/config_kni.sh'
          '''
        }
      }
    }

    stage('Deploy OCP') {
      when {
        expression {
          true
        }
      }
      steps {
       sh '''
        alias sshk="ssh  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i /opt/jenkins/.ssh/id_rsa kni@${server} "
        sshk 'cd $HOME/dev-scripts; make'
        '''
      }
    }
  }
}

ln -s /usr/bin/python3 /usr/bin/python
wget https://golang.org/dl/go1.15.2.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.15.2.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
rm -f go1.15.2.linux-amd64.tar.gz
