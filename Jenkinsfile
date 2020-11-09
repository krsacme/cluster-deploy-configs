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
          true
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
          ir beaker -vv --url="https://beaker.engineering.redhat.com" --beaker-user="$beaker_username_var" \
              --beaker-password="${beaker_password_var}" --host-address="$server" --image="centos-8"  \
              --host-pubkey "/opt/jenkins/.ssh/id_rsa.pub" --host-privkey "/opt/jenkins/.ssh/id_rsa" \
              --web-service "rest" --host-password="${host_password_var}"  --host-user="root"  --release="True"
          ir beaker -vv --url="https://beaker.engineering.redhat.com" --beaker-user="$beaker_username_var" \
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
          true
        }
      }
      steps {
        sh '''
        alias ssht="ssh  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i /opt/jenkins/.ssh/id_rsa root@${server} "
        ssht 'yum install -y git python3 python3-virtualenv python3-libselinux git make wget jq tmux'
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

        withCredentials([file(credentialsId: '${params.beaker_user}-pull-secret', variable: 'pull_secret_file')]) {
          sh '''
          alias scpk="scp  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i /opt/jenkins/.ssh/id_rsa "
          scpk ${pull_secret_file} kni@${server}:/home/kni/pull-secret.json
          '''
        }

        sh '''
        alias sshk="ssh  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i /opt/jenkins/.ssh/id_rsa kni@${server} "
        sshk 'rm -rf $HOME/dev-scripts; git clone https://github.com/openshift-metal3/dev-scripts'
        sshk 'curl -o $HOME/dev-scripts/config_kni.sh https://raw.githubusercontent.com/krsacme/cluster-deploy-configs/master/ocp/4.5/config_kni.sh'
        '''

        withCredentials([string(credentialsId: '${params.beaker_user}-ci-token', variable: 'ci_token')]) {
          sh '''
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
