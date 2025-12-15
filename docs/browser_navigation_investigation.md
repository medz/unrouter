# 浏览器导航和历史行为调查计划

## 概述

本文档旨在详细调查和记录浏览器的导航和历史行为，为 unrouter 项目中的 History 实现提供技术基础。

## 调查目标

1. 深入理解浏览器 History API 的工作原理
2. 了解不同类型的导航行为（pushState、replaceState、back、forward）
3. 研究 URL Fragment（锚点）导航的特殊行为
4. 分析事件监听机制（popstate、hashchange）
5. 探索跨浏览器兼容性问题

## 调查范围

### 1. History API 核心功能

#### 1.1 基础 API
- `window.history.length` - 历史记录堆栈大小
- `window.history.state` - 当前状态对象
- `window.history.scrollRestoration` - 滚动恢复行为

#### 1.2 导航方法
- `history.back()` - 后退
- `history.forward()` - 前进
- `history.go(n)` - 跳转到指定位置
- `history.pushState(state, title, url)` - 添加新历史记录
- `history.replaceState(state, title, url)` - 替换当前历史记录

### 2. 浏览器导航行为

#### 2.1 pushState 行为
- 如何添加新的历史记录项
- URL 变化但不触发页面刷新
- state 对象的存储和限制
- 相对 URL vs 绝对 URL
- 同源策略限制

#### 2.2 replaceState 行为
- 替换当前历史记录而不增加堆栈
- 使用场景和最佳实践
- 与 pushState 的区别

#### 2.3 back/forward/go 行为
- 导航堆栈的遍历
- 触发的事件
- 用户手动点击浏览器按钮 vs 程序调用

### 3. URL Fragment 导航

#### 3.1 Fragment 基础
- Fragment 的定义（URL 中的 `#` 部分）
- Fragment 不会触发页面重载
- Fragment 变化的历史记录行为

#### 3.2 hashchange 事件
- 何时触发
- 事件对象属性（oldURL、newURL）
- 与 popstate 事件的关系

#### 3.3 Fragment 导航特性
- 默认的锚点滚动行为
- 阻止默认滚动的方法
- Fragment 与 History API 的配合使用

### 4. 事件监听机制

#### 4.1 popstate 事件
- 触发时机（back、forward、go）
- 不触发的情况（pushState、replaceState）
- event.state 的使用
- 初始加载时的行为差异

#### 4.2 hashchange 事件
- 专门用于 Fragment 变化
- 与 popstate 的区别和联系
- 事件触发顺序

#### 4.3 beforeunload 事件
- 页面卸载前的拦截
- 用户离开页面的确认

### 5. 状态管理

#### 5.1 State 对象
- 数据结构和大小限制（通常 640KB）
- 序列化要求（结构化克隆算法）
- 不支持的数据类型（函数、DOM 节点等）

#### 5.2 State 持久化
- 浏览器如何存储 state
- 刷新页面后的 state 保留
- 标签页关闭后的行为

### 6. 跨浏览器兼容性

#### 6.1 主流浏览器支持
- Chrome/Edge（Chromium）
- Firefox
- Safari
- 移动端浏览器

#### 6.2 已知差异
- 初始 popstate 事件触发差异
- scrollRestoration 支持情况
- state 对象大小限制
- URL 长度限制

### 7. 实现注意事项

#### 7.1 Memory History 模拟
- 如何在没有浏览器 API 的环境中模拟
- 需要实现的核心功能
- 状态堆栈的数据结构

#### 7.2 Browser History 实现
- 直接使用 History API
- 事件监听和同步
- 错误处理

#### 7.3 Fragment History 实现
- 使用 Fragment 存储路由信息
- 解析和序列化 Fragment
- hashchange 事件处理

## 调查方法

1. **文档研究**
   - MDN Web Docs
   - W3C 规范
   - WHATWG 标准

2. **实验验证**
   - 创建测试 HTML 页面
   - 不同浏览器中的行为测试
   - 边界情况验证

3. **源码参考**
   - React Router 的 history 库
   - Vue Router 的实现
   - 其他成熟路由库

## 预期输出

1. 详细的技术调查报告
2. 浏览器行为对比表
3. 实现建议和最佳实践
4. 测试用例和示例代码

## 时间线

- 第一阶段：History API 核心功能调查
- 第二阶段：导航行为深入研究
- 第三阶段：Fragment 导航特性调查
- 第四阶段：总结和文档完善

## 参考资源

- [MDN - History API](https://developer.mozilla.org/en-US/docs/Web/API/History_API)
- [WHATWG HTML Standard - History](https://html.spec.whatwg.org/multipage/history.html)
- [React Router History](https://github.com/remix-run/history)
- [Vue Router](https://github.com/vuejs/router)
