# AI创作喵网站部署文件

本目录包含部署到 `hujiaofenwritingcat.top` 所需的所有文件。

## 📁 文件结构

```
website-deploy/
├── index.html              # 官网首页
├── user-agreement.html     # 用户协议页面
├── privacy-policy.html     # 隐私政策页面
├── images/                 # 图片资源目录
│   ├── screenshot1.png
│   ├── screenshot2.png
│   └── screenshot3.png
└── README.md               # 本文件
```

## 🚀 快速部署

### 方法一：FTP/SFTP 上传（推荐）

1. **使用 FTP 客户端**（如 FileZilla、WinSCP）
2. **连接到您的服务器**
3. **上传所有文件**到网站根目录（通常是 `public_html/` 或 `www/`）
4. **确保文件权限正确**：
   - HTML 文件：644
   - 目录：755

### 方法二：使用命令行（SSH）

```bash
# 使用 scp 上传
scp -r website-deploy/* user@your-server:/path/to/website/

# 或使用 rsync
rsync -avz website-deploy/ user@your-server:/path/to/website/
```

## ✅ 部署后检查

1. 访问 `https://hujiaofenwritingcat.top` 确认首页正常
2. 检查链接：
   - 用户协议：`https://hujiaofenwritingcat.top/user-agreement.html`
   - 隐私政策：`https://hujiaofenwritingcat.top/privacy-policy.html`
3. 确认图片正常显示
4. 测试移动端访问

## 📝 注意事项

- 确保域名 DNS 已正确解析到服务器
- 如果使用 HTTPS，确保 SSL 证书已配置
- 检查服务器是否支持 `.html` 文件扩展名（通常默认支持）

## 🔧 故障排除

**问题：404 错误**
- 检查文件是否上传到正确目录
- 确认首页文件名为 `index.html`

**问题：图片无法显示**
- 检查 `images/` 目录是否已上传
- 确认图片路径为相对路径 `images/screenshot1.png`

**问题：链接无法访问**
- 确认文件权限正确
- 检查服务器配置是否允许访问 `.html` 文件
