# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure('2') do |config|
    config.vm.box = "precise64"
    
    config.vm.network :forwarded_port, guest: 8000, host:8111

    config.vm.network :forwarded_port, guest: 5432, host:5434

    config.vm.synced_folder ".", "/home/vagrant/twitter_listener"

    config.vm.provision :shell, :path => "etc/install/install.sh", :args => "twitter_listener"
    
    config.vm.provider :aws do |provider, override|
        override.vm.box = "aws-twitter-listener"
    end

end

