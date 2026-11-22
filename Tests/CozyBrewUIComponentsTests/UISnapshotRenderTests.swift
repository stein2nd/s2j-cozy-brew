import AppKit
import CozyBrewService
import CozyBrewUIComponents
import SwiftUI
import XCTest

/// SwiftUI ビューのレンダリング・UI スナップショット風検証 (CI: `swift test`)
@MainActor
final class UISnapshotRenderTests: XCTestCase {
    func testPackageRowViewRendersBitmap() {
        let package = Package.catalogStub(name: "wget", type: .formula)
        let view = PackageRowView(
            package: package,
            onInstall: {}
        )
        .frame(width: 520, height: 72)

        XCTAssertNotNil(bitmap(from: view))
    }

    func testInstallFlowViewRendersBitmap() {
        let package = Package.catalogStub(name: "wget", type: .formula)
        let view = InstallFlowView(
            package: package,
            onConfirm: {},
            onCancel: {}
        )
        .frame(width: 440, height: 240)

        let image = bitmap(from: view)
        XCTAssertNotNil(image)
        XCTAssertGreaterThan(image?.pixelsWide ?? 0, 100)
    }

    func testMainWindowViewRendersWithManager() {
        let manager = BrewManager()
        let view = MainWindowView(manager: manager)
            .frame(width: 900, height: 600)

        XCTAssertGreaterThan(hostingFittingSize(of: view).width, 400)
    }

    private func hostingFittingSize(of view: some View) -> CGSize {
        let hosting = NSHostingView(rootView: view)
        hosting.layoutSubtreeIfNeeded()
        return hosting.fittingSize
    }

    private func bitmap(from view: some View) -> NSBitmapImageRep? {
        let hosting = NSHostingView(rootView: view)
        hosting.frame = CGRect(origin: .zero, size: hostingFittingSize(of: view))
        hosting.layoutSubtreeIfNeeded()
        guard let rep = hosting.bitmapImageRepForCachingDisplay(in: hosting.bounds) else {
            return nil
        }
        hosting.cacheDisplay(in: hosting.bounds, to: rep)
        return rep
    }
}
