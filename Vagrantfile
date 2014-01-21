# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure('2') do |config|
    config.vm.box = "precise64"
    
    config.vm.network :forwarded_port, guest: 8000, host:8111

    config.vm.network :forwarded_port, guest: 5432, host:5434

    config.vm.provision :shell, :path => "etc/install/install.sh", :args => "{{ project_name }}"
    
    config.vm.synced_folder ".", "/vagrant", disabled: true
    config.vm.synced_folder ".", "/vagrant/{{ project_name }}"

    config.vm.provider :aws do |provider, override|
        override.vm.box = "aws_{{ project_name }}"
    end

end

