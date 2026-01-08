# Claude Code Skill Example

CloudCodeでプランモードから開発を設計し、実装を開始する前にworktreeを作成します。
実装が終わったら、PRを作成し、worktreeを削除します。

## スキル一覧

- [create-worktree](./.claude/skills/create-worktree/README.md): planモードが終わるとworktreeを作成します。
- [pr-and-cleanup](./.claude/skills/pr-and-cleanup/README.md): PRを作成し、worktreeを削除します。

## こういうskillとかの作り方
Claude Codeに以下の指示で作りました。
> Planモードが終わって実装が始まる前にworktreeを作るskillを作って

これで出来上がった基本形に追加で指示して自分好みにしてます。
自分は ~/.claude/ に置いて、全プロジェクトで使ってます。
