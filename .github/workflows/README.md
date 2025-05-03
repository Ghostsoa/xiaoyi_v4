# GitHub Actions 工作流说明

## iOS构建流程

此工作流程用于自动构建iOS应用，并将构建产物上传到GitHub Actions的构建产物存储中。

### 触发条件

工作流会在以下情况下自动运行：
- 向`main`分支推送代码时
- 创建针对`main`分支的Pull Request时
- 手动在GitHub Actions界面点击"Run workflow"按钮时

### 构建过程

1. 使用最新的macOS环境
2. 设置Java环境（Flutter需要）
3. 安装指定版本的Flutter SDK
4. 获取Flutter依赖
5. 构建iOS应用（无需代码签名）
6. 上传构建产物

### 获取构建产物

构建完成后，您可以在GitHub Actions的执行记录中下载构建产物。构建产物将保留7天。

### 注意事项

- 此构建过程仅生成未签名的`.app`文件，不生成可分发的`.ipa`文件
- 若要分发正式应用，您需要下载构建产物后，使用Apple Developer账号进行签名和提交
- 如需添加代码签名，您需要在工作流中配置iOS证书和描述文件 