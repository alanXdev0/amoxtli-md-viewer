import SwiftUI

struct LinkCommands: Commands {
    var body: some Commands {
        CommandGroup(after: .appInfo) {
            Button("Olvidar sitios de confianza") {
                TrustedHostsStore().removeAll()
            }
        }
    }
}
