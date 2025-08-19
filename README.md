# Linux 入侵痕迹清理工具

一个功能完整的Linux入侵痕迹清理工具，用于在攻击结束后不留痕迹地清除日志和操作记录。

## ⚠️ 免责声明

**本工具仅用于教育和研究目的，请勿用于非法活动。使用者需自行承担使用风险。**

## 功能特性

### 🔍 清除历史命令记录
- 清除当前会话历史记录 (`history -c`)
- 清空 `.bash_history` 文件
- 设置环境变量不记录历史
- 删除其他shell历史文件 (`.zsh_history`, `.bash_sessions`, `.python_history`)

### 📝 清除系统日志痕迹
- 清空登录失败记录 (`/var/log/btmp`)
- 清空登录成功记录 (`/var/log/wtmp`)
- 清空最后登录时间 (`/var/log/lastlog`)
- 清空当前登录用户信息 (`/var/log/utmp`)
- 清空安全日志 (`/var/log/secure`)
- 清空系统消息日志 (`/var/log/messages`)
- 清空认证日志 (`/var/log/auth.log`)
- 清空系统日志 (`/var/log/syslog`)
- 清除journalctl日志
- 清空审计日志和Web服务器日志

### 🌐 清除Web入侵痕迹
- 清空Nginx访问/错误日志
- 清空Apache访问/错误日志
- 自动替换IP地址为虚假IP
- 支持多种Web服务器日志格式

### 🗑️ 文件安全删除
- 使用 `shred` 命令安全删除 (8次覆盖)
- 使用 `dd` 命令覆盖删除
- 使用 `wipe` 命令删除
- 使用 `srm` 命令删除
- 支持文件和目录的安全删除

### 🔐 隐藏SSH登录痕迹
- 清空SSH相关日志文件
- 检测SSH密钥目录
- 提供SSH隐身登录建议

### 💾 清理内存痕迹
- 清理内存缓存
- 清理swap分区
- 需要root权限

## 安装和使用

### 系统要求
- Python 3.6+
- Linux系统
- 某些功能需要root权限

### 安装依赖
```bash
# 安装必要的系统工具
sudo apt-get update
sudo apt-get install shred wipe secure-delete curl

# 或者对于CentOS/RHEL
sudo yum install shred wipe secure-delete curl
```

### 使用方法

#### 1. 交互式模式 (推荐)
```bash
python3 linux_cleaner.py
```

#### 2. 自动清理模式
```bash
python3 linux_cleaner.py --auto
```

#### 3. 查看帮助
```bash
python3 linux_cleaner.py --help
```

## 使用示例

### 交互式模式菜单
```
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
```

### 安全删除文件示例
```bash
# 选择选项4，然后输入文件路径
请输入要删除的文件路径: /tmp/evil_tool.py
```

## 技术细节

### 历史记录清理方法
1. **清除当前会话历史**: `history -c`
2. **清空历史文件**: 直接清空 `~/.bash_history`
3. **环境变量设置**: 
   ```bash
   unset HISTORY HISTFILE HISTSAVE HISTZONE HISTORY HISTLOG
   export HISTFILE=/dev/null
   export HISTSIZE=0
   export HISTFILESIZE=0
   ```

### 系统日志清理
- 直接清空日志文件内容
- 使用 `journalctl --vacuum-time=1s` 清理systemd日志
- 支持多种日志格式和位置

### 文件安全删除算法
1. **shred命令**: 8次随机数据覆盖 + 3次零覆盖
2. **dd命令**: 使用 `/dev/zero` 覆盖文件内容
3. **wipe命令**: 使用特殊模式重复写入
4. **srm命令**: Secure-Delete工具集的安全删除

### Web日志处理
- 自动检测当前IP地址
- 使用sed命令替换IP地址为虚假IP
- 支持多种Web服务器日志格式

## 注意事项

### ⚠️ 重要警告
1. **权限要求**: 某些操作需要root权限
2. **数据丢失**: 安全删除操作不可逆
3. **系统影响**: 清理系统日志可能影响系统监控
4. **法律风险**: 请确保在合法环境下使用

### 🔒 安全建议
1. 在测试环境中先验证功能
2. 备份重要数据
3. 了解目标系统的日志配置
4. 考虑使用时间戳修改技术

### 🛡️ 额外防护措施
1. **时间戳修改**: 修改文件的访问/修改时间
2. **进程隐藏**: 使用进程隐藏技术
3. **网络痕迹**: 清理网络连接记录
4. **内核模块**: 考虑使用内核级隐藏技术

## 高级用法

### SSH隐身登录
```bash
# 不记录公钥的SSH登录
ssh -o UserKnownHostsFile=/dev/null -T user@host /bin/bash -i

# 隐身登录，不被w/who检测
ssh -T root@192.168.0.1 /bin/bash -i
```

### 时间戳修改
```bash
# 修改文件时间戳
touch -t 202301010000 file.txt

# 批量修改目录时间戳
find /path/to/dir -exec touch -t 202301010000 {} \;
```

### 进程隐藏
```bash
# 使用nohup后台运行
nohup command > /dev/null 2>&1 &

# 使用screen会话
screen -dmS session_name command
```

## 故障排除

### 常见问题
1. **权限不足**: 使用 `sudo` 运行
2. **命令不存在**: 安装相应的系统工具
3. **文件被占用**: 确保文件未被其他进程使用
4. **磁盘空间不足**: 检查磁盘空间

### 调试模式
```bash
# 启用详细输出
python3 -v linux_cleaner.py
```

## 更新日志

### v1.0.0
- 初始版本发布
- 支持基本的痕迹清理功能
- 交互式和自动模式
- 多语言界面支持

## 贡献

欢迎提交Issue和Pull Request来改进这个工具。

## 许可证

本项目仅供教育和研究使用。

---

**再次提醒: 请确保在合法和授权的环境中使用此工具。**
