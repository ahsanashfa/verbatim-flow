import Foundation

struct OneShotVoiceCommandResult {
    let effectiveMode: OutputMode
    let content: String
    let matchedCommand: String?
}

enum OneShotVoiceCommandParser {
    private struct Rule {
        let mode: OutputMode
        let label: String
        let regex: NSRegularExpression
    }

    private static let rules: [Rule] = [
        Rule(
            mode: .formatOnly,
            label: "格式化输出",
            regex: compile(
                pattern: #"^\s*(?:请\s*)?(?:帮我\s*)?(?:把\s*)?(?:以上|以下|这段|这句话|这段话)?\s*(?:的)?\s*(?:话|话语|内容|文本|文字)?\s*(?:格式化输出|仅格式化|只做格式整理|format[\s-]*only|format\s*this)(?=$|[\s,:：，,。！？!?-])"#
            )
        ),
        Rule(
            mode: .clarify,
            label: "整理成书面语",
            regex: compile(
                pattern: #"^\s*(?:请\s*)?(?:帮我\s*)?(?:把\s*)?(?:以上|以下|这段|这句话|这段话)?\s*(?:的)?\s*(?:话|话语|内容|文本|文字)?\s*(?:整理成书面语|改成书面语|转成书面语|整理为书面语|润色一下|整理一下|优化一下|帮我润色|clarify\s*mode|clarify\s*this|rewrite\s*formally|formalize\s*this)(?=$|[\s,:：，,。！？!?-])"#
            )
        ),
        Rule(
            mode: .raw,
            label: "原样输出",
            regex: compile(
                pattern: #"^\s*(?:请\s*)?(?:帮我\s*)?(?:把\s*)?(?:以上|以下|这段|这句话|这段话)?\s*(?:的)?\s*(?:话|话语|内容|文本|文字)?\s*(?:原样输出|保持原样|不要润色|raw\s*mode|raw)(?=$|[\s,:：，,。！？!?-])"#
            )
        )
    ]

    static func parse(raw: String, defaultMode: OutputMode) -> OneShotVoiceCommandResult {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return OneShotVoiceCommandResult(effectiveMode: defaultMode, content: "", matchedCommand: nil)
        }

        let fullRange = NSRange(trimmed.startIndex..<trimmed.endIndex, in: trimmed)

        for rule in rules {
            guard let match = rule.regex.firstMatch(in: trimmed, options: [], range: fullRange),
                  let matchedRange = Range(match.range, in: trimmed)
            else {
                continue
            }

            let suffix = String(trimmed[matchedRange.upperBound...])
            let cleanedContent = stripLeadingSeparators(from: suffix)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            return OneShotVoiceCommandResult(
                effectiveMode: rule.mode,
                content: cleanedContent,
                matchedCommand: rule.label
            )
        }

        if let fallback = parseFallbackLeadingClause(from: trimmed, defaultMode: defaultMode) {
            return fallback
        }

        return OneShotVoiceCommandResult(effectiveMode: defaultMode, content: trimmed, matchedCommand: nil)
    }

    private static func stripLeadingSeparators(from text: String) -> String {
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let stripped = leadingSeparatorsRegex.stringByReplacingMatches(
            in: text,
            options: [],
            range: range,
            withTemplate: ""
        )
        return stripped
    }

    private static let leadingSeparatorsRegex = compile(pattern: #"^[\s,:：，,。！？!?;；-]+"#)

    private static func parseFallbackLeadingClause(
        from text: String,
        defaultMode: OutputMode
    ) -> OneShotVoiceCommandResult? {
        let separators = CharacterSet(charactersIn: "。！？!?，,：:;； \t\n")
        let splitIndex = text.unicodeScalars.firstIndex { separators.contains($0) }
        let head: String
        let tail: String
        if let splitIndex,
           let charIndex = splitIndex.samePosition(in: text) {
            head = String(text[..<charIndex])
            tail = String(text[text.index(after: charIndex)...])
        } else {
            head = text
            tail = ""
        }

        guard !head.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        if matchesAnyPrefixCommand(in: head, commands: clarifyFallbackKeywords) {
            return OneShotVoiceCommandResult(
                effectiveMode: .clarify,
                content: stripLeadingSeparators(from: tail).trimmingCharacters(in: .whitespacesAndNewlines),
                matchedCommand: "整理成书面语"
            )
        }
        if matchesAnyPrefixCommand(in: head, commands: formatFallbackKeywords) {
            return OneShotVoiceCommandResult(
                effectiveMode: .formatOnly,
                content: stripLeadingSeparators(from: tail).trimmingCharacters(in: .whitespacesAndNewlines),
                matchedCommand: "格式化输出"
            )
        }
        if matchesAnyPrefixCommand(in: head, commands: rawFallbackKeywords) {
            return OneShotVoiceCommandResult(
                effectiveMode: .raw,
                content: stripLeadingSeparators(from: tail).trimmingCharacters(in: .whitespacesAndNewlines),
                matchedCommand: "原样输出"
            )
        }

        return nil
    }

    private static let clarifyFallbackKeywords = [
        "整理成书面语",
        "改成书面语",
        "转成书面语",
        "整理为书面语",
        "润色一下",
        "整理一下",
        "优化一下",
        "帮我润色"
    ]

    private static let formatFallbackKeywords = [
        "格式化输出",
        "仅格式化",
        "只做格式整理"
    ]

    private static let rawFallbackKeywords = [
        "原样输出",
        "保持原样",
        "不要润色"
    ]

    private static let allowedPrefixFragments = [
        "",
        "请",
        "帮我",
        "请帮我",
        "把",
        "把以上",
        "把以下",
        "把这段",
        "把这句话",
        "把这段话",
        "以上",
        "以下",
        "这段",
        "这句话",
        "这段话",
        "把以上的话语",
        "把以下的话语",
        "把这段话语",
        "这段话语",
        "以上的话语",
        "以下的话语"
    ].map { normalizeCommandClause($0) }

    private static func matchesAnyPrefixCommand(in head: String, commands: [String]) -> Bool {
        commands.contains { matchesPrefixCommand(in: head, command: $0) }
    }

    private static func matchesPrefixCommand(in head: String, command: String) -> Bool {
        let normalizedHead = normalizeCommandClause(head)
        let normalizedCommand = normalizeCommandClause(command)
        guard !normalizedHead.isEmpty, !normalizedCommand.isEmpty else {
            return false
        }

        guard let range = normalizedHead.range(of: normalizedCommand) else {
            return false
        }

        let prefix = String(normalizedHead[..<range.lowerBound])
        guard allowedPrefixFragments.contains(prefix) else {
            return false
        }

        let suffix = String(normalizedHead[range.upperBound...])
        // Command clause should not carry arbitrary sentence body.
        return suffix.isEmpty || suffix == "的话" || suffix == "话语" || suffix == "内容" || suffix == "文本" || suffix == "文字"
    }

    private static func normalizeCommandClause(_ text: String) -> String {
        let normalized = text.precomposedStringWithCanonicalMapping
        let invisible = CharacterSet(charactersIn: "\u{200B}\u{200C}\u{200D}\u{2060}\u{FEFF}\u{3000}")
        let removeSet = CharacterSet.whitespacesAndNewlines
            .union(.punctuationCharacters)
            .union(.symbols)
            .union(invisible)

        let scalars = normalized.unicodeScalars.filter { !removeSet.contains($0) }
        return String(String.UnicodeScalarView(scalars)).lowercased()
    }

    private static func compile(pattern: String) -> NSRegularExpression {
        // Patterns are static constants controlled in source.
        return try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
    }
}
