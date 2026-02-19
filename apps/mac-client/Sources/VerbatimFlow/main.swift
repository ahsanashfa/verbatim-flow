import AppKit
import Foundation

do {
    let config = try CLIConfig.parse()
    let app = NSApplication.shared

    Task { @MainActor in
        let delegate = MenuBarApp(config: config)
        app.delegate = delegate
        withExtendedLifetime(delegate) {
            app.run()
        }
    }

    RunLoop.main.run()
} catch {
    fputs("\(error)\n", stderr)
    HelpPrinter.printAndExit()
}
