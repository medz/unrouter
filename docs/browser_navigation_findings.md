# 浏览器导航和历史行为技术调查报告

本文档详细记录了浏览器 History API 和导航行为的调查结果，为 unrouter 项目的实现提供技术参考。

---

## 一、History API 核心功能

### 1.1 基础属性

#### window.history.length
- 返回历史记录堆栈中的条目数量
- 只读属性
- 包括当前页面在内
- 浏览器兼容性：自 2015 年 7 月起广泛支持

#### window.history.state
- 返回当前历史条目关联的状态对象
- 如果条目没有状态对象，返回 `null`
- 只读属性
- 刷新页面后状态会保留

#### window.history.scrollRestoration
- 控制浏览器在历史导航时的滚动恢复行为
- 可选值：
  - `"auto"`（默认）：浏览器自动恢复滚动位置
  - `"manual"`：开发者手动控制滚动位置
- 浏览器支持：自 2020 年 1 月起跨浏览器可用
- **重要特性**：
  - 设置应用于当前条目
  - 从外部链接返回时滚动状态不会恢复
  - 可以通过 `history.state` 自定义滚动位置恢复行为

### 1.2 导航方法

#### history.back()
- 相当于点击浏览器的后退按钮
- 等同于 `history.go(-1)`
- 如果没有上一页，调用无效果
- **无参数**
- 异步操作，使用 `popstate` 事件监听完成

#### history.forward()
- 相当于点击浏览器的前进按钮
- 等同于 `history.go(1)`
- 如果没有下一页，调用无效果
- **无参数**
- 异步操作

#### history.go(n)
- 在历史堆栈中跳转到指定位置
- 参数：
  - 正数：前进 n 页
  - 负数：后退 n 页
  - 0 或无参数：刷新当前页面
- 异步操作
- 示例：
  ```javascript
  history.go(-1);  // 后退一页
  history.go(1);   // 前进一页
  history.go(0);   // 刷新当前页
  history.go();    // 刷新当前页
  ```

#### history.pushState(state, title, url)
- 向历史堆栈添加新条目
- **不会触发页面重载**
- **不会触发 `popstate` 事件**
- 参数：
  - `state`：与新条目关联的状态对象（可序列化对象）
  - `title`：大多数浏览器忽略此参数，通常传空字符串
  - `url`：新条目的 URL（可选，默认当前 URL）
    - 可以是相对 URL
    - 可以是绝对 URL
    - **必须与当前 URL 同源**，否则抛出安全异常
- 用例：SPA 中的路由切换

#### history.replaceState(state, title, url)
- 替换当前历史条目
- **不会增加历史堆栈大小**
- 参数与 `pushState` 相同
- 使用场景：
  - 更新当前页面的状态
  - 修正初始 URL
  - 保存表单状态而不增加历史记录

---

## 二、浏览器导航行为详解

### 2.1 pushState 详细行为

**核心特性**：
1. 改变浏览器地址栏 URL，但不发送导航请求
2. 添加新的历史条目到堆栈
3. `history.length` 增加 1
4. 不触发页面刷新或重载
5. 不触发 `popstate` 事件

**State 对象**：
- **大小限制**：
  - Firefox：640KB（早期版本）到 16MB（最新版本）
  - 超过限制会抛出异常
  - 建议：大量数据使用 `sessionStorage` 或 `localStorage`
- **序列化方法**：
  - Gecko 2.0-5.0：JSON 序列化
  - Gecko 6.0+：结构化克隆算法（Structured Clone Algorithm）
- **不支持的数据类型**：
  - 函数
  - DOM 节点
  - 其他不可序列化的对象
- **持久化**：
  - Firefox 将状态对象保存到磁盘
  - 浏览器重启后可恢复
  - 标签页关闭后失效

**URL 限制**：
- **同源策略**：新 URL 必须与当前 URL 同源
  - 同源定义：协议 + 主机 + 端口 相同
  - 违反同源策略会抛出 `SecurityError`
- URL 可以是：
  - 相对路径：`/users/123`
  - 绝对路径：`https://example.com/users/123`
  - 仅查询参数：`?page=2`
  - 仅哈希：`#section1`

**安全考虑**：
- 允许网站在同源范围内更改 URL
- URL 拦截策略可能在页面刷新前不生效
- HTML5 规范定义了标准的同源检查

### 2.2 replaceState 详细行为

**与 pushState 的区别**：
- 替换当前条目，而不是添加新条目
- `history.length` 保持不变
- 用户无法通过后退按钮返回到被替换的状态

**使用场景**：
1. 更新 URL 以反映当前应用状态
2. 修正初始加载的 URL
3. 表单提交后更新 URL（避免重复提交）
4. 无限滚动时更新页码

### 2.3 back/forward/go 导航行为

**触发的事件**：
- 触发 `popstate` 事件
- 如果 URL 哈希改变，触发 `hashchange` 事件

**用户操作 vs 程序调用**：
- 两者行为一致
- 都是异步操作
- 都触发相同的事件

**popstate 事件属性**：
```javascript
window.addEventListener('popstate', (event) => {
  console.log('State:', event.state);
  console.log('Location:', document.location);
});
```
- `event.state`：与该历史条目关联的状态对象
- 对于没有状态对象的条目，`event.state` 为 `null`

---

## 三、popstate 事件机制

### 3.1 触发时机

**触发情况**：
- 调用 `history.back()`
- 调用 `history.forward()`
- 调用 `history.go()`
- 用户点击浏览器后退/前进按钮

**不触发的情况**：
- 调用 `history.pushState()`
- 调用 `history.replaceState()`
- 改变 `window.location.hash`（会触发 `hashchange`）

### 3.2 初始页面加载行为（重要！）

**历史行为差异**：
- **Chrome（v34 之前）**：页面加载时触发 `popstate`
- **Safari（v10.0 之前）**：页面加载时触发 `popstate`
- **Firefox**：从未在页面加载时触发 `popstate`

**当前统一行为**：
- 现代浏览器（Chrome v34+, Safari v10.0+）不再在页面加载时触发 `popstate`
- 这一差异曾导致路由库需要实现规范化逻辑

**解决方案**：
许多路由库实现了检测和规范化逻辑来处理旧浏览器的差异：
```javascript
// 示例：检测初始 popstate
let isInitialLoad = true;
window.addEventListener('popstate', (event) => {
  if (isInitialLoad) {
    isInitialLoad = false;
    return; // 忽略初始触发
  }
  // 处理实际的导航
});
```

### 3.3 scrollRestoration 与 popstate 的交互

**事件触发顺序的浏览器差异**：
- **Chrome**：先触发 `popstate`，后触发 `scroll` 事件
  - 可以在 `popstate` 中读取当前滚动位置
  - 在 `scroll` 事件中使用 `window.scrollTo` 恢复
- **Firefox**：先触发 `scroll`，后触发 `popstate`
  - 无法在 `popstate` 中获取旧的滚动位置

**恢复时机**：
- Chrome：一个动画帧
- Safari：多个动画帧

---

## 四、URL Fragment（哈希）导航

### 4.1 Fragment 基础

**定义**：
- URL 中 `#` 符号及其后面的部分
- 示例：`https://example.com/page#section1`
  - Fragment: `#section1`

**核心特性**：
- Fragment 变化不会触发页面重载
- Fragment 不会发送到服务器
- 纯客户端行为
- 会创建浏览器历史记录

### 4.2 window.location.hash

**读取**：
```javascript
console.log(window.location.hash); // "#section1" （包含 # 符号）
```
- 如果 URL 没有 Fragment，返回空字符串 `""`
- 包含 `#` 符号

**设置**：
```javascript
window.location.hash = "section1"; // 不需要 # 符号
// 或
window.location.hash = "#section1"; // 也可以包含 #
```
- 设置时**不需要**包含 `#` 符号（但包含也可以）
- 会创建浏览器历史记录
- 会触发 `hashchange` 事件
- 会触发默认的锚点滚动行为

**浏览器兼容性**：
- 广泛支持，自 2015 年 7 月起
- IE 8+ 支持

### 4.3 hashchange 事件

**触发时机**：
- 用户点击锚点链接（`<a href="#section">`）
- JavaScript 设置 `window.location.hash`
- 用户在地址栏编辑哈希
- 浏览器后退/前进按钮导致哈希变化

**不触发的情况**：
- 使用 `history.pushState()` 改变哈希
- 使用 `history.replaceState()` 改变哈希

**事件对象**：
```javascript
window.addEventListener('hashchange', (event) => {
  console.log('Old URL:', event.oldURL);
  console.log('New URL:', event.newURL);
});
```
- `event.oldURL`：变化前的完整 URL
- `event.newURL`：变化后的完整 URL

### 4.4 hashchange vs popstate

**触发范围**：
- `hashchange`：仅 Fragment 变化
- `popstate`：任何历史条目变化

**同时触发**：
如果新旧历史条目共享同一文档但 Fragment 不同，两个事件都会触发：
1. 先触发 `hashchange`
2. 后触发 `popstate`

**History API 的影响**：
- `history.pushState()` 和 `replaceState()` 修改哈希时**不触发** `hashchange`
- 但通过 `back()`/`forward()` 返回时**会触发** `hashchange`

### 4.5 默认滚动行为

**自动滚动**：
- 浏览器会自动滚动到 `id` 匹配 Fragment 的元素
- 示例：`#section1` 滚动到 `<div id="section1">`

**阻止默认滚动**：
方法 1：使用 History API
```javascript
history.pushState(null, '', '#section1'); // 不触发滚动
```

方法 2：阻止事件
```javascript
window.addEventListener('hashchange', (event) => {
  event.preventDefault();
  // 自定义滚动行为
});
```

**浏览器差异**：
- Firefox：设置 `location.hash = location.hash` 会滚动到锚点
- Chrome/Safari：设置 `location.hash = location.hash` 被忽略

---

## 五、哈希路由在 SPA 中的应用

### 5.1 传统哈希路由

**工作原理**：
1. 路由信息存储在 URL Fragment 中
2. 监听 `hashchange` 事件
3. 解析哈希并渲染对应组件
4. 不需要服务器端配置

**示例 URL**：
```
https://example.com/#/users/123
https://example.com/#/users/123?page=2
```

**优点**：
- 简单易用，无需服务器配置
- 旧浏览器兼容性好
- 自动创建历史记录

**缺点**：
- URL 不美观（包含 `#`）
- SEO 不友好（搜索引擎可能忽略 Fragment）
- 现已被视为遗留技术

### 5.2 状态持久化

**sessionStorage 的使用**：
由于 `window.location.hash` 本身无法存储状态对象，哈希路由库通常使用 `sessionStorage`：

```javascript
// 保存状态
const key = generateUniqueKey();
sessionStorage.setItem(key, JSON.stringify(state));
window.location.hash = `#/users/123?_k=${key}`;

// 恢复状态
const key = getKeyFromHash();
const state = JSON.parse(sessionStorage.getItem(key));
```

**React Router 的 history 库实现**：
- `createHashHistory` 为每个位置创建唯一键
- 使用 `sessionStorage` 存储状态
- 允许后退/前进时恢复状态

### 5.3 哈希类型

React Router 的 `createHashHistory` 支持多种哈希格式：

**slash（默认）**：
```
https://example.com/#/users/123
```

**noslash**：
```
https://example.com/#users/123
```

**hashbang（Google 的遗留 AJAX URL 格式）**：
```
https://example.com/#!/users/123
```

---

## 六、React Router History 库的实现模式

### 6.1 三种 History 类型

#### createBrowserHistory
- **用途**：现代 Web 浏览器
- **技术**：HTML5 `pushState` 和 `replaceState`
- **URL 格式**：`https://example.com/users/123`
- **配置选项**：
  - `basename`：应用的基础 URL
  - `forceRefresh`：是否强制整页刷新
  - `keyLength`：`location.key` 的长度
  - `getUserConfirmation`：用户确认函数

#### createMemoryHistory
- **用途**：
  - 服务器端渲染
  - 自动化测试
  - 非浏览器环境
- **技术**：内存中的数组维护历史堆栈
- **特点**：
  - 不与浏览器 URL 交互
  - 完全在内存中
  - 适合 Node.js 环境
- **配置选项**：
  - `initialEntries`：初始 URL 数组
  - `initialIndex`：起始索引
  - `keyLength`：键长度

#### createHashHistory
- **用途**：遗留浏览器（不支持 HTML5 History API）
- **技术**：URL 哈希部分
- **URL 格式**：`https://example.com/#/users/123`
- **配置选项**：
  - `basename`：基础 URL
  - `hashType`：哈希类型（slash/noslash/hashbang）
  - `getUserConfirmation`：用户确认函数

### 6.2 抽象模式

**统一接口**：
所有三种 History 类型提供相同的 API：
- `history.push(path, state)`
- `history.replace(path, state)`
- `history.go(n)`
- `history.back()`
- `history.forward()`
- `history.listen(listener)`
- `history.location`
- `history.length`

**好处**：
- 在不同环境间无缝切换
- 测试时使用 Memory History
- 生产环境使用 Browser History
- 遗留环境降级到 Hash History

---

## 七、跨浏览器兼容性总结

### 7.1 History API 支持

| 特性 | Chrome | Firefox | Safari | Edge | IE |
|------|--------|---------|--------|------|-----|
| pushState/replaceState | ✓ (5+) | ✓ (4+) | ✓ (5+) | ✓ | ✓ (10+) |
| popstate 事件 | ✓ | ✓ | ✓ | ✓ | ✓ (10+) |
| scrollRestoration | ✓ (46+) | ✓ (46+) | ✓ (11+) | ✓ | ✗ |
| Structured Clone | ✓ | ✓ (6+) | ✓ | ✓ | 部分 |

**基线**：自 2015 年 7 月起，History API 在所有现代浏览器中广泛可用。

### 7.2 已知差异和解决方案

| 差异 | 浏览器 | 解决方案 |
|------|--------|----------|
| 初始页面加载触发 popstate | Safari <10, Chrome <34 | 标记首次加载并忽略 |
| scrollRestoration 顺序 | Chrome vs Firefox | 使用统一的滚动恢复逻辑 |
| State 对象大小限制 | Firefox: 640KB - 16MB | 使用 sessionStorage 存储大数据 |
| location.hash 重复设置 | Firefox vs Chrome/Safari | 避免重复设置或使用 History API |

---

## 八、实现建议

### 8.1 Memory History 实现要点

**数据结构**：
```javascript
class MemoryHistory {
  constructor(initialEntries = ['/'], initialIndex = 0) {
    this.entries = initialEntries;
    this.index = initialIndex;
    this.listeners = [];
  }

  push(path, state) {
    this.index++;
    this.entries = this.entries.slice(0, this.index);
    this.entries.push({ pathname: path, state });
    this.notify();
  }

  replace(path, state) {
    this.entries[this.index] = { pathname: path, state };
    this.notify();
  }

  go(n) {
    const nextIndex = this.index + n;
    if (nextIndex >= 0 && nextIndex < this.entries.length) {
      this.index = nextIndex;
      this.notify();
    }
  }

  notify() {
    this.listeners.forEach(listener =>
      listener(this.entries[this.index])
    );
  }
}
```

**核心功能**：
1. 维护历史条目数组
2. 维护当前索引
3. 实现 push/replace/go 导航
4. 实现监听器模式

### 8.2 Browser History 实现要点

**初始化**：
```javascript
class BrowserHistory {
  constructor(options = {}) {
    this.basename = options.basename || '';
    this.listeners = [];
    window.addEventListener('popstate', this.handlePopState);
  }

  handlePopState = (event) => {
    this.notify({
      pathname: window.location.pathname,
      search: window.location.search,
      hash: window.location.hash,
      state: event.state
    });
  }

  push(path, state) {
    const url = this.basename + path;
    history.pushState(state, '', url);
    this.notify({ pathname: path, state });
  }

  replace(path, state) {
    const url = this.basename + path;
    history.replaceState(state, '', url);
    this.notify({ pathname: path, state });
  }
}
```

**关键点**：
1. 监听 `popstate` 事件
2. 使用 `pushState`/`replaceState`
3. 处理 `basename`
4. 同步状态更新

### 8.3 Hash History 实现要点

**初始化**：
```javascript
class HashHistory {
  constructor(options = {}) {
    this.hashType = options.hashType || 'slash';
    this.listeners = [];
    window.addEventListener('hashchange', this.handleHashChange);
  }

  handleHashChange = (event) => {
    const path = this.getPathFromHash();
    const key = this.getKeyFromHash();
    const state = this.getStateFromStorage(key);
    this.notify({ pathname: path, state });
  }

  push(path, state) {
    const key = this.generateKey();
    this.saveStateToStorage(key, state);
    window.location.hash = this.formatHash(path, key);
  }

  formatHash(path, key) {
    switch (this.hashType) {
      case 'slash': return `#/${path}?_k=${key}`;
      case 'noslash': return `#${path}?_k=${key}`;
      case 'hashbang': return `#!/${path}?_k=${key}`;
    }
  }

  saveStateToStorage(key, state) {
    sessionStorage.setItem(key, JSON.stringify(state));
  }

  getStateFromStorage(key) {
    const json = sessionStorage.getItem(key);
    return json ? JSON.parse(json) : null;
  }
}
```

**关键点**：
1. 监听 `hashchange` 事件
2. 使用 `sessionStorage` 存储状态
3. 生成唯一键管理状态
4. 支持多种哈希格式

### 8.4 通用最佳实践

**1. 错误处理**：
```javascript
push(path, state) {
  try {
    history.pushState(state, '', path);
  } catch (error) {
    if (error.name === 'SecurityError') {
      console.error('pushState failed: same-origin policy violation');
    } else if (error.name === 'QuotaExceededError') {
      console.error('pushState failed: state object too large');
    }
    throw error;
  }
}
```

**2. State 对象大小管理**：
```javascript
const MAX_STATE_SIZE = 640 * 1024; // 640KB

function pushState(state, title, url) {
  const serialized = JSON.stringify(state);
  if (serialized.length > MAX_STATE_SIZE) {
    // 使用 sessionStorage
    const key = generateKey();
    sessionStorage.setItem(key, serialized);
    history.pushState({ _key: key }, title, url);
  } else {
    history.pushState(state, title, url);
  }
}
```

**3. 初始 popstate 规范化**：
```javascript
let isInitialLoad = true;

window.addEventListener('popstate', (event) => {
  if (isInitialLoad) {
    isInitialLoad = false;
    // 在某些旧浏览器中，忽略初始触发
    if (isOldBrowser()) {
      return;
    }
  }
  handleNavigation(event);
});
```

**4. 滚动恢复管理**：
```javascript
if ('scrollRestoration' in history) {
  history.scrollRestoration = 'manual';
}

// 在导航时保存滚动位置
const scrollPositions = new Map();

function saveScrollPosition() {
  const key = history.state?.key;
  if (key) {
    scrollPositions.set(key, {
      x: window.scrollX,
      y: window.scrollY
    });
  }
}

function restoreScrollPosition() {
  const key = history.state?.key;
  const position = scrollPositions.get(key);
  if (position) {
    window.scrollTo(position.x, position.y);
  }
}
```

---

## 九、关键发现总结

### 9.1 核心要点

1. **pushState/replaceState 不触发 popstate**
   - 只有 back/forward/go 触发
   - 这是设计行为，不是 bug

2. **State 对象有大小限制**
   - Firefox: 640KB - 16MB
   - 超大数据应使用 sessionStorage

3. **同源策略严格执行**
   - pushState 的 URL 必须同源
   - 违反会抛出 SecurityError

4. **初始 popstate 触发不一致**
   - 旧版浏览器有差异
   - 现代浏览器已统一（不触发）

5. **scrollRestoration 时机差异**
   - Chrome: popstate → scroll
   - Firefox: scroll → popstate

6. **hashchange 与 History API 的关系**
   - pushState/replaceState 不触发 hashchange
   - back/forward 可能同时触发两者

7. **哈希路由需要 sessionStorage**
   - location.hash 本身不存储状态
   - 使用唯一键 + sessionStorage 模拟

### 9.2 Flutter unrouter 实现建议

基于以上调查，对 unrouter 项目的建议：

1. **createMemoryHistory**：
   - 优先实现，作为基础
   - 纯 Dart 实现，无需平台 API
   - 用于 Native App 和测试

2. **createBrowserHistory**：
   - Web 平台检测 History API 支持
   - 使用 `dart:js` 与浏览器 History API 交互
   - App 平台回退到 MemoryHistory

3. **createFragmentHistory**：
   - Web 平台使用哈希导航
   - 需要实现 sessionStorage 包装
   - App 平台回退到 MemoryHistory

4. **统一抽象**：
   - 定义 `History` 接口
   - 三种实现共享相同 API
   - 方便测试和切换

---

## 十、参考资源

### 官方文档
- [Working with the History API - MDN](https://developer.mozilla.org/en-US/docs/Web/API/History_API/Working_with_the_History_API)
- [History: pushState() method - MDN](https://developer.mozilla.org/en-US/docs/Web/API/History/pushState)
- [History API - MDN](https://developer.mozilla.org/en-US/docs/Web/API/History_API)
- [Window: popstate event - MDN](https://developer.mozilla.org/en-US/docs/Web/API/Window/popstate_event)
- [Window: hashchange event - MDN](https://developer.mozilla.org/en-US/docs/Web/API/Window/hashchange_event)
- [Location: hash property - MDN](https://developer.mozilla.org/en-US/docs/Web/API/Location/hash)
- [History: scrollRestoration property - MDN](https://developer.mozilla.org/en-US/docs/Web/API/History/scrollRestoration)

### 博客和文章
- [History API - Scroll restoration - Chrome Developers](https://developer.chrome.com/blog/history-api-scroll-restoration)
- [Using Hashed vs. Non-Hashed URL Paths in Single Page Apps - Bits and Pieces](https://blog.bitsrc.io/using-hashed-vs-nonhashed-url-paths-in-single-page-apps-a66234cefc96)
- [pushState and URL Blocking - text/plain](https://textslashplain.com/2024/03/20/pushstate-and-url-blocking/)

### 技术规范
- [WHATWG HTML Standard - History](https://html.spec.whatwg.org/multipage/history.html)
- [Same-origin policy - MDN](https://developer.mozilla.org/en-US/docs/Web/Security/Same-origin_policy)

### 开源项目
- [React Router History](https://github.com/remix-run/history)
- [TanStack Router - History Types](https://tanstack.com/router/latest/docs/framework/react/guide/history-types)

### GitHub Issues 和讨论
- [Normalize browsers that fire a popstate event on load - Pull Request #520](https://github.com/ReactTraining/history/pull/520)
- [State object size limitation in Firefox - Issue #144](https://github.com/inertiajs/inertia/issues/144)
- [popstate/hashchange dispatching doesn't match what browsers do - Issue #1792](https://github.com/whatwg/html/issues/1792)

---

**调查完成日期**：2025-12-15

**下一步**：基于本调查报告，开始实现 unrouter 的 History 功能。
