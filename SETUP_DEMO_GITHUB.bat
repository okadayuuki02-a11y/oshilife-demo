@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"

echo ==============================================
echo OshiLife 外部デモ GitHub Pages 初回セットアップ
echo ==============================================
echo.

where git >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Git が見つかりません。
  echo Git for Windows をインストールしてから再実行してください。
  pause
  exit /b 1
)

set /p REPO_URL=GitHubで作ったリポジトリURLを貼り付けてください: 
if "%REPO_URL%"=="" (
  echo URLが入力されていません。
  pause
  exit /b 1
)

if not exist .git (
  git init
)

git branch -M main

git add .
git commit -m "Publish OshiLife demo" || echo 変更がない場合はこの表示で問題ありません。

git remote remove origin >nul 2>nul
git remote add origin "%REPO_URL%"

echo.
echo GitHubへ送信します。認証画面が出たらGitHubでログインしてください。
git push -u origin main
if errorlevel 1 (
  echo.
  echo [ERROR] pushに失敗しました。表示された内容をスクショしてChatGPTに送ってください。
  pause
  exit /b 1
)

echo.
echo ==============================================
echo アップロード完了。
echo 次はGitHubの Settings ^> Pages で Source を GitHub Actions にしてください。
echo ==============================================
pause
