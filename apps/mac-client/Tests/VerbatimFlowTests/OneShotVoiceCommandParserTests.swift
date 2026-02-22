import XCTest
@testable import VerbatimFlow

final class OneShotVoiceCommandParserTests: XCTestCase {
    func testNoCommandKeepsDefaultModeAndText() {
        let result = OneShotVoiceCommandParser.parse(raw: "  我们今天继续测稳定性  ", defaultMode: .raw)
        XCTAssertEqual(result.effectiveMode, .raw)
        XCTAssertEqual(result.content, "我们今天继续测稳定性")
        XCTAssertNil(result.matchedCommand)
    }

    func testWrittenStyleCommandOverridesCurrentSegmentToClarify() {
        let result = OneShotVoiceCommandParser.parse(
            raw: "把以上的话语整理成书面语：今天我们开会讨论发布计划",
            defaultMode: .raw
        )
        XCTAssertEqual(result.effectiveMode, .clarify)
        XCTAssertEqual(result.content, "今天我们开会讨论发布计划")
        XCTAssertEqual(result.matchedCommand, "整理成书面语")
    }

    func testClarifyCommandOverridesCurrentSegment() {
        let result = OneShotVoiceCommandParser.parse(
            raw: "请帮我润色一下，今天的复盘先到这里",
            defaultMode: .raw
        )
        XCTAssertEqual(result.effectiveMode, .clarify)
        XCTAssertEqual(result.content, "今天的复盘先到这里")
        XCTAssertEqual(result.matchedCommand, "整理成书面语")
    }

    func testCommandOnlyReturnsEmptyContent() {
        let result = OneShotVoiceCommandParser.parse(raw: "整理成书面语", defaultMode: .raw)
        XCTAssertEqual(result.effectiveMode, .clarify)
        XCTAssertEqual(result.content, "")
        XCTAssertEqual(result.matchedCommand, "整理成书面语")
    }

    func testNonPrefixPhraseDoesNotTriggerCommand() {
        let result = OneShotVoiceCommandParser.parse(raw: "我们之后再整理成书面语", defaultMode: .raw)
        XCTAssertEqual(result.effectiveMode, .raw)
        XCTAssertEqual(result.content, "我们之后再整理成书面语")
        XCTAssertNil(result.matchedCommand)
    }

    func testRealWorldPrefixWithChinesePeriodTriggersCommand() {
        let result = OneShotVoiceCommandParser.parse(
            raw: "整理成书面语。那今天呢我完成了语音输入功能。",
            defaultMode: .raw
        )
        XCTAssertEqual(result.effectiveMode, .clarify)
        XCTAssertEqual(result.content, "那今天呢我完成了语音输入功能。")
        XCTAssertEqual(result.matchedCommand, "整理成书面语")
    }

    func testFormatOnlyCommandUsesFormatOnlyMode() {
        let result = OneShotVoiceCommandParser.parse(
            raw: "仅格式化：Hello ,world !",
            defaultMode: .raw
        )
        XCTAssertEqual(result.effectiveMode, .formatOnly)
        XCTAssertEqual(result.content, "Hello ,world !")
        XCTAssertEqual(result.matchedCommand, "格式化输出")
    }
}
