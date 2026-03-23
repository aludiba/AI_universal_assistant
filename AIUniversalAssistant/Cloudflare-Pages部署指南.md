# Cloudflare Pages 部署指南（最接近 freemeapp.lovin.cloud 的方式）

## 🎯 目标

将 喵墨官网部署到类似 `freemeapp.lovin.cloud` 的子域名结构。

## 📋 前置要求

- Cloudflare 账号（免费注册：https://dash.cloudflare.com/sign-up）
- GitHub 账号（可选，但推荐）
- 域名（如果需要自定义子域名）

## 🚀 详细部署步骤

### 方法一：通过 GitHub 部署（推荐）

#### 步骤 1：上传到 GitHub

```bash
# 进入部署目录
cd /Users/chb/Desktop/AI_universal_assistant/AIUniversalAssistant/website-deploy

# 初始化 Git（如果还没有）
git init

# 添加所有文件
git add .

# 提交
git commit -m "喵墨官网 - 初始版本"

# 在 GitHub 创建新仓库后，添加远程仓库
git remote add origin https://github.com/yourusername/ai-writing-cat-website.git

# 推送到 GitHub
git branch -M main
git push -u origin main
```

#### 步骤 2：连接 Cloudflare Pages

1. **登录 Cloudflare Dashboard**
   - 访问 https://dash.cloudflare.com
   - 登录账号

2. **创建 Pages 项目**
   - 点击左侧菜单 "Workers & Pages"
   - 点击 "Create application"
   - 选择 "Pages"
   - 点击 "Connect to Git"

3. **授权 GitHub**
   - 点击 "Connect GitHub"
   - 授权 Cloudflare 访问您的 GitHub 仓库
   - 选择仓库：`ai-writing-cat-website`

4. **配置构建设置**
   - Project name: `ai-writing-cat-website`（或任意名称）
   - Production branch: `main`
   - Framework preset: **None**（静态网站）
   - Build command: （留空）
   - Build output directory: `/`（根目录）
   - Root directory: （留空，使用根目录）

5. **部署**
   - 点击 "Save and Deploy"
   - 等待部署完成（通常 1-2 分钟）

#### 步骤 3：配置自定义域名

1. **添加自定义域名**
   - 在 Pages 项目页面，点击 "Custom domains"
   - 点击 "Set up a custom domain"
   - 输入您想要的域名：
     - 如果使用子域名：`aiwritingcat.lovin.cloud`
     - 或使用主域名：`hujiaofenwritingcat.top`

2. **配置 DNS（如果域名在 Cloudflare）**
   - Cloudflare 会自动配置 DNS 记录
   - 等待几分钟让 DNS 生效

3. **配置 DNS（如果域名不在 Cloudflare）**
   - 在您的域名管理后台添加 CNAME 记录：
     ```
     类型: CNAME
     名称: aiwritingcat (子域名部分)
     目标: your-site.pages.dev (Cloudflare Pages 提供的地址)
     ```

---

### 方法二：直接上传文件（无需 Git）

1. **登录 Cloudflare Dashboard**
   - 访问 https://dash.cloudflare.com

2. **创建 Pages 项目**
   - Workers & Pages → Create application → Pages
   - 选择 "Upload assets"

3. **准备 ZIP 文件**
   ```bash
   cd /Users/chb/Desktop/AI_universal_assistant/AIUniversalAssistant/website-deploy
   zip -r website.zip .
   ```

4. **上传并部署**
   - 在 Cloudflare Pages 上传 `website.zip`
   - 点击 "Deploy site"
   - 等待部署完成

5. **配置域名**（同方法一的步骤 3）

---

## 🌐 域名配置详解

### 场景 1：使用子域名（如 aiwritingcat.lovin.cloud）

**如果 `lovin.cloud` 在 Cloudflare 管理：**

1. 在 Cloudflare 添加域名 `lovin.cloud`（如果还没有）
2. 在 Pages 项目添加自定义域名：`aiwritingcat.lovin.cloud`
3. Cloudflare 会自动创建 DNS 记录

**如果 `lovin.cloud` 不在 Cloudflare：**

1. 在您的域名管理后台添加 CNAME：
   ```
   类型: CNAME
   名称: aiwritingcat
   目标: your-site-abc123.pages.dev
   ```

### 场景 2：使用主域名（hujiaofenwritingcat.top）

1. 在 Pages 项目添加自定义域名：`hujiaofenwritingcat.top`
2. 如果域名在 Cloudflare，自动配置
3. 如果不在，添加 CNAME 记录指向 Pages 地址

---

## ✅ 部署后验证

访问以下链接确认一切正常：

- ✅ `https://aiwritingcat.lovin.cloud`（或您配置的域名）
- ✅ `https://aiwritingcat.lovin.cloud/user-agreement.html`
- ✅ `https://aiwritingcat.lovin.cloud/privacy-policy.html`
- ✅ 检查图片是否正常显示
- ✅ 测试移动端访问

---

## 🔄 更新网站

### 如果使用 GitHub 部署：

```bash
cd website-deploy
# 修改文件后
git add .
git commit -m "更新网站内容"
git push
```

Cloudflare Pages 会自动检测更改并重新部署。

### 如果使用直接上传：

1. 修改文件
2. 重新打包 ZIP
3. 在 Cloudflare Pages 重新上传

---

## 🎉 完成！

您的网站现在已经：
- ✅ 部署在 Cloudflare Pages（类似 freemeapp.lovin.cloud）
- ✅ 全球 CDN 加速
- ✅ 自动 HTTPS（免费 SSL）
- ✅ 完全免费
- ✅ 支持自定义域名/子域名

---

## 📊 与 freemeapp.lovin.cloud 的对比

| 特性 | freemeapp.lovin.cloud | 您的网站（Cloudflare Pages） |
|------|----------------------|---------------------------|
| 托管服务 | 未知（可能是 Cloudflare） | Cloudflare Pages |
| 子域名支持 | ✅ | ✅ |
| HTTPS | ✅ | ✅（自动） |
| CDN | ✅ | ✅（全球） |
| 免费 | 未知 | ✅ |
| 自定义域名 | ✅ | ✅ |

---

**推荐：使用 Cloudflare Pages 通过 GitHub 部署，这是最接近 freemeapp.lovin.cloud 部署方式的方案。**
