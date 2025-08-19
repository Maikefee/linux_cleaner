#!/bin/bash

# Linux 入侵痕迹清理工具 (Bash版本)
# Linux Intrusion Cleaner (Bash Version)

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
    echo -e "${BLUE}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                Linux 入侵痕迹清理工具 (Bash版)                ║
║              Linux Intrusion Cleaner (Bash Version)          ║
║                                                              ║
║  功能: 清除历史记录 | 系统日志 | Web日志 | 文件安全删除        ║
║  Features: History | System Logs | Web Logs | Secure Delete  ║
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

# 清除历史命令记录
clear_history() {
    print_info "正在清除历史命令记录..."
    
    # 清除当前会话历史
    history -c 2>/dev/null && print_success "已清除当前会话历史记录"
    
    # 清空.bash_history文件
    if [[ -f "$HOME_DIR/.bash_history" ]]; then
        modify_file_timestamp "$HOME_DIR/.bash_history"
        > "$HOME_DIR/.bash_history" && print_success "已清空 .bash_history 文件"
    fi
    
    # 设置环境变量不记录历史
    export HISTFILE=/dev/null
    export HISTSIZE=0
    export HISTFILESIZE=0
    export HISTCONTROL=ignorespace:ignoredups:erasedups
    print_success "已设置环境变量不记录历史"
    
    # 清除其他shell历史文件
    local history_files=(".zsh_history" ".bash_sessions" ".python_history" ".node_repl_history" ".mysql_history" ".sqlite_history" ".psql_history" ".lesshst" ".viminfo" ".vim_history" ".nano_history")
    
    for hist_file in "${history_files[@]}"; do
        local file_path="$HOME_DIR/$hist_file"
        if [[ -f "$file_path" ]]; then
            modify_file_timestamp "$file_path"
            rm -f "$file_path" && print_success "已删除 $hist_file"
        fi
    done
    
    # 清理shell配置文件中的历史设置
    local shell_configs=(".bashrc" ".bash_profile" ".zshrc" ".profile")
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
EOF
                print_success "已修改 $config 禁用历史记录"
            fi
        fi
    done
}

# 清除系统日志痕迹
clear_system_logs() {
    print_info "正在清除系统日志痕迹..."
    
    if ! check_root; then
        print_error "需要root权限才能清除系统日志"
        return 1
    fi
    
    # 系统日志文件列表
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
    )
    
    for log_file in "${!log_files[@]}"; do
        if [[ -f "$log_file" ]]; then
            modify_file_timestamp "$log_file"
            > "$log_file" && print_success "已清空 ${log_files[$log_file]} ($log_file)"
        fi
    done
    
    # 清理journalctl日志
    if command_exists journalctl; then
        journalctl --vacuum-time=1s >/dev/null 2>&1 && print_success "已清除journalctl日志"
        journalctl --vacuum-size=1K >/dev/null 2>&1
        journalctl --rotate >/dev/null 2>&1
    fi
    
    # 清理其他日志目录
    local log_dirs=("/var/log/audit" "/var/log/apache2" "/var/log/nginx" "/var/log/lighttpd" "/var/log/httpd" "/var/log/squid" "/var/log/mail" "/var/log/news" "/var/log/debug")
    
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

# 清除Web入侵痕迹
clear_web_logs() {
    print_info "正在清除Web入侵痕迹..."
    
    # 获取当前IP地址
    get_current_ip
    
    # Web日志文件列表
    local web_log_files=(
        "/var/log/nginx/access.log"
        "/var/log/nginx/error.log"
        "/var/log/apache2/access.log"
        "/var/log/apache2/error.log"
        "/var/log/httpd/access_log"
        "/var/log/httpd/error_log"
        "/var/log/lighttpd/access.log"
        "/var/log/lighttpd/error.log"
        "/var/log/squid/access.log"
        "/var/log/squid/cache.log"
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
            local keywords=("evil" "hack" "exploit" "backdoor" "shell")
            for keyword in "${keywords[@]}"; do
                sed -i "/$keyword/d" "$log_file" 2>/dev/null
            done
            
            # 清空日志文件
            > "$log_file" && print_success "已清空并清理关键词: $log_file"
        fi
    done
}

# 安全删除文件
secure_delete_file() {
    local file_path="$1"
    
    if [[ ! -f "$file_path" ]]; then
        print_error "文件不存在: $file_path"
        return 1
    fi
    
    print_info "正在安全删除文件: $file_path"
    
    # 修改文件时间戳
    modify_file_timestamp "$file_path"
    
    # 方法1: 使用shred命令
    if command_exists shred; then
        if shred -f -u -z -v -n 8 "$file_path" 2>/dev/null; then
            print_success "已使用shred安全删除: $file_path"
            return 0
        fi
    fi
    
    # 方法2: 使用dd命令覆盖
    if command_exists dd; then
        local file_size=$(stat -c%s "$file_path" 2>/dev/null || echo "0")
        if [[ $file_size -gt 0 ]]; then
            # 多次覆盖
            for i in {1..3}; do
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

# 安全删除目录
secure_delete_directory() {
    local dir_path="$1"
    
    if [[ ! -d "$dir_path" ]]; then
        print_error "目录不存在: $dir_path"
        return 1
    fi
    
    print_info "正在安全删除目录: $dir_path"
    
    # 先删除目录中的所有文件
    find "$dir_path" -type f -exec sh -c 'secure_delete_file "$1"' sh {} \; 2>/dev/null
    
    # 删除空目录
    rm -rf "$dir_path" && print_success "已安全删除目录: $dir_path"
}

# 隐藏SSH登录痕迹
hide_ssh_traces() {
    print_info "正在隐藏SSH登录痕迹..."
    
    # 清除SSH相关日志
    local ssh_logs=("/var/log/auth.log" "/var/log/secure" "/var/log/btmp" "/var/log/wtmp")
    
    for log_file in "${ssh_logs[@]}"; do
        if [[ -f "$log_file" ]]; then
            modify_file_timestamp "$log_file"
            > "$log_file" && print_success "已清空SSH日志: $log_file"
        fi
    done
    
    # 清除SSH密钥
    local ssh_dir="$HOME_DIR/.ssh"
    if [[ -d "$ssh_dir" ]]; then
        print_warning "检测到SSH目录，建议手动检查并删除相关密钥"
    fi
}

# 清理内存痕迹
clean_memory() {
    print_info "正在清理内存痕迹..."
    
    if ! check_root; then
        print_error "需要root权限才能清理内存"
        return 1
    fi
    
    # 清理内存缓存
    sync
    echo 3 > /proc/sys/vm/drop_caches 2>/dev/null && print_success "已清理内存缓存"
    
    # 清理swap
    swapoff -a && swapon -a 2>/dev/null && print_success "已清理swap分区"
}

# 显示主菜单
show_menu() {
    echo -e "${BLUE}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                        主菜单 / Main Menu                      ║
╠══════════════════════════════════════════════════════════════╣
║  1. 清除历史命令记录 (Clear History Commands)                  ║
║  2. 清除系统日志痕迹 (Clear System Logs)                       ║
║  3. 清除Web入侵痕迹 (Clear Web Logs)                          ║
║  4. 安全删除文件 (Secure Delete File)                         ║
║  5. 安全删除目录 (Secure Delete Directory)                    ║
║  6. 隐藏SSH登录痕迹 (Hide SSH Traces)                         ║
║  7. 清理内存痕迹 (Clean Memory)                               ║
║  8. 一键清理所有痕迹 (Clean All Traces)                       ║
║  9. 退出 (Exit)                                               ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# 交互式模式
interactive_mode() {
    while true; do
        show_menu
        echo -n "请选择操作 (1-9): "
        read -r choice
        
        case $choice in
            1)
                clear_history
                ;;
            2)
                clear_system_logs
                ;;
            3)
                clear_web_logs
                ;;
            4)
                echo -n "请输入要删除的文件路径: "
                read -r file_path
                if [[ -n "$file_path" ]]; then
                    secure_delete_file "$file_path"
                fi
                ;;
            5)
                echo -n "请输入要删除的目录路径: "
                read -r dir_path
                if [[ -n "$dir_path" ]]; then
                    secure_delete_directory "$dir_path"
                fi
                ;;
            6)
                hide_ssh_traces
                ;;
            7)
                clean_memory
                ;;
            8)
                print_info "开始一键清理所有痕迹..."
                clear_history
                clear_system_logs
                clear_web_logs
                hide_ssh_traces
                clean_memory
                print_success "一键清理完成!"
                ;;
            9)
                echo -e "\n${GREEN}👋 再见! Goodbye!${NC}"
                exit 0
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

# 自动清理模式
auto_clean() {
    print_info "开始自动清理所有痕迹..."
    local start_time=$(date +%s)
    
    clear_history
    clear_system_logs
    clear_web_logs
    hide_ssh_traces
    clean_memory
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    print_success "自动清理完成! 耗时: ${duration} 秒"
    print_warning "建议重启系统以确保所有痕迹被完全清除"
}

# 显示帮助
show_help() {
    cat << "EOF"
Linux 入侵痕迹清理工具 (Bash版本)

使用方法:
  ./linux_cleaner.sh          # 交互式模式
  ./linux_cleaner.sh --auto   # 自动清理模式
  ./linux_cleaner.sh --help   # 显示帮助

功能特性:
  - 清除历史命令记录
  - 清除系统日志痕迹
  - 清除Web入侵痕迹
  - 文件安全删除
  - 隐藏SSH登录痕迹
  - 清理内存痕迹
  - 时间戳修改
  - IP地址替换

注意事项:
  - 某些操作需要root权限
  - 请确保在合法环境下使用
  - 建议在测试环境中先验证功能
EOF
}

# 主函数
main() {
    # 检查参数
    case "${1:-}" in
        --auto)
            AUTO_MODE=true
            print_banner
            auto_clean
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        "")
            print_banner
            interactive_mode
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
