# ItoCanvas 1.0.1

ItoCanvas 1.0.1 is a defensive reliability update for locally persisted workspaces.

## Fixed

- Scenario-grid resolution restored from local preferences is normalized to a supported odd value between 5 and 15 before the Scenario Lab allocates its axes.
- Corrupted or legacy preferences can no longer request an effectively unbounded scenario matrix.
- App-level persistence regression coverage now runs in SwiftPM and GitHub Actions.

## Verification

- 13 Swift tests pass, including a failing-first corrupted-preferences regression test.
- Independent fail-closed review found no remaining security concerns or logic errors.
- The release app and DMG were rebuilt and signature-verified.

## Distribution note

The downloadable development build is ad-hoc signed for local testing. Commercial distribution still requires an Apple Developer ID Application certificate and Apple notarization.