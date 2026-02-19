import Foundation

enum PermissionState: String {
    case notDetermined = "Not Determined"
    case authorized = "Authorized"
    case denied = "Denied"
    case restricted = "Restricted"
    case unsupported = "Unsupported"
}

struct PermissionSnapshot {
    let speech: PermissionState
    let microphone: PermissionState
    let accessibilityTrusted: Bool
    let speechRequired: Bool

    var summaryLine: String {
        let accessibility = accessibilityTrusted ? "Authorized" : "Denied"
        let speechLabel = speechRequired ? speech.rawValue : "\(speech.rawValue) (Optional)"
        return "Mic: \(microphone.rawValue) | Speech: \(speechLabel) | Accessibility: \(accessibility)"
    }

    var isReadyForHotkeyDictation: Bool {
        let speechReady = !speechRequired || speech == .authorized
        return speechReady && microphone == .authorized && accessibilityTrusted
    }
}
