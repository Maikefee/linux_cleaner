#!/bin/bash

# Linux 入侵痕迹清理工具安装脚本
# Linux Intrusion Cleaner Installation Script

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印横幅
print_banner() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                Linux 入侵痕迹清理工具安装程序                  ║"
    echo "║              Linux Intrusion Cleaner Installer                ║"
    echo "║                                                              ║"
    echo "║  功能: 自动安装依赖 | 配置环境 | 权限设置 | 工具验证          ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
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
        print_warning "检测到root权限，某些操作可能需要普通用户权限"
        return 1
    fi
    return 0
}

# 检测操作系统
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    elif [[ -f /etc/lsb-release ]]; then
        . /etc/lsb-release
        OS=$DISTRIB_ID
        VER=$DISTRIB_RELEASE
    elif [[ -f /etc/debian_version ]]; then
        OS=Debian
        VER=$(cat /etc/debian_version)
    elif [[ -f /etc/SuSe-release ]]; then
        OS=SuSE
    elif [[ -f /etc/redhat-release ]]; then
        OS=RedHat
    else
        OS=$(uname -s)
        VER=$(uname -r)
    fi
    
    print_info "检测到操作系统: $OS $VER"
    echo $OS
}

# 安装Python依赖
install_python_deps() {
    print_info "检查Python环境..."
    
    # 检查Python版本
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
        print_success "Python3 已安装: $PYTHON_VERSION"
    else
        print_error "Python3 未安装，请先安装Python3"
        exit 1
    fi
    
    # 检查pip
    if command -v pip3 &> /dev/null; then
        print_success "pip3 已安装"
    else
        print_warning "pip3 未安装，尝试安装..."
        if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
            sudo apt-get update && sudo apt-get install -y python3-pip
        elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"RedHat"* ]]; then
            sudo yum install -y python3-pip
        fi
    fi
    
    # 安装Python包
    print_info "安装Python依赖包..."
    pip3 install --user subprocess.run
}

# 安装系统工具 (Ubuntu/Debian)
install_debian_tools() {
    print_info "安装Debian/Ubuntu系统工具..."
    
    sudo apt-get update
    
    # 基础工具
    sudo apt-get install -y \
        curl \
        wget \
        sed \
        grep \
        awk \
        shred \
        dd \
        touch \
        find \
        netstat \
        ss \
        lsof
    
    # 安全删除工具
    if command -v wipe &> /dev/null; then
        print_success "wipe 已安装"
    else
        print_info "安装 wipe..."
        sudo apt-get install -y wipe
    fi
    
    if command -v srm &> /dev/null; then
        print_success "srm 已安装"
    else
        print_info "安装 secure-delete..."
        sudo apt-get install -y secure-delete
    fi
    
    # 网络工具
    sudo apt-get install -y \
        net-tools \
        iproute2 \
        iptables
    
    # 系统监控工具
    sudo apt-get install -y \
        procps \
        sysstat \
        dmesg
}

# 安装系统工具 (CentOS/RHEL)
install_redhat_tools() {
    print_info "安装CentOS/RHEL系统工具..."
    
    sudo yum update -y
    
    # 基础工具
    sudo yum install -y \
        curl \
        wget \
        sed \
        grep \
        awk \
        coreutils \
        findutils \
        net-tools \
        iproute \
        iptables
    
    # 安全删除工具
    if command -v wipe &> /dev/null; then
        print_success "wipe 已安装"
    else
        print_info "安装 wipe..."
        sudo yum install -y wipe
    fi
    
    if command -v srm &> /dev/null; then
        print_success "srm 已安装"
    else
        print_info "安装 secure-delete..."
        sudo yum install -y secure-delete
    fi
    
    # 网络工具
    sudo yum install -y \
        net-tools \
        iproute \
        iptables
    
    # 系统监控工具
    sudo yum install -y \
        procps-ng \
        sysstat \
        util-linux
}

# 安装系统工具 (通用)
install_generic_tools() {
    print_info "安装通用系统工具..."
    
    # 检查并安装基础工具
    tools=("curl" "wget" "sed" "grep" "awk" "shred" "dd" "touch" "find")
    
    for tool in "${tools[@]}"; do
        if command -v $tool &> /dev/null; then
            print_success "$tool 已安装"
        else
            print_warning "$tool 未安装，请手动安装"
        fi
    done
    
    # 检查安全删除工具
    if command -v wipe &> /dev/null; then
        print_success "wipe 已安装"
    else
        print_warning "wipe 未安装，建议安装以提高安全性"
    fi
    
    if command -v srm &> /dev/null; then
        print_success "srm 已安装"
    else
        print_warning "srm 未安装，建议安装以提高安全性"
    fi
}

# 设置文件权限
setup_permissions() {
    print_info "设置文件权限..."
    
    # 设置Python脚本可执行权限
    chmod +x linux_cleaner.py
    chmod +x advanced_cleaner.py
    
    print_success "已设置脚本执行权限"
}

# 创建快捷命令
create_aliases() {
    print_info "创建快捷命令..."
    
    # 检测shell类型
    if [[ "$SHELL" == *"bash"* ]]; then
        RC_FILE="$HOME/.bashrc"
    elif [[ "$SHELL" == *"zsh"* ]]; then
        RC_FILE="$HOME/.zshrc"
    else
        RC_FILE="$HOME/.profile"
    fi
    
    # 获取当前目录
    CURRENT_DIR=$(pwd)
    
    # 添加别名
    ALIASES=(
        "alias linux-cleaner='python3 $CURRENT_DIR/linux_cleaner.py'"
        "alias advanced-cleaner='python3 $CURRENT_DIR/advanced_cleaner.py'"
        "alias lc='python3 $CURRENT_DIR/linux_cleaner.py'"
        "alias ac='python3 $CURRENT_DIR/advanced_cleaner.py'"
    )
    
    for alias in "${ALIASES[@]}"; do
        if ! grep -q "$alias" "$RC_FILE" 2>/dev/null; then
            echo "$alias" >> "$RC_FILE"
            print_success "已添加别名: $alias"
        else
            print_info "别名已存在: $alias"
        fi
    done
    
    print_info "请运行 'source $RC_FILE' 或重新登录以启用别名"
}

# 验证安装
verify_installation() {
    print_info "验证安装..."
    
    # 检查Python脚本
    if [[ -f "linux_cleaner.py" ]]; then
        print_success "linux_cleaner.py 存在"
    else
        print_error "linux_cleaner.py 不存在"
        return 1
    fi
    
    if [[ -f "advanced_cleaner.py" ]]; then
        print_success "advanced_cleaner.py 存在"
    else
        print_error "advanced_cleaner.py 不存在"
        return 1
    fi
    
    # 测试Python脚本
    print_info "测试Python脚本..."
    if python3 -c "import subprocess, os, sys, time, shutil" 2>/dev/null; then
        print_success "Python依赖检查通过"
    else
        print_error "Python依赖检查失败"
        return 1
    fi
    
    # 测试系统命令
    print_info "测试系统命令..."
    commands=("shred" "dd" "sed" "grep" "curl")
    
    for cmd in "${commands[@]}"; do
        if command -v $cmd &> /dev/null; then
            print_success "$cmd 可用"
        else
            print_warning "$cmd 不可用"
        fi
    done
    
    print_success "安装验证完成"
}

# 显示使用说明
show_usage() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                        使用说明                                ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo "║  基础版本:                                                    ║"
    echo "║    python3 linux_cleaner.py                                  ║"
    echo "║    linux-cleaner                                             ║"
    echo "║    lc                                                        ║"
    echo "║                                                              ║"
    echo "║  高级版本:                                                    ║"
    echo "║    python3 advanced_cleaner.py                               ║"
    echo "║    advanced-cleaner                                          ║"
    echo "║    ac                                                        ║"
    echo "║                                                              ║"
    echo "║  自动模式:                                                    ║"
    echo "║    python3 linux_cleaner.py --auto                          ║"
    echo "║    python3 advanced_cleaner.py --auto                       ║"
    echo "║                                                              ║"
    echo "║  帮助信息:                                                    ║"
    echo "║    python3 linux_cleaner.py --help                          ║"
    echo "║    python3 advanced_cleaner.py --help                       ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# 显示安全警告
show_security_warning() {
    echo -e "${YELLOW}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                        安全警告                                ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo "║  ⚠️  本工具仅用于教育和研究目的                              ║"
    echo "║  ⚠️  请勿用于非法活动                                        ║"
    echo "║  ⚠️  使用者需自行承担使用风险                                ║"
    echo "║  ⚠️  某些操作需要root权限                                    ║"
    echo "║  ⚠️  建议在测试环境中先验证功能                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# 主安装函数
main() {
    print_banner
    show_security_warning
    
    # 检查root权限
    check_root
    
    # 检测操作系统
    OS=$(detect_os)
    
    # 安装Python依赖
    install_python_deps
    
    # 根据操作系统安装系统工具
    if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        install_debian_tools
    elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"RedHat"* ]] || [[ "$OS" == *"Fedora"* ]]; then
        install_redhat_tools
    else
        install_generic_tools
    fi
    
    # 设置权限
    setup_permissions
    
    # 创建别名
    create_aliases
    
    # 验证安装
    verify_installation
    
    print_success "安装完成!"
    show_usage
    
    echo -e "${GREEN}"
    echo "下一步:"
    echo "1. 运行 'source ~/.bashrc' 或重新登录以启用别名"
    echo "2. 使用 'linux-cleaner' 或 'advanced-cleaner' 启动工具"
    echo "3. 阅读 README.md 了解详细使用方法"
    echo -e "${NC}"
}

# 运行主函数
main "$@"
