$image = "bento/ubuntu-20.04-arm64"
$ram = 2048
$cpu = 2

leader = {
    :hostname => "leader",
    :ram => $ram,
    :cpu => $cpu
}

managers = [
    {
      :hostname => "manager-1",
      :ram => $ram,
      :cpu => $cpu
    },
    {
      :hostname => "manager-2",
      :ram => $ram,
      :cpu => $cpu
    }
]

workers = [
    {
      :hostname => "worker-1",
      :ram => $ram,
      :cpu => $cpu
    },
    {
      :hostname => "worker-2",
      :ram => $ram,
      :cpu => $cpu
    }
]

def setup_node(node, machine)
  node.vm.hostname = machine[:hostname]
  node.vm.provider "vmware_fusion" do |vm|
    vm.memory = machine[:ram]
    vm.cpus = machine[:cpu]
  end
end

Vagrant.configure("2") do |config|
  config.vm.box = $image

  [*managers, *workers].each do |machine|
    config.vm.define machine[:hostname] do |node|
      setup_node(node, machine)
    end
  end

  config.vm.define "leader" do |node|
    setup_node(node, leader)
    node.vm.network "forwarded_port", guest: 80, host: 80

    node.vm.provision "ansible" do |ansible|
      ansible.compatibility_mode = "2.0"
      ansible.playbook = "playbook.yml"
      ansible.limit = "all"
      ansible.groups = {
          "leader" => leader[:hostname],
          "managers" => managers.map { |vm| vm[:hostname] },
          "workers" => workers.map { |vm| vm[:hostname] },
      }
      ansible.verbose = "v"
    end
  end
end
