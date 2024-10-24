#!/bin/bash

# 切换到 root 账号
sudo -i <<EOF

# 更新包列表并安装QEMU和binfmt-support
echo "Installing QEMU and binfmt-support..."
apt-get update && apt-get install -y qemu-user-static binfmt-support

# 注册QEMU以支持x86架构
echo "Registering QEMU for x86 architecture..."
update-binfmts --enable qemu-x86_64

# 安装KVM相关组件
echo "Installing KVM and related components..."
apt-get install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils
systemctl start libvirtd
systemctl enable libvirtd

# 确认KVM安装
echo "Checking KVM installation..."
virsh list --all

# 下载并运行 docker.sh 脚本
echo "Running docker.sh script..."
bash <(curl -sSL https://linuxmirrors.cn/docker.sh)

# 自动输入等待命令
sleep 3
echo "Y" | xargs
sleep 6
echo "13" | xargs
sleep 6
echo "23" | xargs

# 再次运行 docker.sh 脚本（可能不必要，视情况而定）
bash <(curl -sSL https://linuxmirrors.cn/docker.sh)

# 修改 SSH 配置文件
echo "Configuring SSH settings..."
sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

# 确保 SSH 配置项存在
grep -qxF 'PermitRootLogin yes' /etc/ssh/sshd_config || echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
grep -qxF 'PubkeyAuthentication yes' /etc/ssh/sshd_config || echo 'PubkeyAuthentication yes' >> /etc/ssh/sshd_config

# 编辑认证文件
echo "Configuring authorized_keys..."
sed -i '/no-port-forwarding,no-agent-forwarding,no-X11-forwarding,command="echo/d' /root/.ssh/authorized_keys

# 重启 SSH 服务
echo "Restarting SSH service..."
systemctl restart sshd

# 运行 Docker 容器
echo "Running Docker container..."
docker run -d \
  --platform linux/amd64 \
  -it \
  -p 8066:22 \
  -p 60831:50831 \
  --name my-ubuntu-container \
  --security-opt seccomp=unconfined \
  --privileged \
  --restart unless-stopped \
  --device /dev/kvm \
  ubuntu:23.04 \
  /bin/bash -c "apt-get update && apt-get install -y openssh-server curl sudo && echo 'root:982498223' | chpasswd && \
  sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
  sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
  service ssh start && \
  while true; do sleep 1000; done"

# 获取容器 ID
container_id=$(docker ps -lq)

# 设置容器开机启动
docker update --restart unless-stopped $container_id

# 创建快捷命令，输入 'u' 进入容器的 /root 文件夹
echo "alias u='docker exec -it $container_id /bin/bash -c \"cd /root && bash\"'" >> ~/.bashrc

# 使更改生效
source ~/.bashrc

EOF

echo "所有操作已完成。"
