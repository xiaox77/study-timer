# GitHub Deploy

当前发布目录已经是一个可提交的 Git 项目。

## 推荐方式：GitHub CLI

安装并登录 GitHub CLI 后，在 `StudyTimer` 目录运行：

```powershell
gh auth login
gh repo create study-timer --private --source . --remote origin --push
```

如果你确认图片素材可以公开，也可以把 `--private` 改成 `--public`。

## 推送到已有空仓库

如果你已经在 GitHub 创建了空仓库，例如：

```text
https://github.com/everCoke/study-timer.git
```

在 `StudyTimer` 目录运行：

```powershell
git remote add origin https://github.com/everCoke/study-timer.git
git push -u origin main
```

## 让 Codex 继续部署

把已有仓库名发给 Codex，例如：

```text
everCoke/study-timer
```

Codex 可以继续把当前发布目录的文件提交到这个已有仓库。

## 注意

图片素材来自用户提供的文件。公开仓库发布前，请确认图片版权和授权。
