#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Linux 高级入侵痕迹清理工具
增强版 - 包含更多高级清理功能
"""

import os
import sys
import subprocess
import time
import shutil
import random
import string
from datetime import datetime, timedelta

class AdvancedLinuxCleaner:
    def __init__(self):
        self.current_user = os.getenv('USER')
        self.home_dir = os.path.expanduser('~')
        self.fake_ips = [
            '192.168.1.1', '192.168.1.100', '10.0.0.1', 
            '172.16.0.1', '8.8.8.8', '1.1.1.1'
        ]
        
    def print_banner(self):
        """打印工具横幅"""
        banner = """
╔══════════════════════════════════════════════════════════════╗
║                Linux 高级入侵痕迹清理工具                      ║
║              Advanced Linux Intrusion Cleaner                 ║
║                                                              ║
║  功能: 历史记录 | 系统日志 | Web日志 | 文件删除 | 时间戳修改   ║
║  高级: 进程隐藏 | 网络痕迹 | 内核痕迹 | 内存清理 | 反取证     ║
╚══════════════════════════════════════════════════════════════╝
        """
        print(banner)
    
    def run_command(self, command, shell=True, silent=False):
        """执行系统命令"""
        try:
            if silent:
                result = subprocess.run(command, shell=shell, capture_output=True, text=True)
            else:
                result = subprocess.run(command, shell=shell, capture_output=True, text=True)
            return result.returncode == 0, result.stdout, result.stderr
        except Exception as e:
            return False, "", str(e)
    
    def check_root(self):
        """检查是否为root用户"""
        if os.geteuid() != 0:
            print("⚠️  警告: 某些操作需要root权限才能执行")
            return False
        return True
    
    def generate_fake_timestamp(self):
        """生成虚假时间戳"""
        # 生成过去30天内的随机时间
        days_ago = random.randint(1, 30)
        hours_ago = random.randint(1, 24)
        minutes_ago = random.randint(1, 60)
        
        fake_time = datetime.now() - timedelta(days=days_ago, hours=hours_ago, minutes=minutes_ago)
        return fake_time.strftime("%Y%m%d%H%M")
    
    def modify_file_timestamps(self, file_path):
        """修改文件时间戳"""
        if not os.path.exists(file_path):
            return False
        
        try:
            fake_timestamp = self.generate_fake_timestamp()
            success, _, _ = self.run_command(f"touch -t {fake_timestamp} {file_path}")
            if success:
                print(f"✅ 已修改文件时间戳: {file_path}")
                return True
        except Exception as e:
            print(f"❌ 修改时间戳失败: {e}")
        return False
    
    def clear_history_advanced(self):
        """高级历史记录清理"""
        print("\n🔍 正在执行高级历史记录清理...")
        
        # 基础清理
        self.run_command("history -c")
        self.run_command("history -w")
        
        # 清空所有可能的历史文件
        history_files = [
            '.bash_history', '.zsh_history', '.bash_sessions',
            '.python_history', '.node_repl_history', '.mysql_history',
            '.sqlite_history', '.psql_history', '.lesshst',
            '.viminfo', '.vim_history', '.nano_history'
        ]
        
        for hist_file in history_files:
            file_path = os.path.join(self.home_dir, hist_file)
            if os.path.exists(file_path):
                try:
                    # 修改时间戳后再删除
                    self.modify_file_timestamps(file_path)
                    os.remove(file_path)
                    print(f"✅ 已删除并修改时间戳: {hist_file}")
                except Exception as e:
                    print(f"❌ 处理 {hist_file} 失败: {e}")
        
        # 设置环境变量
        env_commands = [
            "unset HISTORY HISTFILE HISTSAVE HISTZONE HISTORY HISTLOG",
            "export HISTFILE=/dev/null",
            "export HISTSIZE=0",
            "export HISTFILESIZE=0",
            "export HISTCONTROL=ignorespace:ignoredups:erasedups"
        ]
        
        for cmd in env_commands:
            self.run_command(cmd)
        
        # 清理shell配置文件中的历史设置
        shell_configs = ['.bashrc', '.bash_profile', '.zshrc', '.profile']
        for config in shell_configs:
            config_path = os.path.join(self.home_dir, config)
            if os.path.exists(config_path):
                try:
                    # 备份原文件
                    backup_path = config_path + '.backup'
                    shutil.copy2(config_path, backup_path)
                    
                    # 读取并修改配置
                    with open(config_path, 'r') as f:
                        content = f.read()
                    
                    # 添加禁用历史的配置
                    disable_history = """
# Disable history for security
export HISTFILE=/dev/null
export HISTSIZE=0
export HISTFILESIZE=0
export HISTCONTROL=ignorespace:ignoredups:erasedups
"""
                    if disable_history not in content:
                        with open(config_path, 'a') as f:
                            f.write(disable_history)
                        print(f"✅ 已修改 {config} 禁用历史记录")
                        
                except Exception as e:
                    print(f"❌ 修改 {config} 失败: {e}")
    
    def clear_system_logs_advanced(self):
        """高级系统日志清理"""
        print("\n🔍 正在执行高级系统日志清理...")
        
        if not self.check_root():
            print("❌ 需要root权限才能清除系统日志")
            return
        
        # 扩展的日志文件列表
        log_files = {
            '/var/log/btmp': '登录失败记录',
            '/var/log/wtmp': '登录成功记录', 
            '/var/log/lastlog': '最后登录时间',
            '/var/log/utmp': '当前登录用户',
            '/var/log/secure': '安全日志',
            '/var/log/messages': '系统消息日志',
            '/var/log/auth.log': '认证日志',
            '/var/log/syslog': '系统日志',
            '/var/log/kern.log': '内核日志',
            '/var/log/dmesg': '设备消息',
            '/var/log/faillog': '失败登录日志',
            '/var/log/tallylog': '登录尝试日志',
            '/var/log/audit/audit.log': '审计日志',
            '/var/log/cron': '定时任务日志',
            '/var/log/maillog': '邮件日志',
            '/var/log/spooler': '假脱机日志'
        }
        
        for log_file, description in log_files.items():
            if os.path.exists(log_file):
                try:
                    # 修改时间戳
                    self.modify_file_timestamps(log_file)
                    
                    # 清空日志文件
                    with open(log_file, 'w') as f:
                        f.write('')
                    print(f"✅ 已清空并修改时间戳: {description} ({log_file})")
                except Exception as e:
                    print(f"❌ 处理 {log_file} 失败: {e}")
        
        # 清理journalctl日志
        journal_commands = [
            "journalctl --vacuum-time=1s",
            "journalctl --vacuum-size=1K",
            "journalctl --rotate"
        ]
        
        for cmd in journal_commands:
            success, _, _ = self.run_command(cmd)
            if success:
                print(f"✅ 已执行: {cmd}")
        
        # 清理其他日志目录
        log_dirs = [
            '/var/log/audit', '/var/log/apache2', '/var/log/nginx',
            '/var/log/lighttpd', '/var/log/httpd', '/var/log/squid',
            '/var/log/mail', '/var/log/news', '/var/log/debug'
        ]
        
        for log_dir in log_dirs:
            if os.path.exists(log_dir):
                try:
                    for file in os.listdir(log_dir):
                        if file.endswith(('.log', '.log.1', '.log.2')):
                            file_path = os.path.join(log_dir, file)
                            self.modify_file_timestamps(file_path)
                            with open(file_path, 'w') as f:
                                f.write('')
                            print(f"✅ 已清空并修改时间戳: {file_path}")
                except Exception as e:
                    print(f"❌ 处理 {log_dir} 失败: {e}")
    
    def clear_web_logs_advanced(self):
        """高级Web日志清理"""
        print("\n🔍 正在执行高级Web日志清理...")
        
        # 获取当前IP地址
        success, ip_output, _ = self.run_command("curl -s ifconfig.me")
        current_ip = ip_output.strip() if success else "unknown"
        
        # 扩展的Web日志文件列表
        web_log_files = [
            '/var/log/nginx/access.log',
            '/var/log/nginx/error.log',
            '/var/log/apache2/access.log',
            '/var/log/apache2/error.log',
            '/var/log/httpd/access_log',
            '/var/log/httpd/error_log',
            '/var/log/lighttpd/access.log',
            '/var/log/lighttpd/error.log',
            '/var/log/squid/access.log',
            '/var/log/squid/cache.log'
        ]
        
        for log_file in web_log_files:
            if os.path.exists(log_file):
                try:
                    # 修改时间戳
                    self.modify_file_timestamps(log_file)
                    
                    # 替换IP地址为随机虚假IP
                    fake_ip = random.choice(self.fake_ips)
                    self.run_command(f"sed -i 's/{current_ip}/{fake_ip}/g' {log_file}")
                    print(f"✅ 已替换IP地址为 {fake_ip} in {log_file}")
                    
                    # 删除包含特定关键词的行
                    keywords = ['evil', 'hack', 'exploit', 'backdoor', 'shell']
                    for keyword in keywords:
                        self.run_command(f"sed -i '/{keyword}/d' {log_file}")
                    
                    # 清空日志文件
                    with open(log_file, 'w') as f:
                        f.write('')
                    print(f"✅ 已清空并清理关键词: {log_file}")
                    
                except Exception as e:
                    print(f"❌ 处理 {log_file} 失败: {e}")
    
    def secure_delete_file_advanced(self, file_path):
        """高级文件安全删除"""
        if not os.path.exists(file_path):
            print(f"❌ 文件不存在: {file_path}")
            return False
        
        print(f"🔍 正在执行高级安全删除: {file_path}")
        
        # 修改文件时间戳
        self.modify_file_timestamps(file_path)
        
        # 方法1: 使用shred命令 (增强版)
        success, _, _ = self.run_command(f"shred -f -u -z -v -n 10 {file_path}")
        if success:
            print(f"✅ 已使用shred高级删除: {file_path}")
            return True
        
        # 方法2: 使用dd命令多次覆盖
        try:
            file_size = os.path.getsize(file_path)
            # 多次覆盖
            for i in range(3):
                self.run_command(f"dd if=/dev/urandom of={file_path} bs=1M count={file_size//1024//1024 + 1}")
                self.run_command(f"dd if=/dev/zero of={file_path} bs=1M count={file_size//1024//1024 + 1}")
            
            os.remove(file_path)
            print(f"✅ 已使用dd多次覆盖删除: {file_path}")
            return True
        except Exception as e:
            print(f"❌ dd删除失败: {e}")
        
        # 方法3: 使用wipe命令
        success, _, _ = self.run_command(f"wipe -f {file_path}")
        if success:
            print(f"✅ 已使用wipe删除: {file_path}")
            return True
        
        # 方法4: 使用srm命令
        success, _, _ = self.run_command(f"srm -f {file_path}")
        if success:
            print(f"✅ 已使用srm删除: {file_path}")
            return True
        
        print(f"❌ 所有安全删除方法都失败了: {file_path}")
        return False
    
    def hide_process_traces(self):
        """隐藏进程痕迹"""
        print("\n🔍 正在隐藏进程痕迹...")
        
        # 清理进程相关日志
        proc_logs = [
            '/proc/self/environ',
            '/proc/self/cmdline',
            '/proc/self/status'
        ]
        
        # 清理/proc文件系统痕迹
        success, _, _ = self.run_command("echo 1 > /proc/sys/kernel/dmesg_restrict")
        if success:
            print("✅ 已限制dmesg访问")
        
        # 清理内核消息
        success, _, _ = self.run_command("dmesg -c")
        if success:
            print("✅ 已清除内核消息")
        
        # 清理进程统计信息
        success, _, _ = self.run_command("echo 0 > /proc/sys/kernel/randomize_va_space")
        if success:
            print("✅ 已禁用地址空间随机化")
    
    def clear_network_traces(self):
        """清理网络痕迹"""
        print("\n🔍 正在清理网络痕迹...")
        
        if not self.check_root():
            print("❌ 需要root权限才能清理网络痕迹")
            return
        
        # 清理网络连接记录
        net_commands = [
            "netstat -tuln",  # 查看当前连接
            "ss -tuln",       # 查看socket状态
            "lsof -i",        # 查看网络文件
            "cat /proc/net/tcp",  # 查看TCP连接
            "cat /proc/net/udp"   # 查看UDP连接
        ]
        
        # 清理ARP缓存
        success, _, _ = self.run_command("ip neigh flush all")
        if success:
            print("✅ 已清理ARP缓存")
        
        # 清理路由缓存
        success, _, _ = self.run_command("ip route flush cache")
        if success:
            print("✅ 已清理路由缓存")
        
        # 清理网络统计
        success, _, _ = self.run_command("cat /dev/null > /proc/net/dev")
        if success:
            print("✅ 已清理网络统计")
        
        # 清理防火墙日志
        firewall_logs = [
            '/var/log/iptables.log',
            '/var/log/ufw.log',
            '/var/log/firewalld.log'
        ]
        
        for log_file in firewall_logs:
            if os.path.exists(log_file):
                try:
                    self.modify_file_timestamps(log_file)
                    with open(log_file, 'w') as f:
                        f.write('')
                    print(f"✅ 已清空防火墙日志: {log_file}")
                except Exception as e:
                    print(f"❌ 清理 {log_file} 失败: {e}")
    
    def clear_kernel_traces(self):
        """清理内核痕迹"""
        print("\n🔍 正在清理内核痕迹...")
        
        if not self.check_root():
            print("❌ 需要root权限才能清理内核痕迹")
            return
        
        # 清理内核消息
        kernel_commands = [
            "dmesg -c",
            "echo 1 > /proc/sys/kernel/dmesg_restrict",
            "echo 0 > /proc/sys/kernel/printk"
        ]
        
        for cmd in kernel_commands:
            success, _, _ = self.run_command(cmd)
            if success:
                print(f"✅ 已执行: {cmd}")
        
        # 清理内核模块
        success, modules, _ = self.run_command("lsmod")
        if success:
            suspicious_modules = ['rootkit', 'backdoor', 'hack']
            for module in suspicious_modules:
                if module in modules:
                    self.run_command(f"rmmod {module}")
                    print(f"✅ 已卸载可疑模块: {module}")
    
    def anti_forensics(self):
        """反取证技术"""
        print("\n🔍 正在执行反取证操作...")
        
        # 清理文件系统信息
        fs_commands = [
            "sync",
            "echo 3 > /proc/sys/vm/drop_caches",
            "echo 1 > /proc/sys/vm/compact_memory"
        ]
        
        for cmd in fs_commands:
            success, _, _ = self.run_command(cmd)
            if success:
                print(f"✅ 已执行: {cmd}")
        
        # 清理内存
        success, _, _ = self.run_command("swapoff -a && swapon -a")
        if success:
            print("✅ 已清理swap分区")
        
        # 清理临时文件
        temp_dirs = ['/tmp', '/var/tmp', '/dev/shm']
        for temp_dir in temp_dirs:
            if os.path.exists(temp_dir):
                try:
                    for file in os.listdir(temp_dir):
                        file_path = os.path.join(temp_dir, file)
                        if os.path.isfile(file_path):
                            self.secure_delete_file_advanced(file_path)
                except Exception as e:
                    print(f"❌ 清理 {temp_dir} 失败: {e}")
        
        # 清理系统缓存
        cache_dirs = [
            '/var/cache',
            '/var/spool',
            '/var/lib/systemd/coredump'
        ]
        
        for cache_dir in cache_dirs:
            if os.path.exists(cache_dir):
                try:
                    for root, dirs, files in os.walk(cache_dir):
                        for file in files:
                            file_path = os.path.join(root, file)
                            self.modify_file_timestamps(file_path)
                except Exception as e:
                    print(f"❌ 清理缓存 {cache_dir} 失败: {e}")
    
    def show_advanced_menu(self):
        """显示高级菜单"""
        menu = """
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
        """
        print(menu)
    
    def advanced_interactive_mode(self):
        """高级交互式模式"""
        while True:
            self.show_advanced_menu()
            try:
                choice = input("请选择操作 (1-10): ").strip()
                
                if choice == '1':
                    self.clear_history_advanced()
                elif choice == '2':
                    self.clear_system_logs_advanced()
                elif choice == '3':
                    self.clear_web_logs_advanced()
                elif choice == '4':
                    file_path = input("请输入要删除的文件路径: ").strip()
                    if file_path:
                        self.secure_delete_file_advanced(file_path)
                elif choice == '5':
                    self.hide_process_traces()
                elif choice == '6':
                    self.clear_network_traces()
                elif choice == '7':
                    self.clear_kernel_traces()
                elif choice == '8':
                    self.anti_forensics()
                elif choice == '9':
                    print("\n🚀 开始一键高级清理...")
                    self.clear_history_advanced()
                    self.clear_system_logs_advanced()
                    self.clear_web_logs_advanced()
                    self.hide_process_traces()
                    self.clear_network_traces()
                    self.clear_kernel_traces()
                    self.anti_forensics()
                    print("\n✅ 一键高级清理完成!")
                elif choice == '10':
                    break
                else:
                    print("❌ 无效选择，请重新输入")
                
                input("\n按回车键继续...")
                
            except KeyboardInterrupt:
                print("\n\n👋 用户中断，再见!")
                break
            except Exception as e:
                print(f"❌ 发生错误: {e}")
    
    def auto_advanced_clean(self):
        """自动高级清理模式"""
        print("\n🚀 开始自动高级清理所有痕迹...")
        start_time = time.time()
        
        self.clear_history_advanced()
        self.clear_system_logs_advanced()
        self.clear_web_logs_advanced()
        self.hide_process_traces()
        self.clear_network_traces()
        self.clear_kernel_traces()
        self.anti_forensics()
        
        end_time = time.time()
        duration = end_time - start_time
        
        print(f"\n✅ 自动高级清理完成! 耗时: {duration:.2f} 秒")
        print("⚠️  建议重启系统以确保所有痕迹被完全清除")
        print("🔒 高级清理已完成，包含反取证技术")

def main():
    """主函数"""
    cleaner = AdvancedLinuxCleaner()
    cleaner.print_banner()
    
    # 检查参数
    if len(sys.argv) > 1:
        if sys.argv[1] == '--auto':
            cleaner.auto_advanced_clean()
        elif sys.argv[1] == '--help':
            print("""
使用方法:
  python3 advanced_cleaner.py          # 高级交互式模式
  python3 advanced_cleaner.py --auto   # 自动高级清理模式
  python3 advanced_cleaner.py --help   # 显示帮助
            """)
        else:
            print("❌ 无效参数，使用 --help 查看帮助")
    else:
        cleaner.advanced_interactive_mode()

if __name__ == "__main__":
    main()
