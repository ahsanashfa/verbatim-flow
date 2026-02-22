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
            label: "整理成书面语",
            regex: compile(
                pattern: #"^\s*(?:请\s*)?(?:帮我\s*)?(?:把\s*)?(?:以上|以下|这段|这句话|这段话)?\s*(?:的)?\s*(?:话|话语|内容|文本|文字)?\s*(?:整理成书面语|改成书面语|转成书面语|整理为书面语|格式化输出|format\s*only|formalize\s*this|rewrite\s*formally)(?=$|[\s,:：，,。！？!?-])"#
            )
        ),
        Rule(
            mode: .clarify,
            label: "润色/整理一下",
            regex: compile(
                pattern: #"^\s*(?:请\s*)?(?:帮我\s*)?(?:把\s*)?(?:以上|以下|这段|这句话|这段话)?\s*(?:的)?\s*(?:话|话语|内容|文本|文字)?\s*(?:润色一下|整理一下|优化一下|帮我润色|clarify\s*mode|clarify\s*this)(?=$|[\s,:：，,。！？!?-])"#
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

    private static func compile(pattern: String) -> NSRegularExpression {
        // Patterns are static constants controlled in source.
        return try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
    }
}
