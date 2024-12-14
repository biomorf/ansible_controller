# -*- mode: ruby -*-
# vi: set ft=ruby :

RESTART_HOST_DIR = "/vagrant_data"
HOST_HOME_DIR = ENV['HOME']

#VAGRANT_REQUIRED >= 1.8
Vagrant.require_version ">= 1.8"

VAGRANTFILE_API_VERSION = "2"
VAGRANT_BOX = "ubuntu/focal64"

if Vagrant::Util::Platform.windows?
    # is windows
    puts "Vagrant launched from windows."
    # TODO test on Windows PS
    DOCKER_GID = `wsl.exe stat -c '%g' //var/run/docker.sock | tr -d '\n'`
    puts "vagrant host: /var/run/docker.sock is owned by GID #{DOCKER_GID}"
elsif Vagrant::Util::Platform.darwin?
    # is mac
    puts "Vagrant launched from mac."
elsif Vagrant::Util::Platform.linux?
    # is linux
    puts "Vagrant launched from linux."
    #DOCKER_GID = 121
    DOCKER_GID = `stat -c '%g' /var/run/docker.sock | tr -d '\n'`
    puts "vagrant host: /var/run/docker.sock is owned by GID #{DOCKER_GID}"
else
    # is some other OS
    puts "Vagrant launched from unknown platform."

end

RESTART_HOST_IP = "172.21.0.1"
RESTART_GUEST_IP = "172.21.0.21"

PROXY_URL="http://10.0.2.2"
PROXY_PORT="8000"
PROXY="#{PROXY_URL}:#{PROXY_PORT}"
PROXY=""


Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.define "vagrant.docker", autostart: true do |docker|
    docker.vm.hostname = "vagrant.docker"

    ### NOTE   OK on Windows PS with Docker Desktop through WSL2
    ############################################################
    # Provider for Docker on Intel or ARM (aarch64)
    ############################################################
    docker.vm.provider :docker do |d, override|
      override.vm.box = nil
      d.name = "vagrant.docker"
      d.build_dir = "."
      d.dockerfile = "Dockerfile.ubuntu.dind.vagrant.ansible"
      d.build_args = ["--build-arg", "DOCKER_GID=#{DOCKER_GID}", "--tag", "vagrant.docker:latest"]
      d.remains_running = true
      d.has_ssh = true

      d.privileged = true
      d.volumes = ["//sys/fs/cgroup:/sys/fs/cgroup:rw"]
      d.create_args = ["-t", "--cgroupns=host", "--security-opt", "seccomp=unconfined", "--cap-add=SYS_ADMIN", "--tmpfs", "/tmp", "--tmpfs", "/run", "--tmpfs", "/run/lock", "--mount", "type=bind,source=//var/run/docker.sock,target=/var/run/docker.sock"]
    end

    docker.vm.boot_timeout = 600

    docker.vm.synced_folder ".", RESTART_HOST_DIR

    ### TODO test set static ip
    ### NOTE if linux master-host in qemu cloud-init image
    docker.vm.network :public_network, type: "dhcp", bridge: ["ifname03" ], docker_network__gateway: "10.0.2.2", docker_network__ip_range: "10.0.2.0/24"
    ### NOTE if linux master-host in virt-manager
    #docker.vm.network :public_network, type: "dhcp", bridge: [ "enp1s0" ], docker_network__gateway: "192.168.124.1", docker_network__ip_range: "192.168.124.0/24"

    #docker.vm.network :public_network, type: "dhcp", bridge: "eth0", docker_network__ip_range: "192.168.1.252/30"


    docker.vm.network "forwarded_port", guest: 80, host: 8081

      ### Project private network
    docker.vm.network :private_network, ip: RESTART_GUEST_IP, netmask: 16, docker_network__gateway: "#{RESTART_HOST_IP}"


#    docker.vm.provision "ansible_local" do |ansible|
#      ### https://developer.hashicorp.com/vagrant/docs/provisioning/ansible_local
#      #ansible.provisioning_path = "/vagrant_data"
#      ansible.provisioning_path = RESTART_HOST_DIR
#      ansible.playbook = "playbook.yml"
#
#      ansible.install = false
#        ### NOTE on Ubuntu 22.04:
#        ###  E: Package 'python-dev' has no installation candidate
#      #ansible.install = true
#      #ansible.version = "latest"
#      #ansible.install_mode = "default"
#      ansible.install_mode = "pip"
#      #ansible.version = "2.2.1.0"
#      ansible.pip_install_cmd = " \
#        https_proxy=#{PROXY} curl -s https://bootstrap.pypa.io/get-pip.py \
#        | sudo https_proxy=#{PROXY} python3"
#    end

  end

end

