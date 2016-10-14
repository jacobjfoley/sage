# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.
  config.vm.box = "fedora/23-cloud-base"

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  config.vm.network "forwarded_port", guest: 3000, host: 3000

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
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for libvirt. These expose provider-specific options.
  config.vm.provider "libvirt" do |lv|
  
    # Customize the amount of memory on the VM:
    lv.memory = 1024
  end

  # View the documentation for the provider you are using for more
  # information on available options.

  # Define a Vagrant Push strategy for pushing to Atlas. Other push strategies
  # such as FTP and Heroku are also available. See the documentation at
  # https://docs.vagrantup.com/v2/push/atlas.html for more information.
  # config.push.define "atlas" do |push|
  #   push.app = "YOUR_ATLAS_USERNAME/YOUR_APPLICATION_NAME"
  # end

  # Define shell script.
  $script = <<-SHELL
    
    # Update system.
    sudo dnf update -y
    
    # Install and configure PostgreSQL.
    sudo dnf install -y postgresql-server
    sudo postgresql-setup --initdb --unit postgresql
    sudo systemctl enable postgresql
    sudo systemctl start postgresql
    
    # Add user "vagrant" to PostgreSQL DB.
    sudo su --login postgres --command "psql --command 'create user vagrant with createdb login'"
    
    # Install dependencies.
    sudo dnf install -y gcc gcc-c++ make rpm-build ruby-devel nodejs ImageMagick-devel postgresql-devel
    
    # Move to synchronised folder.
    cd /vagrant
    
    # Install gems.
    gem install bundler 
    bundle install
    
    # Setup DB.
    bundle exec rake db:setup
    
    # Reminder.
    echo "Done. Remember to configure enviroment variables for the user vagrant! Refer to the wiki."
    echo "(Variables are for Google Drive integration and Amazon S3 storage of thumbnails.)" 
    echo "Usage: vagrant ssh; cd /vagrant; rails server -b 0.0.0.0"
    echo "Access: Navigate to http://localhost:3000 on your computer."
  
  SHELL

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  config.vm.provision "shell", inline: $script, privileged: false
end
