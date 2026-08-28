# PVE

[![Hits](https://hits.spiritlhl.net/pve.svg?action=hit&title=Hits&title_bg=%23555555&count_bg=%230eecf8&edge_flat=false)](https://hits.spiritlhl.net)

感谢 Proxmox VE 的免费订阅支持

如果有未适配的商家的机器欢迎联系[@spiritlhl_bot](https://t.me/spiritlhl_bot)，有空会尝试支持一下

## 更新

2025.11.05

- 适配部分独立服务器安装过程中的热插拔，识别allow-hotplug热插拔的情况，避免重启断网
- 通过ndisc6确保在SLAAC分配IPV6子网时可能出现的子网识别大小错误的问题，直接从路由器中获取真实的大小
- 确保文件之间无前后顺序依赖，避免IPV6子网掩码检测从未从路由器实际检测过，确保至少执行过一次

[更新日志](CHANGELOG.md)

## 说明文档

国内(China Docs)：

[https://virt.spiritlhl.net/](https://virt.spiritlhl.net/)

国际(English Docs)：

[https://www.spiritlhl.net/en/](https://www.spiritlhl.net/en/)

说明文档中 Proxmox VE 分区内容

自修补虚拟机镜像源：

[https://github.com/oneclickvirt/pve_kvm_images](https://github.com/oneclickvirt/pve_kvm_images)

[https://github.com/oneclickvirt/kvm_images](https://github.com/oneclickvirt/kvm_images)

[https://github.com/oneclickvirt/macos](https://github.com/oneclickvirt/macos)

自修补容器镜像源：

[https://github.com/oneclickvirt/lxc_amd64_images](https://github.com/oneclickvirt/lxc_amd64_images)

[https://github.com/oneclickvirt/pve_lxc_images](https://github.com/oneclickvirt/pve_lxc_images)

[https://github.com/oneclickvirt/lxc_arm_images](https://github.com/oneclickvirt/lxc_arm_images)

## Introduce

English Docs:

[https://www.spiritlhl.net/en/](https://www.spiritlhl.net/en/)

Description of the **Proxmox VE** partition contents in the documentation

Self-patching VM image sources:

[https://github.com/oneclickvirt/pve_kvm_images](https://github.com/oneclickvirt/pve_kvm_images)

[https://github.com/oneclickvirt/kvm_images](https://github.com/oneclickvirt/kvm_images)

[https://github.com/oneclickvirt/macos](https://github.com/oneclickvirt/macos)

Self-patching container image source:

[https://github.com/oneclickvirt/lxc_amd64_images](https://github.com/oneclickvirt/lxc_amd64_images)

[https://github.com/oneclickvirt/pve_lxc_images](https://github.com/oneclickvirt/pve_lxc_images)

[https://github.com/oneclickvirt/lxc_arm_images](https://github.com/oneclickvirt/lxc_arm_images)

## 友链

VPS融合怪测评脚本

https://github.com/oneclickvirt/ecs

https://github.com/spiritLHLS/ecs

## Stargazers over time

[![Stargazers over time](https://starchart.cc/oneclickvirt/pve.svg)](https://github.com/oneclickvirt/ecs)



# PVE 自动化部署脚本

本仓库包含用于 Proxmox VE 的自动化安装、环境优化、NAT 网络配置及虚拟机创建脚本。

## 🚀 快速开始 (全自动)
安装 sudo、git、curl 和 wget。
```bash
apt update && apt install sudo git curl wget -y
```
您可以直接运行 `auto_install.sh` 脚本，它会自动按顺序执行下方的所有步骤。
```bash
wget -P /root -N --no-check-certificate "https://raw.githubusercontent.com/Novice-S/pve/main/auto_install.sh" && chmod +x /root/auto_install.sh && /root/auto_install.sh
```
虚拟机掉卡解决办法：运行此修复命令后
```bash
apt update && apt install linux-headers-$(uname -r) build-essential dkms -y
```
再重装N卡驱动
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Novice-S/nvidia-install-scripts/main/install_nvidia.sh)
```

## 📂 分步执行指南

如果不使用全自动脚本，请按照以下步骤逐步执行。

## 0. 安装基础依赖
安装 sudo、git、curl 和 wget。
```bash
apt update && apt install sudo git curl wget -y
```

## 1. 下载 pve 库到本地

```bash
git clone https://github.com/Novice-S/pve.git
```

## 2. 赋予脚本执行权限

```bash
chmod -R +x /root/pve/scripts
```

## 3. 安装 PVE

```bash
cd /root/pve/scripts
./install_pve.sh
```

## 4. 环境初始化与优化

```bash
cd /root/pve/scripts
./build_backend.sh
```

## 5. 配置 PVE 的 NAT 网络

```bash
cd /root/pve/scripts
./build_nat_network.sh
```

## 6. 一键替换 GRUB 配置
此步骤用于拆分 IOMMU Group（防止直通硬件导致宿主机死机），并开启 AMD IOMMU 支持。
> **注意**：执行后需要重启。

```bash
cp /etc/default/grub /etc/default/grub.bak && \
sed -i 's|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT="quiet amd_iommu=on iommu=pt video=efifb:off pcie_acs_override=downstream,multifunction"|' /etc/default/grub && \
update-grub
reboot
```

## 7. 检查 IOMMU 分组
重启后检查分组是否拆开（不同 Group 编号代表成功）。

```bash
for d in /sys/kernel/iommu_groups/*/devices/*; do n=${d#*/iommu_groups/*}; n=${n%%/*}; printf 'Group %04d: ' $n; lspci -nns ${d##*/}; done | grep -iE "nvidia|ethernet"
```

## 8. 运行新建虚拟机 101 脚本

```bash
cd /root/pve/scripts
./101buildvm.sh
```

## 9. 运行新建虚拟机 102 脚本

```bash
cd /root/pve/scripts
./102buildvm.sh
```

## 10. 登录后台
部署完成后，请访问：
`https://HostIP:8006`

## 11. 常用检测命令

### 检测是否开启虚拟化
如果有输出 `/dev/kvm` 相关信息，说明 KVM 已启用。

```bash
ls -l /dev/kvm
```

### 查询 iptables NAT 规则
查看当前的端口转发配置。

```bash
iptables -t nat -L PREROUTING -n -v --line-numbers
```
### 删掉 Ubuntu 云镜像自带的强制限制文件
后台手动敲，之后就能SSH上

```bash
rm -f /etc/ssh/sshd_config.d/*.conf
```
### 手动下载 Ubuntu 22.04 QCOW2 镜像

如果自动下载失败，可以使用 Ubuntu 官方镜像手动下载：

```bash
wget -O /root/qcow/ubuntu22.qcow2 \
"https://github.com/oneclickvirt/pve_kvm_images/releases/download/ubuntu/ubuntu2204.qcow2"
```

### 安装 iptables-persistent

```bash
apt update && apt install -y iptables-persistent
```
### 🛠️ 故障排查：PVE NAT 小鸡无法联网（100% 丢包）

#### 1. 问题现象
虚拟机（小鸡）内部虽然配置好了局域网 IP 和网关（如 `172.16.1.x`），但 `ping 8.8.8.8` 提示 **100% 丢包**，无法访问外网。

#### 2. 根本原因
PVE 宿主机虽然配置了入站端口转发（`PREROUTING`），但**缺少出站的地址伪装规则（MASQUERADE）**，导致小鸡发出的内网数据包无法被宿主机的外网网卡（如 `vmbr0`）正确转发。

#### 3. 解决步骤

---

### 第一步：【在 PVE 宿主机执行】开启内核路由转发**
```bash
# 临时生效
sysctl -w net.ipv4.ip_forward=1

# 永久写入配置
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p
```
### 第二步：【在 PVE 宿主机执行】添加 MASQUERADE 出站伪装规则
(注：请根据实际网段调整 -s 后面的小鸡网段，外网网卡通常为 vmbr0)

```bash
iptables -t nat -A POSTROUTING -s 172.16.1.0/24 -o vmbr0 -j MASQUERADE
```
### 第三步：【在 PVE 宿主机执行】持久化保存规则（防止重启失效）
```bash
# 确保已安装持久化工具
apt update && apt install -y iptables-persistent netfilter-persistent

# 保存当前规则
netfilter-persistent save
```
