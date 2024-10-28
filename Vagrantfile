# -*- mode: ruby -*-
# vi: set ft=ruby :

RESTART_HOST_DIR = "/vagrant_data"
#RESTART_HOST_DIR = ENV['RESTART_HOST_DIR']
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


### NFS can not docker's default overlay dirs,
### so you must use docker volumes
### OR bindmounted volume dirs
#   if bindmount a dir to docker volume from host
NFS_SRC_VOLUME = "/volume_src"
#NFS_SRC_VOLUME = "/home/def/brojects/restart2D_moodle/data/moodle_data"

NFS_EXPORT_ROOT_VOLUME = "/volume_share"
  #NFS_EXPORT_VOLUME = "/volume_share/1"
  #NFS_EXPORT_VOLUME = "/volume_share_1"

### dir for import from source
NFS_EXPORT_SRC = "/export_src"
#NFS_EXPORT_SRC = "/temp/moodle_data/overlay/upper"

### shared dirs on the NFS server
NFS_EXPORT_ROOT = "/export"
NFS_EXPORT_DIR = "/export/dir"
NFS_SERVER_IP = RESTART_HOST_IP

# here you'll want to mount shared folder to the NFS client
NFS_IMPORT_ROOT = "/import"
NFS_IMPORT_DIR = "/import/#{NFS_SERVER_IP}"
#NFS_IMPORT_DIR = "/srv/moodle_data"


Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.define "vagrant.docker", autostart: false do |docker|
    docker.vm.hostname = "vagrant.docker"

      ### Destroy containers before destroying guest
      ### NOTE temp triggers !!!
    docker.trigger.before [ :destroy, :reload ] do |trigger|
      trigger.info = "Remove docker artifacts..."
      trigger.run = { :inline => "docker rm --force --volumes liquibasec vagrant_data_moodle_1 vagrant_data_mariadb_1 vagrant_data-moodle-1 vagrant_data_mariadb_1 mariadb postgres" }
    end
    docker.trigger.after [ :destroy, :reload ] do |trigger|
      trigger.info = "Remove docker artifacts..."
      trigger.run = { :inline => "docker volume rm -f \
                        vagrant_data_lchangelog \
                        vagrant_data_mariadb_data \
                        vagrant_data_moodle_data \
                        vagrant_data_moodledata_data \
                    " }
      # vagrant_data_moodle_data_overlay_tmp \
    end
    docker.trigger.after [ :destroy, :reload ] do |trigger|
      trigger.info = "Remove docker artifacts..."
      trigger.run = { :inline => "docker network rm --force \
                        vagrant_data_moodle-network \
                    " }
    end

    ### NOTE   OK on Windows PS with Docker Desktop through WSL2
    ############################################################
    # Provider for Docker on Intel or ARM (aarch64)
    ############################################################
    docker.vm.provider :docker do |d, override|
      override.vm.box = nil
      d.name = "vagrant.docker"
      #d.image = ""
      #d.image = "rofrano/vagrant-provider:ubuntu"
      d.build_dir = "."
      #d.dockerfile = "Dockerfile.ubuntu.dind"
      d.dockerfile = "Dockerfile.ubuntu.dind.vagrant.ansible"
      d.build_args = ["--build-arg", "DOCKER_GID=#{DOCKER_GID}", "--tag", "vagrant.docker:latest"]
      d.remains_running = true
      d.has_ssh = true

      d.privileged = true
      d.volumes = ["//sys/fs/cgroup:/sys/fs/cgroup:rw"]
      #d.create_args = ["-t", "--cgroupns=host", "--security-opt", "seccomp=unconfined", "--tmpfs", "/tmp", "--tmpfs", "/run", "--tmpfs", "/run/lock", "--mount", "type=bind,source=//var/run/docker.sock,target=/var/run/docker.sock", "-v", "nfs_export_dir:#{NFS_EXPORT_DIR}", "-v", "nfs_export_root:#{NFS_EXPORT_ROOT}", "-v", "overlay:/overlay" ]
      d.create_args = ["-t", "--cgroupns=host", "--security-opt", "seccomp=unconfined", "--cap-add=SYS_ADMIN", "--tmpfs", "/tmp", "--tmpfs", "/run", "--tmpfs", "/run/lock", "--mount", "type=bind,source=//var/run/docker.sock,target=/var/run/docker.sock", "-v", "nfs_export_dir:#{NFS_EXPORT_DIR}", "-v", "nfs_export_root:#{NFS_EXPORT_ROOT}", "-v", "nfs_export_src:#{NFS_EXPORT_SRC}", "-v", "overlay:/overlay", "-v", "moodle_data_merged:/temp/moodle_data/merged/srv/moodle_data" ]
        #, "-v", "moodle_data_overlay:/temp/moodle_data/overlay"
        #"--mount", "type=bind,source=//var/run/docker.sock,target=/var/run/docker.sock",
        #"-v", "/sys/fs/cgroup:/sys/fs/cgroup:rw", #"--cgroupns=host", # Uncomment to force arm64 for testing images on Intel
      # d.create_args = ["--platform=linux/arm64", "--cgroupns=host"]

      #d.ports = ["8802:8802"]
    end

    ### Remove guest volumes
    docker.trigger.after [ :halt, :destroy, :reload ] do |trigger|
        # we need the users pass again
      #trigger.puts = "Please enter your password so that we can run mount"
      trigger.info = "Remove docker volumes with NFS exports"
      trigger.run = { :inline => "docker volume rm -f \
                        overlay \
                        moodle_data_overlay \
                        moodle_data_merged \
                        nfs_export_root \
                        nfs_export_dir \
                        nfs_export_src \
                    " }
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

        # default router
        #  docker.vm.provision "shell",
        #    privileged: "no",
        #    upload_path: '/home/vagrant/vagrant_set_router.sh',
        #    run: "always",
        #    inline: "route add default gw 172.21.0.1"


        ### comment out as it is included in Dockerfile
    ####docker.vm.provision "install_docker_compose", type: "shell",
    ####  privileged: "no",
    ####  upload_path: '/home/vagrant/vagrant_start_dev_provision.sh',
    ####  inline: <<-SHELL
    ####    sudo echo 'HI'
    ####    apt-get update && \
    ####    apt-get install --yes \
    ####      docker-compose \
    ####      inotify-tools \
    ####      curl
    ####    #https://downloads.rclone.org/rclone-current-linux-amd64.deb
    ####    #curl https://rclone.org/install.sh | sudo bash
    ####  SHELL

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


#    docker.vm.provision "env_dev_provision_vars", type: "shell",
#      env: {RESTART_HOST_DIR:RESTART_HOST_DIR, HOST_HOME_DIR:HOST_HOME_DIR},
#      #privileged: "no",
#      privileged: "yes",
#      upload_path: '/home/vagrant/host_env_dev_setup_vars.sh',
#      path: "script/host_env_dev_setup_vars.sh"


      ### Create and destroy project temp dirs on host
      ### https://linuxhandbook.com/vagrant-triggers/amp/
    docker.trigger.before :up do |trigger|
      trigger.info = "Host moodle_data triggers"
        ### 'run' on vagrant host
      trigger.run = { :inline => "bash -c 'sudo mkdir -pv \
                        /mnt/9p_default/brojects/restart2D_moodle/tmp/mariaconf/ \
                        /mnt/9p_default/brojects/restart2D_moodle/data/db \
                        /var/log/mysql/ \
                        /var/backups/mysql/ \
                        /srv/moodle_data \
                        /srv/moodledata_data \
                        /temp/moodle_data/overlay \
                        /mnt/9p_default/brojects/restart2D_moodle/data/moodle_data \
                        /mnt/9p_default/brojects/restart2D_moodle/data/changelog \
                        /mnt/9p_default/brojects/restart2D_moodle/tmp/changelog \
                        /srv/mariadb/data/ \
                        ; \
                        sudo chown -R 1001:0 /srv/mariadb/ ; \
                        sudo chown -R 1:0 /srv/moodledata_data/ ; \
                    '" }

        ### 'run remote' on vagrant guest
      #trigger.run_remote = { inline: "bash -c 'sudo mkdir -pv /srv/moodle_data'" }
    end

    docker.trigger.after [ :halt, :destroy, :reload ] do |trigger|
      trigger.info = "Remove docker artifacts..."
      trigger.run = { :inline => "sudo rm -rf \
                        /mnt/9p_default/brojects/restart2D_moodle/tmp/ \
                        /srv/mariadb/data/ \
                        /var/log/mysql/ \
                        /srv/moodledata_data \
                        /srv/moodle_data \
                        /temp/moodle_data/lower \
                        /temp/moodle_data" }
    end
                        #/mnt/9p_default_raw/brojects/restart2D_moodle/data/changelog \

#    docker.trigger.before :up do |trigger|
#      trigger.info = "Host liquibase source dir owner setup triggers"
#        ### 'run' on vagrant host
#        ### NOTE triggers aren't running bash scripts, they are executing binaries
#      trigger.run = { :inline => "bash -c 'sudo bindfs -u 1001 -o nonempty /mnt/9p_default_raw/brojects/restart2D_moodle/data/changelog $(realpath $(pwd))/tmp/changelog;'" }
#        ### 'run remote' on vagrant guest
#      #trigger.run_remote = { inline: "bash -c 'sudo mkdir -pv /srv/moodle_data'" }
#    end
#
#    docker.trigger.before :up do |trigger|
#      trigger.info = "Host mariadb source config dir owner setup triggers"
#        ### 'run' on vagrant host
#        ### NOTE triggers aren't running bash scripts, they are executing binaries
#      trigger.run = { :inline => "bash -c 'sudo bindfs -u 1001 -g 0 -o nonempty /home/def/restart/mariadb /mnt/9p_default/brojects/restart2D_moodle/tmp/mariaconf; sudo bindfs -u 1001 -g 0 -o nonempty /var/log/mysql /var/log/mysql;'" }
#        ### 'run remote' on vagrant guest
#      #trigger.run_remote = { inline: "bash -c 'sudo mkdir -pv /srv/moodle_data'" }
#    end

#    docker.trigger.before [ :halt, :destroy, :reload ] do |trigger|
#      trigger.info = "Host liquibase source dir owner setup triggers"
#        ### 'run' on vagrant host
#        ### NOTE triggers aren't running bash scripts, they are executing binaries
#      #trigger.run = { :inline => "bash -c 'sudo fusermount -u /mnt/9p_default_bindfs/brojects/restart2D_moodle/lchangelog;'" }
#      trigger.run = { :inline => "bash -c 'sudo fusermount -u $(realpath $(pwd))/tmp/changelog; sudo fusermount -u $(realpath $(pwd))/tmp/mariaconf; sudo fusermount -u /var/log/mysql;'" }
#        ### 'run remote' on vagrant guest
#      #trigger.run_remote = { inline: "bash -c 'sudo mkdir -pv /srv/moodle_data'" }
#    end

#    docker.trigger.before :up do |trigger|
#      trigger.info = "Host moodle_data triggers"
#        ### 'run' on vagrant host
#      trigger.run = { :inline => "sudo chown 'daemon:root' /srv/moodle_data" }
#        ### 'run remote' on vagrant guest
#      #trigger.run_remote = { inline: "bash -c 'sudo mkdir -pv /srv/moodle_data'" }
#    end


      ### Bind host's moodle_data dirs to guest
    #docker.vm.synced_folder "data/moodledata_lower", "/temp/moodle_data/lower"
    #docker.vm.synced_folder "data/moodledata", "/temp/moodle_data/upper"
    #docker.vm.synced_folder "data/moodledata_work", "/temp/moodle_data/work"
    docker.vm.synced_folder "/srv/moodle_data", "/srv/moodle_data"
    docker.vm.synced_folder "/temp/moodle_data", "/temp/moodle_data"
    docker.vm.synced_folder "/temp/moodle_data/overlay", "/temp/moodle_data/overlay"
    ### make volume?
    #docker.vm.synced_folder "/temp/moodle_data/merged/srv/moodle_data", "/temp/moodle_data/merged/srv/moodle_data"

    #docker.vm.synced_folder "/testx", "/testx"
    #docker.vm.synced_folder "/testx", "/temp/moodle_data/overlay"
    ### make volume?

    ### FSTYPE
    ## on qemu in cloud-init image: fuse
    ## on virt-manager in desktop: ???
#    docker.vm.synced_folder "./data", "#{RESTART_HOST_DIR}/data"


#    docker.vm.provision "upgrade_moodle", type: "shell",
#      #    run: "never",
#      env: {RESTART_HOST_DIR:RESTART_HOST_DIR},
#      privileged: "no",
#      upload_path: '/home/vagrant/upgrade_moodle.sh',
#      inline: "/bin/bash #{RESTART_HOST_DIR}/script/upgrade_moodle.sh"
    ### OR placeholder for "upgrade_moodle" provision
#    docker.vm.provision "upgrade_moodle_placeholder", type: "shell",
#      env: {RESTART_HOST_DIR:RESTART_HOST_DIR},
#      privileged: "no",
#      upload_path: '/home/vagrant/upgrade_moodle_placeholder.sh',
#      inline: "/bin/bash #{RESTART_HOST_DIR}/script/upgrade_moodle_placeholder.sh"


#    docker.vm.provision "env_dev_provision_disk", type: "shell",
#      env: {RESTART_HOST_DIR:RESTART_HOST_DIR},
#      privileged: "no",
#      upload_path: '/home/vagrant/host_env_dev_setup_disk.sh',
#      path: "script/host_env_dev_setup_disk.sh"

   #    ### TODO find out why it needs to reset sometimes...!!!
   #    ###      ??? after disk provision ???
   #    docker.vm.provision "reset_db_after_disk_provision", type: "shell",
   #      after: "env_dev_provision_disk",
   #      privileged: "no",
   #      upload_path: '/home/vagrant/vagrant_reset_db_after_disk_provision.sh',
   #      inline: <<-SHELL
   #        echo ' '
   #        echo '        ### TODO find out why it needs to reset'
   #        echo '        ###      ??? after disk provision ???'
   #        echo ' '
   #
   #        docker volume rm vagrant_data_mariadb_data
   #      SHELL

#    docker.vm.provision "mount_merged_srv_moodle_back", type: "shell",
#      after: "env_dev_provision_disk",
#      privileged: "no",
#      upload_path: '/home/vagrant/vagrant_reset_db_after_disk_provision.sh',
#      inline: <<-SHELL
#        mount --bind /temp/moodle_data/merged/srv/moodle_data /srv/moodle_data
#      SHELL


      ### NFS server
      ###   for export merged moodle_data back to host

      # forward the NFS port
    docker.vm.network "forwarded_port", guest: 2049, host: 8049

#    docker.trigger.before :up do |trigger|
#      trigger.info = "Host moodle_data triggers"
#        ### 'run' on vagrant host
#      trigger.run = { :inline => "sudo mkdir -pv #{NFS_SRC_VOLUME} #{NFS_EXPORT_SRC}" }
#        ### 'run remote' on vagrant guest
#      #trigger.run_remote = { inline: "bash -c 'sudo mkdir -pv /srv/moodle_data'" }
#    end
#
#    docker.trigger.before :up do |trigger|
#      trigger.info = "Host moodle_data triggers"
#        ### 'run' on vagrant host
#      #trigger.run = { :inline => "sudo mount --bind /overlay/home/share_middle/def/brojects/restart2D_moodle/data/moodle_data #{NFS_EXPORT_SRC}" }
#      trigger.run = { :inline => "sudo mount --bind /mnt/9p_bind/brojects/restart2D_moodle/data/moodle_data #{NFS_EXPORT_SRC}" }
#
#      ## TODO test
#      #trigger.run = { :inline => "sudo mount --bind $(realpath #{NFS_SRC_VOLUME}) #{NFS_EXPORT_SRC}" }
#        ### 'run remote' on vagrant guest
#      #trigger.run_remote = { inline: "bash -c 'sudo mkdir -pv /srv/moodle_data'" }
#    end

    #docker.vm.synced_folder NFS_EXPORT_SRC, NFS_EXPORT_SRC
    #docker.vm.synced_folder NFS_SRC_VOLUME, NFS_EXPORT_SRC
####        #    docker.vm.synced_folder NFS_EXPORT_ROOT_VOLUME, NFS_EXPORT_ROOT
####        #    docker.vm.synced_folder NFS_EXPORT_VOLUME, NFS_EXPORT_DIR
####

####      ### https://linuxhandbook.com/vagrant-triggers/amp/
####    docker.trigger.before :up do |trigger|
####      trigger.info = "Create Volumes on docker NFS server"
####        ### 'run' on vagrant host
####      #trigger.run = { :inline => "sudo mkdir -pv #{NFS_SRC_VOLUME} #{NFS_EXPORT_ROOT_VOLUME} #{NFS_EXPORT_VOLUME}" }
####      trigger.run = { :inline => "sudo mkdir -pv #{NFS_SRC_VOLUME}" }
####        ### 'run remote' on vagrant guest
####      #trigger.run_remote = { inline: "bash -c 'sudo mkdir -pv /srv/moodle_data'" }
####    end
####
####
#    docker.vm.provision "Create_NFS_server' export dir on guest", type: "shell",
#      privileged: "no",
#      upload_path: '/home/vagrant/guest_dir_provision.sh',
#      inline: <<SCRIPT
#echo "Guest dir"
#        ### 'run remote' on vagrant guest
#echo "  Create source dir..."
#    #bash -c 'mkdir --verbose -p #{NFS_EXPORT_SRC}'
#    #echo "test export" > #{NFS_EXPORT_SRC}/test.txt
#mount --verbose --rbind /temp/moodle_data/merged/srv/moodle_data #{NFS_EXPORT_SRC}
#
#    # bash -c 'mkdir -pv #{NFS_EXPORT_ROOT}'
#chmod --verbose -R 777 #{NFS_EXPORT_ROOT}
#chown --verbose -R nobody:nogroup #{NFS_EXPORT_ROOT}
#
#    # bash -c 'mkdir --verbose -pv #{NFS_EXPORT_DIR}'
#mount --verbose --rbind #{NFS_EXPORT_SRC} #{NFS_EXPORT_DIR}
#SCRIPT
#
#    # configure NFS on guest
#    docker.vm.provision "NFS_server_provision", type: "shell",
#      privileged: "no",
#      upload_path: '/home/vagrant/vagrant_nfs_provision.sh',
#      inline: <<SCRIPT
#apt-get install -y nfs-kernel-server nfs-common portmap net-tools
#host_ip="$(netstat -rn | grep "^0.0.0.0 " | cut -d " " -f10)"
#
#echo "
##{NFS_EXPORT_ROOT}    $host_ip(rw,no_subtree_check,async,no_root_squash,insecure,fsid=0)    172.21.0.0/16(rw,no_subtree_check,async,no_root_squash,insecure,fsid=0)
#
##{NFS_EXPORT_DIR}     $host_ip(rw,no_subtree_check,async,no_root_squash,nohide,insecure)    172.21.0.1(rw,no_subtree_check,async,no_root_squash,nohide,insecure,fsid=1)
#" \
#  | tee --append /etc/exports
#
#exportfs -rav
#systemctl restart nfs-server
#SCRIPT
#
#    ### NFS client
#    # after the machine is up, mount the NFS share
#    docker.trigger.after :up do |trigger|
#      trigger.info = "Create dirs on NFS client"
#        # make the dir if it doesnt exist
#      trigger.run = { :inline => "sudo mkdir -pv " + NFS_IMPORT_ROOT + " " + NFS_IMPORT_DIR }
#    end
#
#    docker.trigger.after :up do |trigger|
#        # we need the users pass to mount (make sure you are a sudoer!)'
#      #trigger.puts = "Please enter your password so that we can run mount"
#      trigger.info = "Create NFS client"
#      #trigger.run = { :inline => "sudo mount -vvvv -t nfs -o vers=3 172.21.0.21:#{NFS_EXPORT_DIR}  #{NFS_IMPORT_DIR}" }
#      #trigger.run = { :inline => "sudo mount -vvvv -t nfs -o vers=4 172.21.0.21:/  #{NFS_IMPORT_DIR}" }
#        ### TODO fix access to NFSv3 server through localhost:8049
#      #trigger.run = { :inline => "sudo mount -vvv -t nfs -o vers=3,proto=tcp,port=8049 localhost:#{NFS_EXPORT_DIR}  #{NFS_IMPORT_DIR}" }
#      trigger.run = { :inline => "sudo mount -vvv -t nfs -o vers=4,proto=tcp,port=8049 localhost:/  #{NFS_IMPORT_DIR}" }
#    end
#
#    # before halting, unmount the share
#    docker.trigger.before [ :halt, :destroy, :reload ] do |trigger|
#        # we need the users pass again
#      #trigger.puts = "Please enter your password so that we can run mount"
#      trigger.info = "Umount NFS client dir"
#      trigger.run = { :inline => "bash -c 'sudo umount --force --lazy " + NFS_IMPORT_DIR + " || exit 0 ;'" }
#    end
#
#    docker.trigger.before [ :halt, :destroy, :reload ] do |trigger|
#        # we need the users pass again
#      #trigger.puts = "Please enter your password so that we can run mount"
#      trigger.info = "Umount NFS client dir"
#      trigger.run = { :inline => "bash -c 'sudo umount --force --lazy /srv/moodle_data/ || exit 0 ;'" }
#    end
#
#    docker.trigger.before [ :halt, :destroy, :reload ] do |trigger|
#      #trigger.puts = "Please enter your password so that we can run mount"
#      trigger.info = "Remove NFS client dir"
#      trigger.run = { :inline => "sudo rm --recursive --force " + NFS_IMPORT_DIR + " " + NFS_IMPORT_ROOT }
#    end

#    docker.trigger.after [ :halt, :destroy, :reload ] do |trigger|
#        # we need the users pass again
#      #trigger.puts = "Please enter your password so that we can run mount"
#      trigger.info = "Umount docker volumes with NFS exports"
#      trigger.run = { :inline => "sudo umount -f \
#                        /export_src \
#                    " }
#    end


#    docker.vm.provision "Setup_sync_git_source_dir_with_moodle_overlay_upper_dir", type: "shell",
#      env: {RESTART_HOST_DIR:RESTART_HOST_DIR},
#      privileged: "no",
#      upload_path: '/home/vagrant/sync_git_moodle_setup.sh',
#      path: "script/sync_git_moodle_setup.sh"

#    docker.trigger.after [ :up ] do |trigger|
#      trigger.info = "Mount imported merged /srv/moodle_data to host..."
#      trigger.run = { :inline => "\
#                        sudo mount --rbind \
#                          #{NFS_IMPORT_DIR}/dir \
#                          /srv/moodle_data \
#                        " }
#    end



#    docker.vm.provision "start_dev", type: "shell", run: "always",
#      privileged: "no",
#      upload_path: '/home/vagrant/vagrant_start_dev_provision.sh',
#      inline: <<-SHELL
#        #sudo mkdir -pv /temp/moodle_data/merged
#        #sudo mkdir -pv /srv/moodle_data
#        #cd #{RESTART_HOST_DIR} && docker compose up -d
#      SHELL

  end



  config.vm.define "vagrant.vbox", autostart: false do |vbox|
  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
    vbox.vm.box = VAGRANT_BOX
    vbox.vm.provider :virtualbox do |v|
      v.name = "moodle_devenv"
      #v.linked_clone = true
      v.linked_clone = true if Gem::Version.new(Vagrant::VERSION) >= Gem::Version.new('1.8.0')
      # shortcuts for memory and CPU settings
      #v.memory = 2048
      v.memory = "4096"
      v.cpus = "4"
      v.customize ["modifyvm", :id, "--cpuexecutioncap", "50"]
    end

    #vbox.vm.provision "docker" do |d|
      ## build an image
      # it is an argument to 'docker build' in guest
      # so this path must exist there (use .synced_folder)
      #    d.build_image = "/vagrant/app"
      # additional args
      #    d.build_image = "/vagrant/app2"
      #    d.args = "-t 'tagname'"

      ## initial pull
      #d.images = ["ubuntu"]
      # subsequent pulls only on at a time
      #    d.pull_images "ubuntu2"
      #    d.pull_images "vagrant"

      ## run at 'vagrant up'
      #!!! only Ruby block syntax
      #d.run "rabbitmq"
      #d.run "ubuntu",
      #  cmd: "bash -l && echo 'from docker'",
      #  args: "-v '/vagrant:/var/www'"

      # run multiple containers based off the same image, you can do so by providing different names and specifying the image parameter to it:
      #d.run "db-1", image: "user/mysql"
      #d.run "db-2", image: "user/mysql"

      #
      #d.post_install_provision "shell", inline:"echo export http_proxy='http://127.0.0.1:3128/' >> /etc/default/docker"

      ## all
        #    d.run "ubuntu", # this overrides previous 'run'
        ## optional options
        # list of images to pull using docker pull
        #      image: "",
        #      args: "-v '/vagrant:/var/www'", # args to 'docker run'
        # The command to start within the container.
        # If not specified, then the container's default command will be used, such as the "CMD" command specified in the Dockerfile.
        #      cmd: "bash -l"

        #      auto_assign_name: true, # sets --name of container to the 1st argument of run (here is 'ubuntu')
        #      daemonize: true, # SAME AS docker run -d
        #      restart: "always"
    #end

    # Disable automatic box update checking. If you disable this, then
    # boxes will only be checked for updates when the user runs
    # `vagrant box outdated`. This is not recommended.
    # config.vm.box_check_update = false

    # Create a forwarded port mapping which allows access to a specific port
    # within the machine from a port on the host machine. In the example below,
    # accessing "localhost:8080" will access port 80 on the guest machine.
    # NOTE: This will enable public access to the opened port
     vbox.vm.network "forwarded_port", guest: 80, host: 8080

    # Create a forwarded port mapping which allows access to a specific port
    # within the machine from a port on the host machine and only allow access
    # via 127.0.0.1 to disable public access
    # config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"

    # Create a private network, which allows host-only access to the machine
    # using a specific IP.
    # config.vm.network "private_network", ip: "192.168.33.10"

    # Create a public network, which generally matched to bridged network.
    # Bridged networks make the machine appear as another physical device on
    # your network.
    # config.vm.network "public_network"

    # Share an additional folder to the guest VM. The first argument is
    # the path on the host to the actual folder. The second argument is
    # the path on the guest to mount the folder. And the optional third
    # argument is a set of non-required options.
    vbox.vm.synced_folder ".", RESTART_HOST_DIR
    #config.vm.synced_folder ".",  #{RESTART_HOST_DIR}

    # Provider-specific configuration so you can fine-tune various
    # backing providers for Vagrant. These expose provider-specific options.
    # Example for VirtualBox:

    # config.vm.provider "virtualbox" do |vb|
    #   # Display the VirtualBox GUI when booting the machine
    #   vb.gui = true

    #   # Customize the amount of memory on the VM:
    #   vb.memory = "1024"
    # end

    # View the documentation for the provider you are using for more
    # information on available options.

    # Enable provisioning with a shell script. Additional provisioners such as
    # Ansible, Chef, Docker, Puppet and Salt are also available. Please see the
    # documentation for more information about their specific syntax and use.
    vbox.vm.provision "install_docker_compose", type: "shell",
      privileged: "no",
      upload_path: '/home/vagrant/install_docker_compose.sh',
      inline: <<-SHELL
        apt-get update \
          && apt-get upgrade --yes \
          && apt-get install --yes docker-compose-v2 docker.io docker-buildx \
          #docker-compose \
          #inotify-tools \
          #curl
        usermod --append --groups docker vagrant
        #https://downloads.rclone.org/rclone-current-linux-amd64.deb
        #curl https://rclone.org/install.sh | sudo bash
      SHELL

    vbox.vm.provision "env_dev_provision_vars", type: "shell",
      env: {RESTART_HOST_DIR:RESTART_HOST_DIR},
      privileged: "no",
      upload_path: '/home/vagrant/host_env_dev_setup_vars.sh',
      path: "script/host_env_dev_setup_vars.sh"

    # upgrade|update overlay dirs with new moodle release from container
    # TODO make test with curl until success
    # then provision "upgrade_moodle" can be activated !!!
    # !!! Until then you can copy new moodle files into upper overlay dir only by hand !!!
    vbox.vm.provision "upgrade_moodle", type: "shell",
      #    run: "never",
      privileged: "no",
      upload_path: '/home/vagrant/upgrade_moodle.sh',
      inline: "/bin/bash #{RESTART_HOST_DIR}/script/upgrade_moodle.sh"
      #path: "script/upgrade_moodle.sh"

    vbox.vm.provision "env_dev_provision_disk", type: "shell",
      env: {RESTART_HOST_DIR:RESTART_HOST_DIR},
      privileged: "no",
      upload_path: '/home/vagrant/host_env_dev_setup_disk.sh',
      path: "script/host_env_dev_setup_disk.sh"

#    vbox.vm.provision "start_dev", type: "shell", run: "always",
#      env: {LOCAL_USERNAME_VAR:ENV['USERNAME'], PATH_VAR_ON_HOST:ENV['PATH']},
#      #    inline: "echo Guess you are $LOCAL_USERNAME_VAR. And you are about to run #{VAGRANT_BOX}. In case you need some random number, here it is directly from your host environment #{ENV['RANDOM']} "
#      inline: <<-SHELL
#        ##      source #{RESTART_HOST_DIR}/.env
#        echo "Guess you are $LOCAL_USERNAME_VAR."
#        echo "And you are about to run #{VAGRANT_BOX}."
#        echo "In case you need some random number, here it is directly from your host environment: #{ENV['RANDOM']}"
#        echo Starting in #{ENV['RESTART_HOST_DIR']} #{RESTART_HOST_DIR}...
#        #{RESTART_HOST_DIR}/script/bootstrap.sh
#        cd /vagrant/ && docker compose up -d
#      SHELL
  end

end

