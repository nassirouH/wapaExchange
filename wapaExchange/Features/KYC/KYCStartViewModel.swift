import Foundation

@MainActor
@Observable
final class KYCStartViewModel {
    enum Step: Equatable {
        case intro
        case launching
        case sdkRunning
        case polling
        case done(KYCStatus)
        case error(String)
    }

    var step: Step = .intro
    var session: KYCSession?

    private let kyc: KYCServicing

    init(kyc: KYCServicing? = nil) {
        self.kyc = kyc ?? KYCService.shared
    }

    func start() async {
        step = .launching
        do {
            // 1. Backend creates / reuses a Sumsub applicant + mints a 30-min SDK access token.
            let session = try await kyc.startSession()
            self.session = session

            // 2. Hand the token to the Sumsub Mobile SDK — it takes over the screen
            //    (document picker, OCR, liveness, selfie). Result reported on dismiss.
            step = .sdkRunning
            let outcome = await SumsubKYC.present(sdkToken: session.sdkToken)
            switch outcome {
            case .completed:
                break
            case .canceled:
                step = .intro
                return
            case .failed(let message):
                step = .error(message)
                return
            }

            // 3. Sumsub runs AML / sanctions / document validity checks server-side and
            //    posts the verdict to /v1/webhooks/kyc/sumsub. Poll our own status
            //    endpoint until we see a terminal state (or timeout — KYC review can
            //    take from seconds for auto-decisions up to hours for manual review).
            step = .polling
            let final = await pollUntilTerminal(maxSeconds: 60)
            step = .done(final)
        } catch {
            step = .error((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
        }
    }

    private func pollUntilTerminal(maxSeconds: Int, intervalSeconds: Int = 2) async -> KYCStatus {
        let deadline = Date().addingTimeInterval(TimeInterval(maxSeconds))
        while Date() < deadline {
            if Task.isCancelled { return .pending }
            if let status = try? await kyc.status() {
                if status == .approved || status == .rejected { return status }
            }
            try? await Task.sleep(nanoseconds: UInt64(intervalSeconds) * 1_000_000_000)
        }
        return .pending
    }
}
