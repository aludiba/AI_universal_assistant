# 快速部署到 GitHub Pages

## 🚀 使用 GitHub Pages 部署（适合熟悉 Git 的用户）

### 前置要求
- GitHub 账号（免费注册：https://github.com）
- Git 已安装（macOS 通常已预装）

### 步骤 1：创建 GitHub 仓库

1. 登录 GitHub
2. 点击右上角 "+" → "New repository"
3. 仓库名称：`ai-writing-cat-website`（或任意名称）
4. 选择 **Public**（GitHub Pages 需要公开仓库）
5. 点击 "Create repository"

### 步骤 2：上传文件到 GitHub

在终端执行以下命令：

```bash
# 进入部署目录
cd /Users/chb/Desktop/AI_universal_assistant/AIUniversalAssistant/website-deploy

# 初始化 Git（如果还没有）
git init

# 添加所有文件
git add .

# 提交
git commit -m "Initial commit: 喵墨官网"

# 添加远程仓库（替换 yourusername 为您的 GitHub 用户名）
git remote add origin https://github.com/yourusername/ai-writing-cat-website.git

# 推送到 GitHub
git branch -M main
git push -u origin main
```

### 步骤 3：启用 GitHub Pages

1. 在 GitHub 仓库页面，点击 **Settings**
2. 左侧菜单选择 **Pages**
3. 在 "Source" 部分：
   - Branch: 选择 `main`
   - Folder: 选择 `/ (root)`
4. 点击 **Save**

### 步骤 4：配置自定义域名

1. **创建 CNAME 文件**
   ```bash
   cd website-deploy
   echo "hujiaofenwritingcat.top" > CNAME
   git add CNAME
   git commit -m "Add custom domain"
   git push
   ```

2. **配置 DNS**
   在您的域名管理后台添加 CNAME 记录：
   - 类型：**CNAME**
   - 名称：**@**（根域名）
   - 值：**yourusername.github.io**（替换为您的 GitHub 用户名）
   - TTL：3600

### 步骤 5：等待生效

- DNS 解析通常需要几分钟到几小时
- GitHub Pages 部署通常需要 1-2 分钟
- 访问 `https://hujiaofenwritingcat.top` 查看效果

## ✅ 验证部署

访问以下链接确认：
- ✅ `https://hujiaofenwritingcat.top`
- ✅ `https://hujiaofenwritingcat.top/user-agreement.html`
- ✅ `https://hujiaofenwritingcat.top/privacy-policy.html`

## 🔄 更新网站

以后如果需要更新网站内容：

```bash
cd website-deploy
# 修改文件后
git add .
git commit -m "Update website"
git push
```

GitHub Pages 会自动重新部署（通常 1-2 分钟）。

## 🎉 完成！

您的网站现在已经：
- ✅ 完全免费托管
- ✅ 自动 HTTPS
- ✅ 版本控制（可以回退到任何版本）
- ✅ 全球 CDN

---

**提示：** 如果不熟悉 Git，建议使用 Netlify（拖拽上传更简单）。
