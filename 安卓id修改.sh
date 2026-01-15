#!/system/bin/sh

# =========================================================
# 仿爱玩机工具箱 - Android ID 修改器 (Shell/Root版)
# 功能：备份原ID、随机/自定义修改、强制停止应用生效
# =========================================================

# --- 颜色定义 ---
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# --- 配置文件路径 ---
BACKUP_FILE="/sdcard/AndroidID_History.txt"

# --- 头部 Banner ---
clear
echo -e "${CYAN}#############################################${NC}"
echo -e "${CYAN}#          Android ID 深度修改工具          #${NC}"
echo -e "${CYAN}#          (仿爱玩机系统修改模式)           #${NC}"
echo -e "${CYAN}#############################################${NC}"

# --- 1. 检查 Root 权限 ---
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}[!] 错误：没有 Root 权限。${NC}"
    echo -e "请在 su 环境下运行此脚本。"
    exit 1
fi

# --- 2. 获取当前信息 ---
current_id=$(settings get secure android_id | tr -d '\r\n')
echo -e "${WHITE}当前系统 Android ID: ${YELLOW}$current_id${NC}"
echo -e "${CYAN}---------------------------------------------${NC}"

# --- 3. 获取目标应用 ---
echo -e "${GREEN}[1/3] 设置目标应用${NC}"
echo -e "输入包名后，脚本将在修改 ID 后自动强杀该应用以生效。"
echo -n "请输入应用包名 (直接回车跳过强杀): "
read package_name

if [ ! -z "$package_name" ]; then
    # 简单检测应用是否存在
    if pm path "$package_name" >/dev/null 2>&1; then
        echo -e ">> 已锁定目标: ${GREEN}$package_name${NC}"
    else
        echo -e ">> ${YELLOW}警告：未找到该应用，但仍会执行系统修改。${NC}"
    fi
else
    echo -e ">> 跳过应用强杀步骤，仅修改系统值。"
fi

echo -e "${CYAN}---------------------------------------------${NC}"

# --- 4. 选择修改模式 ---
echo -e "${GREEN}[2/3] 选择修改方式${NC}"
echo -e "${WHITE}1.${NC} 随机生成 (推荐)"
echo -e "${WHITE}2.${NC} 自定义输入"
echo -e "${WHITE}3.${NC} 恢复原来的 ID (从备份)"
echo -e "${WHITE}0.${NC} 退出"
echo -n "请输入选项: "
read choice

new_id=""

case $choice in
    1)
        # 生成随机ID (16位十六进制)
        new_id=$(cat /dev/urandom | tr -dc '0-9a-f' | head -c 16)
        echo -e ">> 生成随机 ID: ${CYAN}$new_id${NC}"
        ;;
    2)
        echo -n "请输入新的 Android ID (16位): "
        read input_id
        # 长度校验
        if [ ${#input_id} -ne 16 ]; then
            echo -e "${RED}[!] 长度错误，必须是16位！${NC}"
            exit 1
        fi
        new_id=$input_id
        ;;
    3)
        if [ ! -f "$BACKUP_FILE" ]; then
            echo -e "${RED}[!] 没有找到备份文件。${NC}"
            exit 1
        fi
        echo -e ">> 最近的备份记录："
        tail -n 5 "$BACKUP_FILE"
        echo -e ""
        echo -n "请输入要恢复的 ID: "
        read input_id
        new_id=$input_id
        ;;
    0)
        exit 0
        ;;
    *)
        echo -e "${RED}[!] 无效选项${NC}"
        exit 1
        ;;
esac

# --- 5. 执行修改与备份 ---
echo -e "${CYAN}---------------------------------------------${NC}"
echo -e "${GREEN}[3/3] 执行修改${NC}"

# 自动备份
timestamp=$(date "+%Y-%m-%d %H:%M:%S")
echo "[$timestamp] 原ID: $current_id -> 新ID: $new_id (App: $package_name)" >> "$BACKUP_FILE"
echo -e ">> 原 ID 已备份至: ${YELLOW}$BACKUP_FILE${NC}"

# 写入新 ID
settings put secure android_id "$new_id"

# 验证
final_id=$(settings get secure android_id | tr -d '\r\n')

if [ "$final_id" = "$new_id" ]; then
    echo -e ">> ${GREEN}系统 Android ID 修改成功！${NC}"
    
    # 核心步骤：强杀应用，迫使它重新读取 ID
    if [ ! -z "$package_name" ]; then
        echo -e ">> 正在重置应用状态 ($package_name)..."
        am force-stop "$package_name"
        echo -e ">> ${GREEN}应用已停止，请手动重新打开应用即可生效。${NC}"
    fi
else
    echo -e ">> ${RED}修改失败！请检查 Root 权限或系统限制。${NC}"
fi

echo -e "${CYAN}#############################################${NC}"