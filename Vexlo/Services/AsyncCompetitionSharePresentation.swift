import Foundation

/// Daily share invite copy for off-platform async competition (Competition 5C.1).
/// Read-only presentation; does not call Game Center or mutate run/daily state.
struct AsyncCompetitionShareContent: Equatable {
    let subject: String
    let inviteLine: String
    let inviteURL: URL
}

enum AsyncCompetitionSharePresentation {
    static let dailyInviteURL = URL(string: "vexlo://daily")!

    static func dailyShareContent(for payload: ResultSharePayload) -> AsyncCompetitionShareContent? {
        guard payload.mode == .daily else { return nil }
        let subject: String
        if let headline = payload.dailyRitualHeadline, !headline.isEmpty {
            subject = VexloStrings.AsyncCompetition.dailyShareSubject(headline: headline)
        } else {
            subject = VexloStrings.AsyncCompetition.dailyShareSubjectDefault
        }
        return AsyncCompetitionShareContent(
            subject: subject,
            inviteLine: VexloStrings.AsyncCompetition.dailyShareInviteLine,
            inviteURL: dailyInviteURL
        )
    }
}
