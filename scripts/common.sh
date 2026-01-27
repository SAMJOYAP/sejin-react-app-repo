mkdir -p scripts

cat > scripts/common.sh <<'EOF'
#!/usr/bin/env bash
set -euxo pipefail

# 1) 기본 패키지
apt-get update -y
apt-get install -y \
  curl ca-certificates gnupg lsb-release \
  net-tools iproute2 jq \
  python3 python3-pip \
  git \
  chrony \
  socat conntrack

# 2) 시간 동기화
systemctl enable --now chrony || systemctl enable --now chronyd || true

# 3) swap 비활성화 (k8s 필수)
swapoff -a || true
sed -i.bak '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# 4) 커널 모듈 (k8s 네트워킹)
cat >/etc/modules-load.d/k8s.conf <<MOD
overlay
br_netfilter
MOD

modprobe overlay || true
modprobe br_netfilter || true

# 5) sysctl (k8s 요구)
cat >/etc/sysctl.d/99-k8s.conf <<SYS
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
SYS

sysctl --system

# 6) /etc/hosts 고정(편의)
cat >/etc/hosts <<HOSTS
127.0.0.1 localhost
192.168.76.10 bastion
192.168.76.11 cp1
192.168.76.21 w1
192.168.76.22 w2
192.168.76.23 w3
HOSTS

# 7) containerd 설치(선택)
# Kubespray가 설치/설정도 해주지만, 베이스로 미리 깔아두면 편할 때가 있음
apt-get install -y containerd || true
if systemctl list-unit-files | grep -q '^containerd'; then
  mkdir -p /etc/containerd
  containerd config default > /etc/containerd/config.toml || true
  # systemd cgroup 사용 권장
  sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml || true
  systemctl enable --now containerd || true
fi

echo "[OK] common.sh completed."
EOF

chmod +x scripts/common.sh
