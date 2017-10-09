Vagrant.configure(2) do |config|
  config.vm.define 'moloch' do |box|
      box.vm.box = "ubuntu/xenial64"
      box.vm.hostname = 'moloch-singlehost'
      box.vm.network :private_network, ip: "192.168.10.11"
      box.vm.provider :virtualbox do |vb|
       vb.customize ["modifyvm", :id, "--memory", "2048"]
       vb.customize ["modifyvm", :id, "--cpus", "2"]
      end
      config.vm.provision "shell", path: "installMoloch.bash"
  end
end
