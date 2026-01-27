cat > scripts/common.sh <<'EOF'
#!/usr/bin/env bash
set -euxo pipefail

# -----------------------------
# Rocky/RHEL base prereqs for Kubernetes + Kubespray
# -----------------------------

# 1) 기본 패키지
dnf -y update
dnf -y install \
  curl ca-certificates \
  git \
  iproute iproute-tc \
  net-tools \
  jq \
  tar unzip \
  socat \
  conntrack-tools \
  ebtables ethtool \
  nfs-utils \
  chrony \
  python3 \
  libselinux-python3 \
  policycoreutils-python-utils

# 2) 시간 동기화
systemctl enable --now chronyd

# 3) swap 비활성화 (K8s 필수)
swapoff -a || true
sed -i.bak '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# 4) 커널 모듈 로드 (K8s 네트워크)
cat >/etc/modules-load.d/k8s.conf <<MOD
overlay
br_netfilter
MOD

modprobe overlay || true
modprobe br_netfilter || true

# 5) sysctl 파라미터 (K8s 필수)
cat >/etc/sysctl.d/99-k8s.conf <<SYS
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
SYS

sysctl --system

# 6) 방화벽 (실습 환경에서는 보통 꺼서 변수 제거)
# - 실무에서는 켜고 포트만 여는 게 맞지만,
#   과제/실습에서 네트워크 이슈 줄이려면 OFF 추천
systemctl disable --now firewalld || true

# 7) /etc/hosts 고정 (편의)
cat >/etc/hosts <<HOSTS
127.0.0.1   localhost localhost.localdomain
192.168.76.10 bastion
192.168.76.11 cp1
192.168.76.21 w1
192.168.76.22 w2
192.168.76.23 w3
HOSTS

echo "[OK] common prereqs applied."
EOF

chmod +x scripts/common.sh
