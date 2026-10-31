import SwiftUI

struct DefaultAppCommands: Commands {
    let flow: DefaultAppFlow

    var body: some Commands {
        CommandGroup(after: .appInfo) {
            Button("Establecer como visor Markdown predeterminado…") {
                Task { await flow.setAsDefaultFromMenu() }
            }
        }
    }
}
