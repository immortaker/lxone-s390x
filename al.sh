file_name="alist-linux-s390x.tar.gz"
url="https://github.com/AlistGo/alist/releases/download/beta/$file_name"
service_file="/usr/lib/systemd/system/alist.service"
download_dir="/opt"  # 请根据需要设置下载目录
alist_executable="$download_dir/alist"  # 固定的可执行文件路径

# 函数：检查命令是否成功并输出相应信息
check_command() {
    if ! "$@"; then
        echo "命令失败: $*"
        exit 1
    fi
}

# 下载并解压 AList
echo "正在下载 $file_name ..."
check_command wget -O "$download_dir/$file_name" "$url"

echo "正在解压 $file_name ..."
check_command tar -xzvf "$download_dir/$file_name" -C "$download_dir"

# 清理下载的压缩文件
echo "清理下载的文件..."
check_command rm "$download_dir/$file_name"

# 检查 AList 可执行文件是否存在
if [ -f "$alist_executable" ]; then
    echo "给 $alist_executable 授予执行权限..."
    check_command chmod +x "$alist_executable"
else
    echo "找不到可执行文件 $alist_executable，请确认解压后的文件名。"
    exit 1
fi

# 获取 AList 所在目录
path_alist_dir=$(dirname "$alist_executable")

# 检查服务文件是否存在
if [ ! -f "$service_file" ]; then
    echo "创建 $service_file ..."
    cat <<EOL | sudo tee "$service_file" > /dev/null
[Unit]
Description=alist
After=network.target

[Service]
Type=simple
WorkingDirectory=$path_alist_dir
ExecStart=$alist_executable server
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL
else
    echo "服务文件 $service_file 已存在，更新内容..."
    sudo tee "$service_file" > /dev/null <<EOL
[Unit]
Description=alist
After=network.target

[Service]
Type=simple
WorkingDirectory=$path_alist_dir
ExecStart=$alist_executable server
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL
fi

# 重新加载 systemd 配置
sudo systemctl daemon-reload

# 启动 AList 服务
check_command sudo systemctl start alist

# 设置 AList 服务开机自启
check_command sudo systemctl enable alist

/opt/alist admin set 1
echo "AList 服务已启动并设置为开机自启,初始账户密码：admin；1。"
