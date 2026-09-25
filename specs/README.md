# specs

`core/` 的设计规范。**这里写「为什么这样定」和「新代码必须遵守什么」**；
怎么用某个 API 看头文件的 Doxygen 注释，怎么跑生成器看
[tools/codegen/README.md](../tools/codegen/README.md)。

## 读什么

| 规范 | 回答的问题 | 状态 |
|---|---|---|
| [architecture.md](architecture.md) | 一段新代码放哪一层、哪个目录、叫什么名字 | 已实施 |
| [object-model.md](object-model.md) | 一个公共类型怎么被创建、持有、传递、销毁 | 已实施 |
| [api-style.md](api-style.md) | 一个公共方法 / 类型 / 枚举叫什么、收什么、返回什么、失败怎么说 | 已实施 |
| [platform-seam.md](platform-seam.md) | 平台相关的状态和代码藏在哪里、怎么藏 | 已实施 |
| [event-system.md](event-system.md) | 事件怎么定义、怎么发、在哪个线程跑 | 已实施 |
| [managers.md](managers.md) | 系统级资源由谁持有、三张查找表怎么分工 | 已实施 |
| [c-abi.md](c-abi.md) | C ABI 长什么样、由谁产出、类型怎么过桥 | 生成管线已实施 |
| [handle-ownership.md](handle-ownership.md) | C ABI 句柄的所有权与失效语义 | 已决策，实施中 |
| [view.md](view.md) | 怎么在窗口里放原生控件（View）并响应它：类型、所有权、布局、事件 | 已实施 |

新增一个跨平台模块，按顺序读 architecture → object-model → api-style → platform-seam；
要过 C ABI 再读 c-abi + handle-ownership。

只是给现有类加一两个方法，读 api-style 一篇就够——它的检查单就是头文件 diff 的
review 清单。

## 未决事项写在哪

没有单独的问题清单。**每篇规范自己带着它那个领域的未决项和存量缺口**：

- 规则旁边就地标注违反它的存量代码（「存量缺口」「已知违规」），写到类名 / 方法名。
- 方向还没定的问题放在该篇的「未决」一节（event-system §6、managers §5、c-abi §7、
  api-style §4），写清现状和候选方向。

问题解决后直接改规范正文：删掉缺口标注，或把「未决」里的条目改写成规则。
2026-08-22 那次全量审查的原始清单在 git 历史里（`DESIGN_REVIEW.md`）。

## 写规范的约定

- 每篇开头给出**状态**、**适用范围**、**核实基准日期**。规范会腐烂，日期让读者知道
  该不该重新核对。
- 断言要能在代码里被验证。写「当前 14 个头文件用 PIMPL」这种可数的事实，
  而不是「大部分类使用 PIMPL」。
- 已知的不一致就地写出来（哪个类、哪个方法、差在哪），不要粉饰成统一。
- 结尾放检查单，让规范可以当 code review 清单用。
