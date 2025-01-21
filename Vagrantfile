Vagrant.configure("2") do |config|

# charpentier CyberChef Build
  config.vm.define "charpentier" do |cfg|
    cfg.vm.box = "generic/debian12"
    cfg.vm.hostname = "charpentier"
    cfg.vm.network "public_network", dev: 'br0', bridge: 'br0', mode: 'bridge', type: 'bridge'
    cfg.vm.provision :file, source: './installfiles', destination: "/tmp/installfiles"
    cfg.vm.provision :shell, path: "bootstrap.sh"
    cfg.vm.synced_folder "./CyberChef/", "/mnt/build"
    
    cfg.vm.provider "libvirt" do |lv, override|
      lv.graphics_type = "vnc"
      lv.video_type = "vga"
      lv.input :type => "tablet", :bus => "usb"
      lv.video_vram = 4096
      lv.memory = 2048
      lv.cpus = 2
      lv.cpu_mode = "host-passthrough"
      # Which storage pool path to use. Default to /var/lib/libvirt/images or ~/.local/share/libvirt/images depending on if you are running a system or user QEMU/KVM session.
      lv.storage_pool_name = 'default'
      override.vm.synced_folder './', '/vagrant', type: 'rsync'
    end

    cfg.vm.provider "vmware_fusion" do |v, override|
      v.vmx["displayname"] = "charpentier"
      v.memory = 2048
      v.cpus = 2
      v.gui = false
    end

    cfg.vm.provider "vmware_desktop" do |v, override|
      v.vmx["displayname"] = "charpentier"
      v.memory = 2048
      v.cpus = 2
      v.gui = false
    end

    cfg.vm.provider "virtualbox" do |vb, override|
      vb.gui = false
      vb.name = "charpentier"
      vb.customize ["modifyvm", :id, "--memory", 2048]
      vb.customize ["modifyvm", :id, "--cpus", 2]
      vb.customize ["modifyvm", :id, "--vram", "4"]
      vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
      vb.customize ["setextradata", "global", "GUI/SuppressMessages", "all" ]
    end
  end

  # cyberchef CyberChef Build
  config.vm.define "cyberchef" do |cfg|
    cfg.vm.box = "generic/debian12"
    cfg.vm.hostname = "cyberchef"
    cfg.vm.network "public_network", type: "dhcp", bridge: 'enp1s0'
    cfg.vm.provision :file, source: './installfiles', destination: "/tmp/installfiles"
    cfg.vm.provision :shell, path: "bootstrap.sh"
    cfg.vm.synced_folder "./CyberChef/", "/mnt/build"

    cfg.vm.provider "libvirt" do |lv, override|
      lv.graphics_type = "vnc"
      lv.video_type = "vga"
      lv.input :type => "tablet", :bus => "usb"
      lv.video_vram = 4096
      lv.memory = 2048
      lv.cpus = 2
      lv.cpu_mode = "host-passthrough"
      # Which storage pool path to use. Default to /var/lib/libvirt/images or ~/.local/share/libvirt/images depending on if you are running a system or user QEMU/KVM session.
      lv.storage_pool_name = 'default'
      override.vm.synced_folder './', '/vagrant', type: 'rsync'
    end

    cfg.vm.provider "vmware_fusion" do |v, override|
      v.vmx["displayname"] = "cyberchef"
      v.memory = 2048
      v.cpus = 2
      v.gui = false
    end

    cfg.vm.provider "vmware_desktop" do |v, override|
      v.vmx["displayname"] = "cyberchef"
      v.memory = 2048
      v.cpus = 2
      v.gui = false
    end

    cfg.vm.provider "virtualbox" do |vb, override|
      vb.gui = false
      vb.name = "cyberchef"
      vb.customize ["modifyvm", :id, "--memory", 2048]
      vb.customize ["modifyvm", :id, "--cpus", 2]
      vb.customize ["modifyvm", :id, "--vram", "4"]
      vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
      vb.customize ["setextradata", "global", "GUI/SuppressMessages", "all" ]
    end
  end
end
