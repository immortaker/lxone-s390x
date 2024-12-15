#!/bin/bash  

# 检查是否存在名为 'yz' 的 screen  
if screen -list | grep -q "yz"; then
    echo "找到名为 'yz' 的 screen，正在关闭..."  
    # 关闭名为 'yz' 的 screen  
    screen -S yz -X quit
fi

# 创建一个新的 'yz' screen，并在其中静默运行 'yz' 命令  
echo "创建新的 'yz' screen，并静默运行 'yz' 命令..."  
screen -S yz -dm bash -c "yz"

echo "脚本完成。"
