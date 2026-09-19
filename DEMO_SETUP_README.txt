OshiLife 外部デモ公開（GitHub Pages）
====================================

目的
- PCを起動していなくても、スマホからいつでもOshiLifeを確認する
- 家・会社・外出先・友達の端末から同じURLで見る

初回だけやること
1. GitHubで新しいリポジトリを作成
   推奨名: oshilife-demo
   ※ GitHub FreeでPagesを使う場合はPublicが簡単です。

2. このフォルダ直下で SETUP_DEMO_GITHUB.bat をダブルクリック
   作成したGitHubリポジトリのURLを貼り付ける
   例: https://github.com/USERNAME/oshilife-demo.git

3. GitHubのリポジトリを開く
   Settings > Pages > Build and deployment > Source を「GitHub Actions」にする
   （すでにGitHub ActionsになっていればそのままでOK）

4. Actionsタブで「Deploy OshiLife Demo」が成功するまで待つ

公開URL
- リポジトリ名が oshilife-demo の場合:
  https://USERNAME.github.io/oshilife-demo/

以後の更新
- 新版のファイルでこのリポジトリを更新して main にpushすると自動再公開されます。
- PCを閉じても公開URLはそのまま使えます。

保存について
- Web版のローカル保存はブラウザ単位です。
- 公開URLを同じスマホ・同じブラウザで使えば、そのブラウザ内の保存データを継続できます。
- 別端末とのデータ同期は別途クラウド同期機能が必要です。
