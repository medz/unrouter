## 前言

在 Flutter 中，从来都没有一个脱离 MaterialApp、CupertinoApp、WidgetsApp 的可用路由器。

所有的路由包都是基于 Flutter 导航器 进行开发，低 API 仅一个 Router，并且它还是基于 Widget（使用了 StatefulWidget）封装
的 Widget 组件。

实际上，我们完全可以做到下面这样简单的基础路由器：

```dart
final router = createRouter(
  history: createMemoryHistory(); // createBrowserHistory、createFragmentHistory,
  [
    Route('/', () => const Home()),
    Route(
      '/users',
      () => const Users(), // default child widget,
      named: {
        'left': () => const UserList(),
        'right': () => const Ad(),
      },
      children: [
        Route(':id', () => const UserDetail()),
        Route('**', () => const UserTip)),
      ],
    ),
  ],
);

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  Widget build(BuildContext context) {
    return RouterView();
  }
}

class Home extends StatelessWidget {
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Home'),
    ),
  }
}

class Users extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        RouterView(name: 'left'),
        RouterView(),
        RouterView(name: 'right'),
      ],
    );
  }
}

class UserList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const ListView(...);
  }
}

class UserDetail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('UserDetail'),
    );
  }
}

class Ad extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('Ad');
  }
}

class UserTip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('UserTip'),
    );
  }
}
```

当与 MaterialApp、CupertinoApp、WidgetsApp 等配合：

```dart
class App extends StatelessWidget {
  Widget build(BuildContext context) {
    return MaterialApp(
      routerConfig: toFlutterRouterConfig(router),
    );
  }
}
```

## 为什么需要这个？

有了这个，提供最基础的导航功能，并且匹配浏览器的导航行为。所有人都可以直接脱离 MaterialApp、CupertinoApp 构建自己独特的 UI
包或者框架而无需当心导航功能。用户只需要依赖 `unrouter` 无论是在 Flutter 内置的 App 模式中还是完全有第三方构建的 UI 框架/组件 中都可以享受导航器功能。并且没有复杂代价。

另外，提供 `toFlutterRouterConfig` 的目的则是为 Flutter 内置 App 场景（都是基于 WidgetsApp 开发的）允许用户除了使用独特的 unrouter 导航功能，还可以直接使用 Flutter 导航器功能而不会造成任何成本。

## history 是什么？

### createMemoryHistory()

这通常是 Native 平台默认的，但可以在 Web 中使用。不实用原生的路由效果。模拟浏览器的导航和历史行为。

### createBrowserHistory

它匹配浏览器的导航行为和历史行为，当 Flutter 编译为 App 时候，回退到 createMemoryHistory、当构建为 web 时候直接使用。

注意：它通常使用 Dart 的 JS 互相调用行为，直接交互 Web 的 History。

### createFragmentHistory

和 createBrowserHistory 类似，只是使用 URL 的 Fragment 部分进行记录，例如 `https://example.com#users/1?page=1`.
并且在编译为 App 时候回退到 createMemoryHistory。

## 如何实施？

我们应该优先实施 History。

更多的可以一步一步地询问我。

---

## 项目进度

### ✅ 已完成：浏览器导航和历史行为调查（2025-12-15）

已完成详细的浏览器 History API 和导航行为调查，调查报告位于：
- **计划文档**：`docs/browser_navigation_investigation.md`
- **技术报告**：`docs/browser_navigation_findings.md`

#### 调查成果总结

1. **History API 核心功能**
   - pushState/replaceState/back/forward/go 的详细行为
   - State 对象大小限制（640KB-16MB）和序列化要求
   - 同源策略和安全限制
   - scrollRestoration 滚动恢复机制

2. **事件机制**
   - popstate 事件：触发时机和跨浏览器差异
   - hashchange 事件：Fragment 导航专用
   - 事件触发顺序和兼容性问题

3. **三种 History 实现模式**
   - **Memory History**：内存数组维护，适合 Native 和测试
   - **Browser History**：HTML5 History API，现代浏览器首选
   - **Hash History**：URL Fragment，遗留浏览器支持

4. **实现建议**
   - 包含详细的代码示例和最佳实践
   - 错误处理和状态管理策略
   - Flutter/Dart 平台适配方案

### 📋 下一步计划

#### 阶段 1：实现 History 基础抽象

1. **定义 History 接口**
   - 定义通用的 History 抽象类/接口
   - 包含：push, replace, go, back, forward, listen 等方法
   - 定义 Location 数据结构

2. **实现 createMemoryHistory**
   - 纯 Dart 实现，无需平台 API
   - 维护历史条目数组和当前索引
   - 实现监听器模式
   - 编写单元测试

#### 阶段 2：实现平台特定 History

3. **实现 createBrowserHistory（Web 平台）**
   - 使用 `dart:js_interop` 与浏览器 History API 交互
   - 监听 popstate 事件
   - 处理同源策略和错误
   - 实现 state 对象大小检查

4. **实现 createFragmentHistory（Web 平台）**
   - 使用 URL Fragment 存储路由
   - 监听 hashchange 事件
   - 使用 window.sessionStorage 存储状态对象
   - 支持多种哈希格式（slash/noslash/hashbang）

#### 阶段 3：路由匹配和组件

5. **实现路由匹配器**
   - 路径解析和匹配算法
   - 支持参数路由（:id）
   - 支持通配符路由（**）
   - 嵌套路由支持

6. **实现 RouterView 组件**
   - 默认和命名 outlet
   - 与 History 集成
   - 嵌套路由渲染

#### 阶段 4：集成和测试

7. **Flutter 集成**
   - 实现 `toFlutterRouterConfig`
   - 与 MaterialApp/CupertinoApp 集成测试

8. **完整测试套件**
   - 单元测试
   - 集成测试
   - Web/Native 平台测试

### 💡 开发指导

当你继续开发时，请：
1. 参考 `docs/browser_navigation_findings.md` 中的实现建议和代码示例
2. 遵循报告中的最佳实践（错误处理、状态管理等）
3. 注意跨浏览器兼容性问题（详见报告第七节）
4. 优先实现 Memory History，然后再实现平台特定的 History

### 📚 参考文档

- **[项目进度追踪](TODO.md)** - 详细的任务清单和里程碑
- [浏览器导航调查计划](docs/browser_navigation_investigation.md)
- [浏览器导航技术报告](docs/browser_navigation_findings.md)
- [React Router History 源码](https://github.com/remix-run/history)
- [MDN History API 文档](https://developer.mozilla.org/en-US/docs/Web/API/History_API)

### 🎯 当前状态

**已完成阶段**：
- ✅ 前期调研（浏览器导航和历史行为调查）
- ✅ **阶段 1：History 基础抽象**

**当前阶段**：阶段 1 已完成！🎉

**下一步**：开始实现阶段 2 - 平台特定 History 实现（Browser History 和 Fragment History）

详细的任务清单和进度请查看 [TODO.md](TODO.md)

#### 阶段 1 完成总结

已成功实现：
- ✅ `Location` 类 - 完整的 URL 位置表示
- ✅ `Action` 枚举和 `Update` 类 - 操作类型定义
- ✅ `History` 抽象类 - 统一的 History 接口
- ✅ `MemoryHistory` 实现 - 功能完善的内存历史管理
- ✅ 37 个单元测试全部通过
- ✅ 完整的 API 文档和使用示例

文件清单：
- `lib/src/history/location.dart`
- `lib/src/history/update.dart`
- `lib/src/history/listener.dart`
- `lib/src/history/history.dart`
- `lib/src/history/memory_history.dart`
- `lib/unrouter.dart`
- `test/history/memory_history_test.dart`
- `example/history_example.dart`
