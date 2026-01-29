# 快速部署到 Netlify（最简单的方法）

## 🚀 5 分钟快速部署

### 步骤 1：注册 Netlify（1 分钟）

1. 访问 https://www.netlify.com
2. 点击右上角 "Sign up"
3. 使用 GitHub、Google 或 Email 注册

### 步骤 2：上传网站（2 分钟）

1. 登录后，点击 **"Add new site"** → **"Deploy manually"**
2. 将整个 `website-deploy` 文件夹拖拽到上传区域
3. 等待上传完成（通常几秒钟）

### 步骤 3：配置域名（2 分钟）

1. 上传完成后，点击 **"Site settings"**
2. 选择 **"Domain management"**
3. 点击 **"Add custom domain"**
4. 输入：`hujiaofenwritingcat.top`
5. 按照提示配置 DNS：
   - 类型：**CNAME**
   - 名称：**@**（根域名）
   - 值：显示的 Netlify 地址（例如：`your-site-123.netlify.app`）

### 步骤 4：完成 ✅

- Netlify 会自动配置 HTTPS（免费 SSL 证书）
- 几分钟后即可访问 `https://hujiaofenwritingcat.top`

## 📸 详细截图说明

### 上传文件
```
Netlify 控制台
┌─────────────────────────────┐
│  Add new site              │
│  ┌───────────────────────┐ │
│  │  拖拽 website-deploy  │ │
│  │  文件夹到这里         │ │
│  └───────────────────────┘ │
└─────────────────────────────┘
```

### DNS 配置示例
```
在您的域名管理后台添加：

类型: CNAME
名称: @
值:   your-site-123.netlify.app
TTL:  3600
```

## ✅ 部署后验证

访问以下链接确认一切正常：
- ✅ `https://hujiaofenwritingcat.top`
- ✅ `https://hujiaofenwritingcat.top/user-agreement.html`
- ✅ `https://hujiaofenwritingcat.top/privacy-policy.html`

## 🎉 完成！

您的网站现在已经：
- ✅ 全球 CDN 加速
- ✅ 自动 HTTPS（免费 SSL）
- ✅ 自动备份和版本管理
- ✅ 完全免费

---

**需要帮助？** 查看 `iCloud替代方案-免费部署指南.md` 获取更多选项。
