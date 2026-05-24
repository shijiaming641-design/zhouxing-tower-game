# Art Pack v2 接入报告

来源文件：

```text
/Users/xiaoshizi/Desktop/zhouxing_art_pack_v2.zip
```

## 接入结论

压缩包头部是 ZIP，但缺少正常的 End Of Central Directory 结尾。`unzip` 和 Python `zipfile` 都不能直接读取，已使用 `zip -FF` 抢救。

已恢复并接入的内容：

- 角色新目录：`assets/characters/<role>/`
- 兼容旧代码的扁平角色图：`assets/characters/*_portrait.png`、`*_select.png`、`*_battle.png`
- 战斗反馈特效：`assets/effects/`
- 部分敌人新目录：`assets/enemies/advanced/enemy_advanced_assault.png`
- 包内清单：`docs/ART_PACK_V2_MANIFEST.md`
- 包内 README：`docs/ART_PACK_V2_README.md`

已做代码适配：

- `ArtRegistry` 优先读取 v2 新目录。
- 工匠使用 `artisan` 新目录，同时保留旧 `hacker` 扁平路径回退。
- 敌人支持新分层目录：`basic/`、`elite/`、`advanced/`、`boss/`，缺失时回退旧扁平路径。
- 新增角色小头像、角色被动图标、战斗特效路径查询。
- 行为按钮图标优先读 `assets/icons/action/`，缺失时回退旧图标。

## 当前缺失

包内清单声明 290 个资源路径；当前项目存在 145 个，缺失 145 个。

主要缺失类别：

- 敌人分层目录大部分缺失：`assets/enemies/basic/`、`assets/enemies/elite/`、部分 `advanced/`、`boss/phase2`
- 行为图标缺失：`assets/icons/action/`
- 扩展战斗图标缺失：碎甲、连招、暴击、胜利、失败、平局
- 资源图标缺失：金币、材料、存储器、生命、攻击、护甲
- 状态图标缺失：灼烧、减速、增攻、虚弱、Boss 阶段
- 具体装备图标缺失：`assets/items/equipment/`
- 扩展时代 UI 缺失：事件背景、商店背景、营寨背景、结算背景
- 时代按钮/卡片/弹窗/扩展章印缺失：`buttons/`、`cards/`、`overlays/`

## 重新导出建议

请重新压缩完整目录，确保压缩包可以通过以下命令正常列出：

```text
unzip -t zhouxing_art_pack_v2.zip
unzip -l zhouxing_art_pack_v2.zip
```

推荐重新打包目录结构：

```text
zhouxing_art_pack_v2/
├── README.md
├── asset_manifest.md
└── assets/
```

重新发包后，可以直接覆盖当前 `assets/`，代码端已经准备好读取 v2 新目录并保留旧路径回退。

