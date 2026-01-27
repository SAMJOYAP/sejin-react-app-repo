cat > scripts/bastion.sh <<'EOF'
#!/usr/bin/env bash
set -euxo pipefail

# -----------------------------
# Bastion: Ansible + Kubespray tooling
# -----------------------------

dnf -y update
dnf -y install git sshpass

# Rocky 8에서 ansible 최신 버전 안정적으로 쓰기 위해 python3.9 사용
# (Rocky 9면 기본 python3가 최신이라 아래 module enable이 실패할 수 있는데, 실패해도 넘어가게 처리)
dnf -y module enable python39 || true
dnf -y install python39 python39-pip python39-setuptools python39-wheel || true

# python3.9가 없으면 그냥 python3 사용 (Rocky 9 대비)
PY_BIN=""
if command -v python3.9 >/dev/null 2>&1; then
  PY_BIN="python3.9"
elif command -v python3 >/dev/null 2>&1; then
  PY_BIN="python3"
else
  echo "Python not found" >&2
  exit 1
fi

# vagrant 유저 홈에 venv 생성
VAGRANT_HOME="/home/vagrant"
VENV_DIR="${VAGRANT_HOME}/.venvs/ansible"

mkdir -p "${VAGRANT_HOME}/.venvs"
chown -R vagrant:vagrant "${VAGRANT_HOME}/.venvs"

sudo -u vagrant ${PY_BIN} -m venv "${VENV_DIR}"

# ansible 설치 (venv 내부)
sudo -u vagrant bash -lc "
  source '${VENV_DIR}/bin/activate'
  pip install --upgrade pip
  # Kubespray 호환성 범위로 고정(너무 최신으로 튀는 것 방지)
  pip install 'ansible>=2.14,<2.17'
"

# vagrant 로그인 시 자동으로 venv 활성화되게(편의)
BASHRC="${VAGRANT_HOME}/.bashrc"
grep -q "source ${VENV_DIR}/bin/activate" "${BASHRC}" || echo "source ${VENV_DIR}/bin/activate" >> "${BASHRC}"

# SSH 키 생성 (kubespray가 노드들로 ssh 접속할 때 사용)
if [ ! -f "${VAGRANT_HOME}/.ssh/id_rsa" ]; then
  sudo -u vagrant ssh-keygen -t rsa -b 4096 -N "" -f "${VAGRANT_HOME}/.ssh/id_rsa"
fi

# known_hosts 미리 등록
sudo -u vagrant bash -lc "ssh-keyscan -H cp1 w1 w2 w3 >> '${VAGRANT_HOME}/.ssh/known_hosts' || true"

echo "[OK] bastion tooling ready (ansible in venv)."
EOF

chmod +x scripts/bastion.sh
