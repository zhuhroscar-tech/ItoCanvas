[![English](https://img.shields.io/badge/English-555555?style=flat)](README.md) [![简体中文](https://img.shields.io/badge/简体中文-555555?style=flat)](README.zh-CN.md)

# ItoCanvas

原生、离线的 macOS 期权分析应用，用于理解定价与风险。ItoCanvas 在同一个 SwiftUI 工作区中提供欧式期权定价、Greeks、隐含波动率、多腿策略和现货价格／波动率情景分析，面向学习与研究，不用于执行交易。

![期权分析工作区](Assets/README/overview.png)

## 可以做什么

- 使用 Black–Scholes–Merton 和连续股息率为欧式 call、put 定价。
- 查看 delta、gamma、vega、theta、rho，并在无套利边界校验后求解隐含波动率。
- 在 Scenario Lab 中查看现货价格 × 波动率热力图。
- 使用预设策略或自定义 legs 绘制到期收益图。
- 在本地保存工作区并导出 CSV。

[Scenario Lab 截图](Assets/README/scenarios.png) · [演示视频](Docs/demo.mp4)

## 安装

需要 **macOS 14 Sonoma 或更新版本**。从 [GitHub Releases](https://github.com/zhuhroscar-tech/ItoCanvas/releases/latest) 下载 DMG，打开后将 **ItoCanvas** 拖入 **Applications**。

开发版打包使用 ad-hoc 签名，未采用 Developer ID 签名和 notarization。macOS 可能提示风险或阻止启动；请先确认源码与 release 来源，再决定是否运行。不要为打开应用而关闭系统级安全保护。

## 构建与测试

需要 Xcode 26，或其他提供 **Swift 6.2+** 的 toolchain：

```bash
git clone https://github.com/zhuhroscar-tech/ItoCanvas.git
cd ItoCanvas
swift test
./Scripts/build_app.sh
./Scripts/create_dmg.sh
```

脚本将应用和 DMG 写入 `dist/`。量化计算位于 `Sources/ItoCanvasCore`；SwiftUI 界面、持久化和导出逻辑位于 `Sources/ItoCanvas`。

## 模型约定与限制

利率和波动率以年化百分比输入。无风险利率与股息率采用连续复利；vega 和 rho 按一个百分点的变化显示，theta 按一个日历日显示。

模型假设欧式行权，并采用波动率和利率恒定的 Black–Scholes–Merton 对数正态过程。不处理提前行权、离散股息、volatility smile 或 skew、跳跃过程及随机利率。策略图基于输入的权利金展示到期收益，不表示到期前的 mark-to-market P&L。结果是分析估值，不是可执行的市场报价，也不构成投资建议。

公式与 solver 说明见[模型说明](Docs/MODEL_NOTES.md)，工作区设计见[产品文档](Docs/PRODUCT.md)。

## 隐私与许可证

无需账户或网络连接，用户数据保留在本机。详见[隐私说明](PRIVACY.md)、[安全说明](SECURITY.md)和 [MIT 许可证](LICENSE)。
