import Flutter
import UIKit

/// Flutterのコンテンツの上に、iOSネイティブの UITabBar を重ねて表示するルートVC。
/// iOS 26 SDKでビルドすると、標準の UITabBar は自動でLiquid Glass素材になる。
@objc(RootFlutterViewController)
final class RootFlutterViewController: FlutterViewController {
  private static let channelName = "com.stockmemo.app/native_tab_bar"

  private struct TabSpec {
    let title: String
    let icon: String
    let selectedIcon: String
  }

  private let tabs: [TabSpec] = [
    TabSpec(title: "在庫を確認", icon: "shippingbox", selectedIcon: "shippingbox.fill"),
    TabSpec(title: "残りわずか", icon: "exclamationmark.triangle", selectedIcon: "exclamationmark.triangle.fill"),
    TabSpec(title: "在庫切れ", icon: "xmark.bin", selectedIcon: "xmark.bin.fill"),
    TabSpec(title: "買い物リスト", icon: "cart", selectedIcon: "cart.fill"),
    TabSpec(title: "設定", icon: "gearshape", selectedIcon: "gearshape.fill"),
  ]

  private let tabBar = UITabBar()
  private var methodChannel: FlutterMethodChannel?

  override func viewDidLoad() {
    super.viewDidLoad()
    setUpTabBar()
    setUpMethodChannel()
  }

  private func setUpTabBar() {
    tabBar.translatesAutoresizingMaskIntoConstraints = false
    tabBar.delegate = self
    let labelFont = UIFont(name: "ZenMaruGothic-Regular", size: 10) ?? UIFont.systemFont(ofSize: 10)
    tabBar.items = tabs.map { spec in
      let item = UITabBarItem(
        title: spec.title,
        image: UIImage(systemName: spec.icon),
        selectedImage: UIImage(systemName: spec.selectedIcon)
      )
      item.setTitleTextAttributes([.font: labelFont], for: .normal)
      item.setTitleTextAttributes([.font: labelFont], for: .selected)
      return item
    }
    tabBar.selectedItem = tabBar.items?.first

    view.addSubview(tabBar)
    NSLayoutConstraint.activate([
      tabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  private func setUpMethodChannel() {
    let channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: binaryMessenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self, call.method == "updateBadges" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self.updateBadges(with: call.arguments as? [String: Any] ?? [:])
      result(nil)
    }
    methodChannel = channel
  }

  private func updateBadges(with data: [String: Any]) {
    guard let items = tabBar.items else { return }

    func badgeText(forCount count: Any?) -> String? {
      guard let count = count as? Int, count > 0 else { return nil }
      return "\(count)"
    }

    if items.count > 1 {
      items[1].badgeValue = badgeText(forCount: data["low"])
    }
    if items.count > 2 {
      items[2].badgeValue = badgeText(forCount: data["empty"])
    }
    if items.count > 4 {
      items[4].badgeValue = (data["hasUnread"] as? Bool == true) ? "!" : nil
    }
  }
}

extension RootFlutterViewController: UITabBarDelegate {
  func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
    let index = tabBar.items?.firstIndex(of: item) ?? 0
    methodChannel?.invokeMethod("tabSelected", arguments: ["index": index])
  }
}
