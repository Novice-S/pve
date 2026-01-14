#!/bin/bash

# 定义颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 进度标记文件 (用来判断是第几次运行)
STAGE_FILE="/root/.pve_install_stage1_done"

echo -e "${GREEN}=== PVE 一键配置脚本 v4.1 (含VM部署) ===${NC}"

# 检查是否 root
if [ "$EUID" -ne 0 ]; then echo -e "${RED}请使用 root 运行！${NC}"; exit 1; fi

# ==========================================
# 逻辑判断：是第1次运行，还是重启后的第2次？
# ==========================================

if [ ! -f "$STAGE_FILE" ]; then
    # --------------------------------------
    # 阶段一：初次运行 (Step 0 - Step 3 part 1)
    # 目标：更换内核，准备环境
    # --------------------------------------
    echo -e "${YELLOW}>> 当前状态：第 1 次运行${NC}"
    echo -e "${YELLOW}>> 任务：安装依赖 -> 运行PVE安装脚本(换内核) -> 重启${NC}"
    
    # [Step 0] 统一安装依赖
    echo -e "${GREEN}[Step 0] 更新源并安装 sudo, git, curl...${NC}"
    apt update && apt install sudo git curl -y
    
    # [Step 1] 下载 PVE 库
    echo -e "${GREEN}[Step 1] 下载 PVE 脚本仓库...${NC}"
    if [ ! -d "/root/pve" ]; then
        git clone https://github.com/Novice-S/pve.git /root/pve
    else
        echo "目录 /root/pve 已存在，跳过克隆。"
    fi
    
    # [Step 2] 给执行权限
    echo -e "${GREEN}[Step 2] 赋予脚本执行权限...${NC}"
    chmod -R +x /root/pve/scripts
    
    # [Step 3] 安装 PVE (第一遍：换内核)
    echo -e "${GREEN}[Step 3] 正在运行 install_pve.sh (第 1 遍 - 更换内核)...${NC}"
    cd /root/pve/scripts
    ./install_pve.sh
    
    # 标记阶段一完成
    touch "$STAGE_FILE"
    
    echo -e "${RED}=======================================${NC}"
    echo -e "${RED} [阶段一成功] 内核已更换，必须重启系统！${NC}"
    echo -e "${YELLOW} 请在重启后，再次运行此脚本 (`./setup_pve.sh`)。${NC}"
    echo -e "${YELLOW} 第二次运行将自动执行：安装PVE软件 -> 配置网络 -> 创建虚拟机 (Step 8&9)${NC}"
    echo -e "${RED}=======================================${NC}"
    
    read -p "是否现在立即重启? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        reboot
    else
        echo "你选择了稍后重启。请务必重启后再次运行此脚本，否则 PVE 无法安装成功。"
        exit 0
    fi

else
    # --------------------------------------
    # 阶段二：重启后运行 (Step 3 part 2 - Step 9)
    # 目标：安装PVE软件，配置环境，建立虚拟机
    # --------------------------------------
    echo -e "${GREEN}>> 检测到阶段一标记文件。${NC}"
    echo -e "${GREEN}>> 当前状态：第 2 次运行 (重启后)${NC}"
    echo -e "${GREEN}>> 任务：完成 PVE 安装 -> 环境配置 -> 创建虚拟机${NC}"
    
    cd /root/pve/scripts
    
    # [Step 3 重复] 再次运行 install_pve.sh
    echo -e "${GREEN}[Step 3] 正在运行 install_pve.sh (第 2 遍 - 安装 PVE 核心软件)...${NC}"
    ./install_pve.sh
    
    echo -e "${GREEN}-------------------------------------------${NC}"
    echo -e "${GREEN} PVE 核心安装完成，开始配置环境与虚拟机...${NC}"
    echo -e "${GREEN}-------------------------------------------${NC}"

    # [Step 4] 环境初始化
    echo -e "${GREEN}[Step 4] 环境初始化 (build_backend.sh)...${NC}"
    ./build_backend.sh
    
    # [Step 5] 配置 NAT 网络
    echo -e "${GREEN}[Step 5] 配置 NAT 网络 (build_nat_network.sh)...${NC}"
    ./build_nat_network.sh
    
    # [Step 6] 修改 Grub (直通配置)
    echo -e "${GREEN}[Step 6] 修改 Grub 配置 (防死机/IOMMU分组)...${NC}"
    cp /etc/default/grub /etc/default/grub.bak
    sed -i 's|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT="quiet amd_iommu=on iommu=pt video=efifb:off pcie_acs_override=downstream,multifunction"|' /etc/default/grub
    update-grub
    
    # [Step 7] 提示 IOMMU
    echo -e "${GREEN}[Step 7] IOMMU 检查准备就绪 (将在最终重启后生效)${NC}"
    
    # [Step 8] 创建虚拟机 101
    # 只有前面的 install_pve.sh (第2遍) 跑完，这里才能成功
    echo -e "${GREEN}[Step 8] 正在创建虚拟机 101 (101buildvm.sh)...${NC}"
    if [ -f "./101buildvm.sh" ]; then
        chmod +x ./101buildvm.sh
        ./101buildvm.sh
    else
        echo -e "${RED}错误：未找到 101buildvm.sh，跳过。${NC}"
    fi

    # [Step 9] 创建虚拟机 102
    echo -e "${GREEN}[Step 9] 正在创建虚拟机 102 (102buildvm.sh)...${NC}"
    if [ -f "./102buildvm.sh" ]; then
        chmod +x ./102buildvm.sh
        ./102buildvm.sh
    else
        echo -e "${RED}错误：未找到 102buildvm.sh，跳过。${NC}"
    fi
    
    echo -e "${GREEN}=== 全流程结束！所有配置与虚拟机创建已完成 ===${NC}"
    echo -e "${YELLOW}为了让 Step 6 的 IOMMU 直通配置生效，系统需要最后一次重启。${NC}"
    echo -e "重启后，可运行以下命令检查分组："
    echo "for d in /sys/kernel/iommu_groups/*/devices/*; do n=\${d#*/iommu_groups/*}; n=\${n%%/*}; printf 'Group %04d: ' \$n; lspci -nns \${d##*/}; done | grep -iE \"nvidia|ethernet\""
    
    read -p "是否现在立即重启? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        reboot
    fi
    
    # 任务全部完成，可以选择是否删除标记文件，通常建议保留以免误触
fi