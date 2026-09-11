import Flutter
import StoreKit

/// Reports the introductory offer the App Store is actually serving.
///
/// AppActor's package model carries the recurring price and nothing else, so a
/// paywall that spells out its own trial terms is really just repeating what
/// someone typed into App Store Connect months ago. Change the offer there and
/// the copy silently becomes a lie -- and a price written as "$0.99" was
/// already a lie in the other 170 territories. Asking StoreKit costs one round
/// trip and keeps the two in step on their own.
enum IntroOfferBridge {
  private static let channelName = "antique/intro_offer"

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: registrar.messenger()
    )

    channel.setMethodCallHandler { call, result in
      guard call.method == "fetch" else {
        result(FlutterMethodNotImplemented)
        return
      }

      guard
        let arguments = call.arguments as? [String: Any],
        let productIds = arguments["productIds"] as? [String],
        !productIds.isEmpty
      else {
        result(FlutterError(code: "bad_arguments",
                            message: "productIds must be a non-empty list",
                            details: nil))
        return
      }

      guard #available(iOS 15.0, *) else {
        // The caller reads an empty map as "no offer known" and falls back to
        // copy that promises nothing, which is the safe thing to show.
        result([String: Any]())
        return
      }

      Task {
        do {
          let products = try await Product.products(for: productIds)
          var payload: [String: Any] = [:]
          for product in products {
            guard let offer = product.subscription?.introductoryOffer else { continue }
            payload[product.id] = describe(offer)
          }
          result(payload)
        } catch {
          result(FlutterError(code: "storekit_unavailable",
                              message: error.localizedDescription,
                              details: nil))
        }
      }
    }
  }

  @available(iOS 15.0, *)
  private static func describe(_ offer: Product.SubscriptionOffer) -> [String: Any] {
    return [
      "mode": paymentMode(offer.paymentMode),
      "displayPrice": offer.displayPrice,
      "periodUnit": periodUnit(offer.period.unit),
      "periodValue": offer.period.value,
      "periodCount": offer.periodCount,
    ]
  }

  @available(iOS 15.0, *)
  private static func paymentMode(_ mode: Product.SubscriptionOffer.PaymentMode) -> String {
    switch mode {
    case .freeTrial: return "free_trial"
    case .payUpFront: return "pay_up_front"
    case .payAsYouGo: return "pay_as_you_go"
    default: return "unknown"
    }
  }

  @available(iOS 15.0, *)
  private static func periodUnit(_ unit: Product.SubscriptionPeriod.Unit) -> String {
    switch unit {
    case .day: return "day"
    case .week: return "week"
    case .month: return "month"
    case .year: return "year"
    @unknown default: return "unknown"
    }
  }
}
