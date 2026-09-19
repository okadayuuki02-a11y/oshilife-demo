@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"

echo OshiLife デモ更新をGitHubへ送信します。
where git >nul 2>nul || (echo Gitが見つかりません。 & pause & exit /b 1)
if not exist .git (echo 初回は SETUP_DEMO_GITHUB.bat を実行してください。 & pause & exit /b 1)

git add .
git commit -m "Update OshiLife demo" || echo 変更がない場合はこの表示で問題ありません。
git push
if errorlevel 1 (
  echo pushに失敗しました。画面をChatGPTへ送ってください。
  pause
  exit /b 1
)
echo 完了。GitHub Actionsが自動で再公開します。
pause
