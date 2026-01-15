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
curl -o auto_install.sh https://raw.githubusercontent.com/Novice-S/pve/main/auto_install.sh && chmod +x auto_install.sh && ./auto_install.sh
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
