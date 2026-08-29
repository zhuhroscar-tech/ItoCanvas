import XCTest
@testable import ItoCanvas

final class AppModelPersistenceTests: XCTestCase {
    @MainActor
    func testCorruptPersistedScenarioResolutionIsClampedBeforeUse() throws {
        let suiteName = "ItoCanvasTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        var corrupted = WorkspaceState()
        corrupted.scenarios.steps = Int.max
        let encoded = try JSONEncoder().encode(corrupted)
        defaults.set(encoded, forKey: "ItoCanvas.workspace.v1")

        let model = AppModel(defaults: defaults)

        XCTAssertEqual(model.workspace.scenarios.steps, 15)
    }
}