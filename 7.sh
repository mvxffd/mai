#!/system/bin/sh
# ============================================
# Root工具箱 - 动态时间版 v3.3
# ============================================

VERSION="3.3"
DEBUG=false
LOG_FILE="/data/local/tmp/root_toolbox.log"

# ---------- 颜色定义 ----------
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
CYAN='\033[36m'
WHITE='\033[37m'
BOLD_RED='\033[1;31m'
BOLD_GREEN='\033[1;32m'
BOLD_YELLOW='\033[1;33m'
BOLD_CYAN='\033[1;36m'
BOLD_BLUE='\033[1;34m'
BOLD_WHITE='\033[1;37m'
RESET='\033[0m'
SEP='============================================================='

# ---------- 日志函数 ----------
log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    mkdir -p /data/local/tmp 2>/dev/null
    echo "$msg" >> "$LOG_FILE" 2>/dev/null
    [ "$DEBUG" = true ] && echo "${YELLOW}[DEBUG] $*${RESET}" >&2
}

error_log() {
    local msg="[ERROR] $*"
    log "$msg"
    echo "${RED}❌ $*${RESET}" >&2
}

success_log() {
    local msg="[SUCCESS] $*"
    log "$msg"
    echo "${GREEN}✅ $*${RESET}"
}

info_log() {
    local msg="[INFO] $*"
    log "$msg"
    echo "${CYAN}ℹ️  $*${RESET}"
}

# ---------- 权限校验 ----------
check_root() {
    local uid=$(id -u 2>/dev/null || echo 9999)
    if [ "$uid" -ne 0 ]; then
        echo "${BOLD_GREEN}${SEP}${RESET}"
        echo "${RED}            权限校验失败${RESET}"
        echo "${RED}  本脚本必须使用root权限运行！${RESET}"
        echo "${RED}   没有root权限，你活着干哈 ${RESET}"
        echo "${BOLD_GREEN}${SEP}${RESET}"
        log "权限校验失败，非root用户"
        exit 1
    fi
    log "权限校验通过"
}

# ---------- 通用工具函数 ----------
# 安全执行命令
safe_exec() {
    local cmd="$1"
    local error_msg="${2:-命令执行失败}"
    
    eval "$cmd" 2>/dev/null
    if [ $? -eq 0 ]; then
        return 0
    else
        error_log "$error_msg"
        return 1
    fi
}

# 安全启动应用
start_app() {
    local pkg="$1"
    local act="${2:-}"
    local result=0
    
    # 检查应用是否安装
    pm list packages 2>/dev/null | grep -q "$pkg"
    if [ $? -ne 0 ]; then
        error_log "应用 $pkg 未安装"
        return 1
    fi
    
    if [ -n "$act" ]; then
        am start -n "${pkg}/${act}" >/dev/null 2>&1
        result=$?
    else
        am start -a android.intent.action.MAIN -c android.intent.category.LAUNCHER "${pkg}" >/dev/null 2>&1
        result=$?
    fi
    
    if [ $result -eq 0 ]; then
        success_log "已启动 $pkg"
        return 0
    else
        error_log "启动失败 $pkg"
        return 1
    fi
}

# 按任意键返回
wait_return() {
    echo "${GREEN}按回车返回主菜单...${RESET}"
    read tmp 2>/dev/null
    # 清除缓冲区
    clear
}

# 安全读取属性
get_prop() {
    local prop="$1"
    local default="${2:-}"
    local val
    
    val=$(getprop "$prop" 2>/dev/null)
    if [ -z "$val" ]; then
        val="$default"
    fi
    echo "$val"
}

# 格式化文件大小
format_size() {
    local size="$1"
    case "$size" in
        ''|*[!0-9]*) echo "未知大小"; return ;;
    esac
    
    if [ "$size" -ge 1048576 ]; then
        echo "$((size / 1048576)) MB"
    elif [ "$size" -ge 1024 ]; then
        echo "$((size / 1024)) KB"
    else
        echo "${size} B"
    fi
}

# ---------- 主菜单（动态时间版）----------
show_menu() {
    clear
    echo "${BOLD_CYAN}${SEP}${RESET}"
    echo "${RED}                Root 工具箱 v${VERSION}${RESET}"
    # 🔄 动态时间：每次显示菜单时获取最新时间
    echo "${BOLD_WHITE}                $(date '+%Y-%m-%d %H:%M:%S')${RESET}"
    echo ""
    echo "${GREEN} 1 欧美大片专区${RESET}          ${CYAN} 6 设备信息${RESET}"
    echo "${YELLOW} 2 Scene${RESET}                 ${GREEN} 7 批量复制PNG${RESET}"
    echo "${BLUE} 3 系统设置${RESET}               ${MAGENTA} 8 清理缓存${RESET}"
    echo "${MAGENTA} 4 微信${RESET}"
    echo "${BOLD_RED} 5 退出脚本${RESET}"
    echo "${BOLD_CYAN}${SEP}${RESET}"
    echo -n "${CYAN}请输入选项后按回车: ${RESET}"
}

# ---------- 功能函数 ----------

# 功能1：欧美大片专区
menu_europe() {
    local PACKAGE="com.oplus.camera"
    local DIR="/storage/emulated/0/欧美链接在这"
    local SRC_DIR="/storage/emulated/0/Pictures"
    local TXT_PATH="${DIR}/欧美链接在这.txt"
    local TXT_CONTENT="https://t.me/cnxvlog ← 先开VPN，再用浏览器打开"
    
    info_log "启动欧美大片专区"
    info_log "提示：若功能无效果，请先执行 su setenforce 0"
    
    # 检查相机应用
    pm list packages 2>/dev/null | grep -q "$PACKAGE"
    if [ $? -ne 0 ]; then
        error_log "相机应用 $PACKAGE 未安装"
        wait_return
        return 1
    fi
    
    echo "${GREEN}🎬 有惊喜 😁😁${RESET}"
    
    # 启动前置相机拍照（两次）
    i=1
    while [ $i -le 2 ]; do
        am start -n "${PACKAGE}/.Camera" --ei android.intent.extras.CAMERA_FACING 1 >/dev/null 2>&1
        sleep 1
        input keyevent 25
        sleep 1
        i=$((i + 1))
    done
    
    # 创建txt文件
    mkdir -p "$DIR" 2>/dev/null
    if [ ! -f "$TXT_PATH" ]; then
        echo "$TXT_CONTENT" > "$TXT_PATH"
        echo "${GREEN}✓ 已创建: ${TXT_PATH}${RESET}"
    else
        echo "${YELLOW}文件已存在: ${TXT_PATH}${RESET}"
    fi
    echo "${BLUE}📁 固定目录: ${DIR}${RESET}"
    
    wait_return
}

# 功能6：设备系统信息
menu_device_info() {
    info_log "查看设备信息"
    echo "${BOLD_BLUE}==================== 设备系统信息 ====================${RESET}"
    # 🔄 动态时间
    echo "${CYAN}当前时间: $(date '+%Y-%m-%d %H:%M:%S')${RESET}"
    echo ""
    
    echo "${CYAN}【内核版本】${RESET}"
    uname -a 2>/dev/null || echo "读取失败"
    
    echo "${CYAN}【设备硬件型号】${RESET}"
    echo "$(get_prop ro.product.model "未知")"
    
    echo "${CYAN}【制造商】${RESET}"
    echo "$(get_prop ro.product.manufacturer "未知")"
    
    echo "${CYAN}【Android版本】${RESET}"
    echo "$(get_prop ro.build.version.release "未知")"
    
    api_level=$(get_prop ro.build.version.sdk)
    [ -n "$api_level" ] && echo "API级别：$api_level"
    
    patch_date=$(get_prop ro.build.version.security_patch)
    [ -n "$patch_date" ] && echo "安全补丁：$patch_date"
    
    echo "${CYAN}【处理器】${RESET}"
    cpu_info=$(cat /proc/cpuinfo 2>/dev/null | grep -E "Hardware|Processor" | head -1 | cut -d: -f2 | sed 's/^[ \t]*//')
    if [ -n "$cpu_info" ]; then
        echo "$cpu_info"
    else
        echo "未识别处理器"
    fi
    
    echo "${CYAN}【CPU核心】${RESET}"
    cpu_cores=$(grep -c "^processor" /proc/cpuinfo 2>/dev/null)
    echo "核心数: ${cpu_cores:-未知}"
    
    echo "${CYAN}【内存信息】${RESET}"
    free -m 2>/dev/null | grep Mem | while read line; do
        total=$(echo $line | awk '{print $2}')
        used=$(echo $line | awk '{print $3}')
        if [ -n "$total" ]; then
            echo "总内存: ${total} MB"
            echo "已用内存: ${used} MB"
        fi
    done
    
    echo "${BOLD_BLUE}======================================================${RESET}"
    wait_return
}

# 功能7：批量复制PNG
menu_png_batch() {
    local SRC_DIR="/storage/emulated/0/1"
    local TARGET_DIR="/storage/emulated/0/2"
    local PNG_FOUND=""
    local NAME_LIST="0y 1S 5Q 7c _e C9 CG D2 Et jy kb Mb SD tf u3"
    local total_count=15
    local copy_success=0
    local copy_failed=0
    
    clear
    echo "${BOLD_BLUE}===== PNG批量复制工具 v2.0 =====${RESET}"
    info_log "启动PNG批量复制"
    info_log "提示：复制失败请先执行 su setenforce 0"
    
    # 源目录检查
    if [ ! -d "$SRC_DIR" ]; then
        error_log "源目录不存在: $SRC_DIR"
        echo "${YELLOW}💡 请手动在手机根目录创建文件夹 1 并放入PNG图片${RESET}"
        wait_return
        return 1
    fi
    
    # 查找PNG文件
    info_log "扫描源目录: $SRC_DIR"
    echo "${CYAN}🔍 正在扫描源目录...${RESET}"
    
    PNG_FOUND=$(find "$SRC_DIR" -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.PNG" \) 2>/dev/null | head -n1)
    
    if [ -z "$PNG_FOUND" ]; then
        echo "${YELLOW}⚠️  当前目录未找到PNG，尝试递归搜索子目录...${RESET}"
        PNG_FOUND=$(find "$SRC_DIR" -maxdepth 2 -type f \( -iname "*.png" -o -iname "*.PNG" \) 2>/dev/null | head -n1)
    fi
    
    if [ -z "$PNG_FOUND" ]; then
        error_log "未找到PNG图片"
        echo "${RED}【错误】$SRC_DIR 及其子目录内未找到PNG图片！${RESET}"
        echo "${YELLOW}💡 支持的格式: .png .PNG${RESET}"
        wait_return
        return 1
    fi
    
    # 显示文件信息
    local FILE_SIZE=""
    if stat -c%s "$PNG_FOUND" >/dev/null 2>&1; then
        FILE_SIZE=$(stat -c%s "$PNG_FOUND")
    elif stat -f%z "$PNG_FOUND" >/dev/null 2>&1; then
        FILE_SIZE=$(stat -f%z "$PNG_FOUND")
    fi
    local FILE_NAME=$(basename "$PNG_FOUND")
    local FILE_PATH=$(dirname "$PNG_FOUND")
    
    echo "${GREEN}✅ 找到图片: $FILE_NAME${RESET}"
    echo "${CYAN}📁 源路径: $FILE_PATH${RESET}"
    [ -n "$FILE_SIZE" ] && echo "${CYAN}📦 文件大小: $(format_size "$FILE_SIZE")${RESET}"
    echo "${YELLOW}📂 目标目录: $TARGET_DIR${RESET}"
    echo ""
    
    # 目标目录检查
    if [ -d "$TARGET_DIR" ]; then
        existing_count=$(find "$TARGET_DIR" -maxdepth 1 -type f -iname "*.png" 2>/dev/null | wc -l)
        echo "${YELLOW}⚠️  目标目录已有 $existing_count 个PNG文件${RESET}"
    fi
    
    # 确认操作
    echo "${YELLOW}即将复制 $total_count 个文件:${RESET}"
    echo -n "   "
    cols=0
    for name in $NAME_LIST; do
        echo -n "${name}.png  "
        cols=$((cols + 1))
        if [ $cols -eq 5 ]; then
            echo ""
            echo -n "   "
            cols=0
        fi
    done
    echo ""
    echo ""
    echo -n "${CYAN}确认执行? [y/N]: ${RESET}"
    read confirm
    echo ""
    
    case "$confirm" in
        y|Y)
            # 执行复制
            info_log "开始复制PNG文件"
            echo "${CYAN}⏳ 正在复制...${RESET}"
            
            mkdir -p "$TARGET_DIR" 2>/dev/null
            
            for name in $NAME_LIST; do
                target="${TARGET_DIR}/${name}.png"
                
                # 检查目标是否已存在
                if [ -f "$target" ]; then
                    backup="${TARGET_DIR}/${name}_backup_$(date +%s).png"
                    mv "$target" "$backup" 2>/dev/null
                    echo "${YELLOW}⚠️  已备份: ${name}.png${RESET}"
                fi
                
                # 复制文件
                cp "$PNG_FOUND" "$target" 2>/dev/null
                if [ $? -eq 0 ]; then
                    echo "${GREEN}✅ ${name}.png${RESET}"
                    copy_success=$((copy_success + 1))
                else
                    echo "${RED}❌ ${name}.png (复制失败)${RESET}"
                    copy_failed=$((copy_failed + 1))
                fi
            done
            
            echo ""
            echo "${GREEN}📊 复制完成: 成功 $copy_success 个，失败 $copy_failed 个${RESET}"
            ;;
        *)
            echo "${YELLOW}已取消操作${RESET}"
            ;;
    esac
    
    wait_return
}

# 功能8：清理缓存
menu_clean_cache() {
    clear
    echo "${BOLD_BLUE}===== 缓存清理工具 =====${RESET}"
    info_log "启动缓存清理"
    
    echo "${CYAN}正在计算缓存大小...${RESET}"
    
    total_size=0
    for dir in /data/data/*/cache /data/data/*/code_cache /storage/emulated/0/Android/data/*/cache; do
        if [ -d "$dir" ]; then
            size=$(du -s "$dir" 2>/dev/null | cut -f1)
            case "$size" in
                ''|*[!0-9]*) ;;
                *) total_size=$((total_size + size)) ;;
            esac
        fi
    done
    
    total_size_mb=$((total_size / 1024))
    echo "${CYAN}📦 缓存总大小: ${total_size_mb} MB${RESET}"
    
    echo -n "${CYAN}确认清理? [y/N]: ${RESET}"
    read confirm
    echo ""
    
    case "$confirm" in
        y|Y)
            echo "${YELLOW}⏳ 正在清理缓存...${RESET}"
            
            for dir in /data/data/*/cache /data/data/*/code_cache /storage/emulated/0/Android/data/*/cache; do
                if [ -d "$dir" ]; then
                    rm -rf "$dir"/* 2>/dev/null
                fi
            done
            
            success_log "缓存清理完成"
            ;;
        *)
            echo "${YELLOW}已取消操作${RESET}"
            ;;
    esac
    
    wait_return
}

# ---------- 主程序入口 ----------
main() {
    # 设置信号处理
    trap 'echo "\n${YELLOW}脚本被中断${RESET}"; exit 1' INT TERM
    
    # 权限检查
    check_root
    
    # 记录启动日志
    log "========== Root工具箱 v$VERSION 启动 =========="
    
    # 主循环
    while true; do
        show_menu
        read -t 1 key 2>/dev/null  # 每秒超时，实现自动刷新
        local exit_code=$?
        
        # 如果超时（无输入），继续循环刷新
        if [ $exit_code -eq 142 ] || [ $exit_code -eq 1 ]; then
            continue
        fi
        
        echo ""
        
        case "$key" in
            1) menu_europe ;;
            2) start_app "com.omarea.vtools" && wait_return ;;
            3) start_app "com.android.settings" && wait_return ;;
            4) start_app "com.tencent.mm" ".ui.LauncherUI" && wait_return ;;
            5)
                echo "${GREEN}正在退出脚本...${RESET}"
                log "脚本正常退出"
                exit 0
                ;;
            6) menu_device_info ;;
            7) menu_png_batch ;;
            8) menu_clean_cache ;;
            *)
                if [ -n "$key" ]; then
                    echo "${RED}输入错误，请重新选择！${RESET}"
                    sleep 1
                fi
                ;;
        esac
    done
}

# 启动主程序
main "$@"