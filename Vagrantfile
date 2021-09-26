Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"
  config.vm.network "forwarded_port", guest:8065, host:8065
  config.vm.network "forwarded_port", guest: 80, host: 80
  config.vm.hostname = 'mattermost'

  setup_script = File.read('vm_setup.sh')
  
  config.vm.provision :shell, inline: setup_script, run: 'once'

end
