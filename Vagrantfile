Vagrant.configure(2) do |config|
  config.vm.define 'moloch' do |box|
      box.vm.box = "ubuntu/xenial64"
      box.vm.hostname = 'moloch-singlehost'
      box.vm.network :private_network, ip: "192.168.10.11"
      box.vm.provider :virtualbox do |vb|
       vb.customize ["modifyvm", :id, "--memory", "1024"]
       vb.customize ["modifyvm", :id, "--cpus", "1"]
      end
      config.vm.provision "shell", path: "installMolochundElastic.bash"
  end
  config.vm.define 'grafana' do |box|
      box.vm.box = "ubuntu/xenial64"
      box.vm.hostname = 'grafana'
      box.vm.network :private_network, ip: "192.168.10.12"
      box.vm.provider :virtualbox do |vb|
       vb.customize ["modifyvm", :id, "--memory", "512"]
       vb.customize ["modifyvm", :id, "--cpus", "1"]
      end
      config.vm.provision "shell", path: "installInfluxundGrafana.bash"
  end
end
