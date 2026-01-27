# -*- mode: ruby -*-
# vi: set ft=ruby :

# =========================
# VM 설정
# =========================
VM_IMAGE = "nobreak-labs/ubuntu-noble"

VM_SUBNET = "192.168.76."   # ✅ 요청한 대역
VM_NAMES = {
  bastion: "bastion",
  control: "cp1",
  workers: ["w1", "w2", "w3"]
}

VM_CONFIG = {
  bastion: { cpus: 2, memory: 2048 },
  control: { cpus: 2, memory: 4096 },
  worker:  { cpus: 2, memory: 4096 }
}

# (선택) 추가 디스크 옵션
EXTRA_DISK_ENABLED = false
EXTRA_DISK_SIZE_GB = 10

# =========================
# 프로비저닝: APT 미러 변경 (ARM/x86 자동 분기)
# =========================
CHANGE_APT_REPO = <<-SCRIPT
  set -eux
  ARCH=$(uname -m)
  RELEASE=$(lsb_release -cs)

  if [ "$RELEASE" = "jammy" ]; then
    # Ubuntu 22.04
    if [ "$ARCH" = "x86_64" ]; then
      sed -i 's/archive.ubuntu.com\\|kr.archive.ubuntu.com\\|security.ubuntu.com/ftp.kaist.ac.kr/g' /etc/apt/sources.list
    elif [ "$ARCH" = "aarch64" ]; then
      sed -i 's/ports.ubuntu.com/ftp.kaist.ac.kr/g' /etc/apt/sources.list
    fi
  elif [ "$RELEASE" = "noble" ]; then
    # Ubuntu 24.04
    if [ "$ARCH" = "x86_64" ]; then
      sed -i 's|^URIs:.*|URIs: http://ftp.kaist.ac.kr/ubuntu/|g' /etc/apt/sources.list.d/ubuntu.sources
    elif [ "$ARCH" = "aarch64" ]; then
      sed -i 's|^URIs:.*|URIs: http://ftp.kaist.ac.kr/ubuntu-ports/|g' /etc/apt/sources.list.d/ubuntu.sources
    fi
  fi
SCRIPT

# =========================
# 노드 정의
# =========================
VMS = [
  { name: VM_NAMES[:bastion], role: :bastion, ip: "#{VM_SUBNET}10" },
  { name: VM_NAMES[:control], role: :control, ip: "#{VM_SUBNET}11" },
  { name: VM_NAMES[:workers][0], role: :worker, ip: "#{VM_SUBNET}21" },
  { name: VM_NAMES[:workers][1], role: :worker, ip: "#{VM_SUBNET}22" },
  { name: VM_NAMES[:workers][2], role: :worker, ip: "#{VM_SUBNET}23" },
].map do |vm|
  role_cfg =
    case vm[:role]
    when :bastion then VM_CONFIG[:bastion]
    when :control then VM_CONFIG[:control]
    else VM_CONFIG[:worker]
    end

  vm.merge(
    image: VM_IMAGE,
    cpus: role_cfg[:cpus],
    memory: role_cfg[:memory],
    extra_disk_enabled: EXTRA_DISK_ENABLED,
    extra_disk_size: EXTRA_DISK_SIZE_GB * 1024 # VBox uses MB
  )
end

# =========================
# VM 템플릿
# =========================
Vagrant.configure("2") do |config|
  VMS.each do |vm|
    config.vm.define vm[:name] do |node|
      node.vm.box = vm[:image]
      node.vm.hostname = vm[:name]

      node.vm.provider "virtualbox" do |vb|
        vb.linked_clone = false
        vb.name = "k8s-#{vm[:name]}"
        vb.cpus = vm[:cpus]
        vb.memory = vm[:memory]

        # (선택) 추가 디스크
        if vm[:extra_disk_enabled] == true
          disk_dir = "disks"
          disk_path = "#{disk_dir}/#{vm[:name]}.vmdk"
          Dir.mkdir(disk_dir) unless Dir.exist?(disk_dir)

          unless File.exist?(disk_path)
            vb.customize ["createmedium", "disk", "--format", "VMDK", "--filename", disk_path, "--size", vm[:extra_disk_size]]
          end
          # 컨트롤러 이름은 박스/환경에 따라 다를 수 있어. 안 붙으면 주석 처리 후 진행.
          vb.customize ["storageattach", :id, "--storagectl", "VirtIO Controller", "--port", 1, "--device", 0, "--type", "hdd", "--medium", disk_path]
        end
      end

      # 네트워크
      node.vm.network "private_network", ip: vm[:ip], nic_type: "virtio"

      # 공유폴더 비활성 (ARM/VirtualBox에서 이슈 줄이기)
      node.vm.synced_folder ".", "/vagrant", disabled: true

      # APT 미러 변경
      node.vm.provision "shell", inline: CHANGE_APT_REPO

      # 공통 OS 세팅
      node.vm.provision "shell", path: "scripts/common.sh", privileged: true

      # bastion 전용 세팅
      if vm[:role] == :bastion
        node.vm.provision "shell", path: "scripts/bastion.sh", privileged: true
      end
    end
  end
end
