# unrouter 项目开发进度

> 最后更新：2025-12-15

---

## 📊 总体进度

- [x] 前期调研
- [x] 阶段 1：History 基础抽象 ✅ **已完成！**
- [ ] 阶段 2：平台特定 History 实现
- [ ] 阶段 3：路由匹配和组件
- [ ] 阶段 4：集成和测试
- [ ] 阶段 5：文档和发布

---

## ✅ 前期调研

### 浏览器导航和历史行为调查
- [x] 创建调查计划文档 (`docs/browser_navigation_investigation.md`)
- [x] 调查 History API 核心功能
  - [x] pushState/replaceState 行为
  - [x] back/forward/go 方法
  - [x] State 对象序列化和大小限制
  - [x] 同源策略和安全限制
- [x] 调查事件机制
  - [x] popstate 事件触发时机
  - [x] hashchange 事件行为
  - [x] 跨浏览器兼容性差异
- [x] 调查 URL Fragment 导航
  - [x] window.location.hash 行为
  - [x] 默认滚动行为
  - [x] 与 History API 的配合
- [x] 研究 React Router history 库实现
  - [x] createBrowserHistory 模式
  - [x] createMemoryHistory 模式
  - [x] createHashHistory 模式
- [x] 编写技术调查报告 (`docs/browser_navigation_findings.md`)
- [x] 更新项目指导文档 (`CLAUDE.md`)

---

## 🔨 阶段 1：History 基础抽象 ✅ **已完成！**

### 1.1 定义核心数据结构 ✅
- [x] 设计 `Location` 类 (`lib/src/history/location.dart`)
  - [x] pathname（路径）
  - [x] search（查询参数）
  - [x] hash（片段标识符）
  - [x] state（状态对象）
  - [x] key（唯一标识符）
  - [x] copyWith 方法
  - [x] toUrl 方法
  - [x] 相等性比较
- [x] 设计 `Action` 枚举和 `Update` 类 (`lib/src/history/update.dart`)
  - [x] Push（添加新条目）
  - [x] Replace（替换当前条目）
  - [x] Pop（后退/前进）
  - [x] Update 类封装操作和位置
- [x] 设计 `Listener` 类型定义 (`lib/src/history/listener.dart`)
  - [x] Listener 回调函数签名
  - [x] Unlisten 取消订阅函数类型

### 1.2 定义 History 抽象接口 ✅
- [x] 创建 `History` 抽象类 (`lib/src/history/history.dart`)
  - [x] 属性：`location` - 当前位置
  - [x] 属性：`action` - 最后的操作类型
  - [x] 方法：`push(path, [state])` - 添加新条目
  - [x] 方法：`replace(path, [state])` - 替换当前条目
  - [x] 方法：`go(delta)` - 跳转指定步数
  - [x] 方法：`back()` - 后退一步
  - [x] 方法：`forward()` - 前进一步
  - [x] 方法：`listen(listener)` - 监听变化
  - [x] 方法：`createHref(location)` - 创建 URL 字符串
  - [x] 辅助方法：`parsePath` - 解析路径
- [x] 编写详细的文档注释
- [x] 提供使用示例

### 1.3 实现 createMemoryHistory ✅
- [x] 创建 `MemoryHistory` 类 (`lib/src/history/memory_history.dart`)
  - [x] 实现历史条目数组（`_entries`）
  - [x] 实现当前索引（`_index`）
  - [x] 实现监听器列表（`_listeners`）
- [x] 实现 `push` 方法
  - [x] 截断当前索引后的条目
  - [x] 添加新条目
  - [x] 更新索引
  - [x] 通知监听器
  - [x] Location 自动生成唯一 key
- [x] 实现 `replace` 方法
  - [x] 替换当前索引的条目
  - [x] 通知监听器
- [x] 实现 `go` 方法
  - [x] 边界检查
  - [x] 更新索引
  - [x] 通知监听器
  - [x] delta 为 0 时刷新
- [x] 实现 `back` 和 `forward` 方法
- [x] 实现 `listen` 方法
  - [x] 添加监听器
  - [x] 返回取消订阅函数
  - [x] 支持迭代中移除
- [x] 实现 `createHref` 方法
- [x] 支持初始化选项
  - [x] `initialEntries` - 初始历史条目（支持 String 和 Location）
  - [x] `initialIndex` - 初始索引
- [x] 编写完整的单元测试 (`test/history/memory_history_test.dart`)
  - [x] 测试基本导航（push/replace/go/back/forward）
  - [x] 测试监听器通知
  - [x] 测试边界条件
  - [x] 测试状态管理
  - [x] 测试复杂导航场景
  - [x] **37 个测试全部通过！**

### 1.4 导出和示例 ✅
- [x] 更新主导出文件 (`lib/unrouter.dart`)
- [x] 创建使用示例 (`example/history_example.dart`)
- [x] 验证示例运行正常

### 📦 交付物
- ✅ 完整的 History 抽象接口
- ✅ 功能完善的 MemoryHistory 实现
- ✅ 100% 测试覆盖率（37 个测试）
- ✅ 详细的 API 文档
- ✅ 可运行的示例代码

---

## 🌐 阶段 2：平台特定 History 实现

### 2.1 Web 平台准备
- [ ] 创建 Web 平台检测工具
- [ ] 设置 `dart:js_interop` 依赖
- [ ] 定义 JavaScript 互操作接口
  - [ ] window.history 接口
  - [ ] window.location 接口
  - [ ] sessionStorage 接口
  - [ ] 事件监听器接口

### 2.2 实现 createBrowserHistory
- [ ] 创建 `BrowserHistory` 类
- [ ] 实现初始化
  - [ ] 读取当前浏览器位置
  - [ ] 支持 `basename` 选项
  - [ ] 注册 popstate 事件监听器
- [ ] 实现 `push` 方法
  - [ ] 调用 `history.pushState`
  - [ ] 同源策略检查
  - [ ] 错误处理（SecurityError）
  - [ ] 状态对象大小检查
  - [ ] 通知监听器
- [ ] 实现 `replace` 方法
  - [ ] 调用 `history.replaceState`
  - [ ] 同源策略检查
  - [ ] 错误处理
- [ ] 实现 `go/back/forward` 方法
  - [ ] 调用相应的浏览器 API
- [ ] 实现 popstate 事件处理
  - [ ] 读取 `event.state`
  - [ ] 同步内部状态
  - [ ] 通知监听器
- [ ] 处理初始 popstate 兼容性
  - [ ] 检测旧浏览器行为
  - [ ] 忽略初始触发
- [ ] 实现状态对象大小管理
  - [ ] 检测大对象
  - [ ] 降级到 sessionStorage
- [ ] 编写单元测试（需要 Web 测试环境）
- [ ] 编写集成测试

### 2.3 实现 createFragmentHistory
- [ ] 创建 `FragmentHistory` 类
- [ ] 实现初始化
  - [ ] 读取当前哈希
  - [ ] 支持 `basename` 选项
  - [ ] 支持 `hashType` 选项（slash/noslash/hashbang）
  - [ ] 注册 hashchange 事件监听器
- [ ] 实现哈希格式化
  - [ ] `slash` 格式：`#/path`
  - [ ] `noslash` 格式：`#path`
  - [ ] `hashbang` 格式：`#!/path`
- [ ] 实现哈希解析
  - [ ] 提取路径
  - [ ] 提取状态键
  - [ ] 解析查询参数
- [ ] 实现 `push` 方法
  - [ ] 生成唯一键
  - [ ] 保存状态到 sessionStorage
  - [ ] 格式化哈希
  - [ ] 设置 `window.location.hash`
  - [ ] 通知监听器
- [ ] 实现 `replace` 方法
  - [ ] 生成键
  - [ ] 保存状态
  - [ ] 使用 `history.replaceState` 更新哈希
- [ ] 实现 hashchange 事件处理
  - [ ] 解析新哈希
  - [ ] 从 sessionStorage 恢复状态
  - [ ] 通知监听器
- [ ] 实现 sessionStorage 管理
  - [ ] 保存状态对象
  - [ ] 读取状态对象
  - [ ] 清理过期状态
- [ ] 实现 `go/back/forward` 方法
- [ ] 编写单元测试
- [ ] 编写集成测试

### 2.4 平台适配层
- [ ] 创建工厂函数
  - [ ] `createBrowserHistory()` - Web 平台检测，App 回退到 Memory
  - [ ] `createFragmentHistory()` - Web 平台检测，App 回退到 Memory
- [ ] 实现平台检测逻辑
  - [ ] 检测是否为 Web 平台
  - [ ] 检测 History API 支持
  - [ ] 自动降级策略
- [ ] 编写平台适配测试

---

## 🧭 阶段 3：路由匹配和组件

### 3.1 路径匹配器
- [ ] 设计路由配置数据结构
  - [ ] `Route` 类
  - [ ] path（路径模式）
  - [ ] builder（组件构建器）
  - [ ] children（子路由）
  - [ ] named（命名 outlet）
- [ ] 实现路径解析器
  - [ ] 静态段匹配
  - [ ] 参数段匹配（`:id`）
  - [ ] 通配符匹配（`*`、`**`）
- [ ] 实现路径参数提取
  - [ ] 提取路径参数
  - [ ] 提取查询参数
- [ ] 实现路由优先级排序
  - [ ] 静态路由优先
  - [ ] 参数路由次之
  - [ ] 通配符最后
- [ ] 实现嵌套路由匹配
  - [ ] 递归匹配子路由
  - [ ] 构建匹配链
- [ ] 编写单元测试
  - [ ] 测试各种路径模式
  - [ ] 测试参数提取
  - [ ] 测试嵌套路由

### 3.2 Router 核心
- [ ] 创建 `Router` 类
  - [ ] 持有 `History` 实例
  - [ ] 持有路由配置
  - [ ] 持有当前匹配结果
- [ ] 实现 `createRouter` 工厂函数
  - [ ] 接收 history 和路由配置
  - [ ] 初始化路由器
  - [ ] 执行初始匹配
- [ ] 实现导航逻辑
  - [ ] 监听 History 变化
  - [ ] 执行路由匹配
  - [ ] 更新当前匹配
  - [ ] 通知订阅者
- [ ] 实现导航 API
  - [ ] `push(path, [state])`
  - [ ] `replace(path, [state])`
  - [ ] `go(delta)`
  - [ ] `back()`
  - [ ] `forward()`
- [ ] 编写单元测试

### 3.3 RouterView 组件
- [ ] 创建 `RouterView` Widget
  - [ ] 支持默认 outlet
  - [ ] 支持命名 outlet（`name` 参数）
- [ ] 实现路由上下文
  - [ ] 使用 InheritedWidget 传递路由信息
  - [ ] 提供当前匹配信息
  - [ ] 提供参数访问
- [ ] 实现组件渲染
  - [ ] 根据匹配结果构建 Widget
  - [ ] 支持嵌套渲染
  - [ ] 支持多个命名 outlet
- [ ] 实现响应式更新
  - [ ] 监听路由变化
  - [ ] 触发重建
- [ ] 编写 Widget 测试
- [ ] 编写集成测试

### 3.4 实用工具
- [ ] 实现参数访问 API
  - [ ] `useParams()` - 获取路径参数
  - [ ] `useSearchParams()` - 获取查询参数
  - [ ] `useLocation()` - 获取当前位置
  - [ ] `useNavigate()` - 获取导航函数
- [ ] 实现导航辅助函数
  - [ ] 相对路径解析
  - [ ] URL 构建
- [ ] 编写文档和示例

---

## 🔗 阶段 4：集成和测试

### 4.1 Flutter 集成
- [ ] 实现 `toFlutterRouterConfig` 函数
  - [ ] 转换为 `RouterConfig<Location>`
  - [ ] 实现 `RouteInformationParser`
  - [ ] 实现 `RouterDelegate`
  - [ ] 实现 `BackButtonDispatcher`
- [ ] 测试与 MaterialApp 集成
  - [ ] 创建示例应用
  - [ ] 测试基本导航
  - [ ] 测试后退按钮
- [ ] 测试与 CupertinoApp 集成
- [ ] 测试与 WidgetsApp 集成
- [ ] 处理深度链接
- [ ] 处理 Web URL 更新

### 4.2 测试套件
- [ ] History 单元测试
  - [ ] MemoryHistory 完整测试
  - [ ] BrowserHistory 测试（需要 Web 环境）
  - [ ] FragmentHistory 测试（需要 Web 环境）
- [ ] 路由匹配器测试
  - [ ] 各种路径模式
  - [ ] 参数提取
  - [ ] 嵌套路由
  - [ ] 边界情况
- [ ] Router 集成测试
  - [ ] 完整导航流程
  - [ ] 状态管理
  - [ ] 监听器通知
- [ ] Widget 测试
  - [ ] RouterView 渲染
  - [ ] 嵌套路由
  - [ ] 命名 outlet
- [ ] 端到端测试
  - [ ] Native 应用场景
  - [ ] Web 应用场景
  - [ ] 混合场景

### 4.3 示例应用
- [ ] 创建基础示例
  - [ ] 简单的多页导航
  - [ ] 参数路由
  - [ ] 嵌套路由
- [ ] 创建高级示例
  - [ ] 命名 outlet
  - [ ] 动态路由
  - [ ] 路由守卫
- [ ] 创建 Web 示例
  - [ ] Browser History
  - [ ] Hash History
  - [ ] URL 同步
- [ ] 创建与 MaterialApp 集成示例

---

## 📚 阶段 5：文档和发布

### 5.1 API 文档
- [ ] 为所有公开 API 编写文档注释
  - [ ] History 接口
  - [ ] Router 类
  - [ ] RouterView Widget
  - [ ] 工具函数
- [ ] 生成 API 文档
- [ ] 审查文档完整性

### 5.2 用户指南
- [ ] 编写入门指南
  - [ ] 安装和设置
  - [ ] 基本概念
  - [ ] 第一个应用
- [ ] 编写核心概念文档
  - [ ] History 类型选择
  - [ ] 路由配置
  - [ ] 嵌套路由
  - [ ] 命名 outlet
- [ ] 编写高级主题
  - [ ] 路由守卫
  - [ ] 状态管理
  - [ ] 性能优化
- [ ] 编写迁移指南
  - [ ] 从其他路由库迁移

### 5.3 README 和示例
- [ ] 完善 README.md
  - [ ] 项目介绍
  - [ ] 特性列表
  - [ ] 快速开始
  - [ ] 基本用法示例
  - [ ] 链接到完整文档
- [ ] 创建 CHANGELOG.md
- [ ] 准备示例代码仓库

### 5.4 发布准备
- [ ] 完善 pubspec.yaml
  - [ ] 版本号
  - [ ] 描述
  - [ ] 依赖版本
  - [ ] SDK 约束
- [ ] 许可证审查
- [ ] 准备发布说明
- [ ] 发布到 pub.dev
  - [ ] 初始版本 0.1.0
  - [ ] 收集反馈
  - [ ] 迭代改进

---

## 🎯 里程碑

### M1: 核心 History 实现 (预计完成度: 40%)
- [x] 浏览器行为调查
- [ ] Memory History 实现和测试
- [ ] 基础数据结构定义

### M2: 平台支持 (预计完成度: 70%)
- [ ] Browser History 实现
- [ ] Fragment History 实现
- [ ] 平台适配层
- [ ] 跨平台测试

### M3: 路由功能 (预计完成度: 90%)
- [ ] 路由匹配器
- [ ] Router 核心
- [ ] RouterView 组件
- [ ] Flutter 集成

### M4: 发布就绪 (预计完成度: 100%)
- [ ] 完整测试套件
- [ ] 完整文档
- [ ] 示例应用
- [ ] 发布到 pub.dev

---

## 📝 开发注意事项

### 技术决策
- **History API**：参考 `docs/browser_navigation_findings.md` 实现细节
- **平台检测**：优先使用条件导入（`dart:html` vs `dart:io`）
- **JavaScript 互操作**：使用最新的 `dart:js_interop`（Dart 3.2+）
- **状态管理**：使用 ChangeNotifier 或自定义监听器模式
- **测试**：使用 `test` 包和 `flutter_test` 包

### 代码规范
- 遵循 Dart 官方代码风格
- 使用 `dart format` 格式化代码
- 使用 `dart analyze` 静态分析
- 保持 100% 测试覆盖率（核心功能）

### 参考资源
- 浏览器调查报告：`docs/browser_navigation_findings.md`
- React Router History：https://github.com/remix-run/history
- Vue Router：https://github.com/vuejs/router
- MDN History API：https://developer.mozilla.org/en-US/docs/Web/API/History_API

---

## 🔄 更新日志

- **2025-12-15**：创建 TODO 文档，完成前期调研阶段
