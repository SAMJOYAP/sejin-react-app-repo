cat > scripts/bastion.sh <<'EOF'
#!/usr/bin/env bash
set -euxo pipefail

# 1) 도구 설치
apt-get update -y
apt-get install -y \
  git sshpass \
  python3 python3-venv python3-pip

# 2) vagrant 유저 기준으로 ansible venv 구성
VAGRANT_HOME="/home/vagrant"
VENV_DIR="${VAGRANT_HOME}/.venvs/ansible"

mkdir -p "${VAGRANT_HOME}/.venvs"
chown -R vagrant:vagrant "${VAGRANT_HOME}/.venvs"

sudo -u vagrant python3 -m venv "${VENV_DIR}"

sudo -u vagrant bash -lc "
  source '${VENV_DIR}/bin/activate'
  pip install --upgrade pip wheel setuptools
  pip install 'ansible>=2.14,<2.17'
"

# 3) 로그인 시 자동 활성화(편의)
BASHRC="${VAGRANT_HOME}/.bashrc"
grep -q "source ${VENV_DIR}/bin/activate" "${BASHRC}" || echo "source ${VENV_DIR}/bin/activate" >> "${BASHRC}"

# 4) SSH 키 생성 (kubespray에서 cp1/w1/w2/w3 접속용)
if [ ! -f "${VAGRANT_HOME}/.ssh/id_rsa" ]; then
  sudo -u vagrant ssh-keygen -t rsa -b 4096 -N "" -f "${VAGRANT_HOME}/.ssh/id_rsa"
fi

# 5) known_hosts 미리 채우기
sudo -u vagrant bash -lc "ssh-keyscan -H cp1 w1 w2 w3 >> '${VAGRANT_HOME}/.ssh/known_hosts' || true"

echo "[OK] bastion.sh completed (ansible ready)."
EOF

chmod +x scripts/bastion.sh
