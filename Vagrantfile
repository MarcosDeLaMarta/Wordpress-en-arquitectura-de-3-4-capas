# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  config.vm.box = "debian/buster64"

  # BALANCEADOR
  config.vm.define "balanceadorMarcos" do |app|
    app.vm.hostname = "balanceadorMarcos"
    app.vm.network "private_network", ip: "192.168.2.10"
    app.vm.network "forwarded_port", guest: 80, host:9000
    app.vm.provision "shell", path: "balanceador.sh"
  end

  #serverNFS
  config.vm.define "serverNFSMarcos" do |app|
    app.vm.hostname = "serverNFSMarcos"
    app.vm.network "private_network", ip: "192.168.3.200"
    app.vm.provision "shell", path: "NFS.sh"
  end

  #serverweb1
  config.vm.define "serverweb1Marcos" do |app|
    app.vm.hostname = "serverweb1Marcos"
    app.vm.network "private_network", ip: "192.168.2.100"
    app.vm.network "private_network", ip: "192.168.3.100"
    app.vm.provision "shell", path: "serverweb1.sh"
  end

  #serverweb2
  config.vm.define "serverweb2Marcos" do |app|
    app.vm.hostname = "serverweb2Marcos"
    app.vm.network "private_network", ip: "192.168.2.101"
    app.vm.network "private_network", ip: "192.168.3.101"
    app.vm.provision "shell", path: "serverweb2.sh"
  end

  # Serverdatos1
  config.vm.define "ServerdatosMarcos" do |app|
    app.vm.hostname = "ServerdatosMarcos"
    app.vm.network "private_network", ip: "192.168.3.150"
    app.vm.provision "shell", path: "BBDD2.sh"
  end

  config.ssh.insert_key = false
  config.ssh.forward_agent = false

end
