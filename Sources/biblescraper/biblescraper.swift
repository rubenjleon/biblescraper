import Foundation
import SwiftSoup

@main
struct BibleScraper {
    static func main() async {
        do {
            let html = try await fetchHTML(
                from: "https://www.biblegateway.com/reading-plans/verse-of-the-day/today?version=NASB1995"
            )
            let output = try extractPassages(from: html)
            print("\n\(output)\n")
        } catch {
            FileHandle.standardError.write(Data("Error: \(error)\n".utf8))
            exit(1)
        }
    }

    static func fetchHTML(from urlString: String) async throws -> String {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh)", forHTTPHeaderField: "User-Agent")
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let html = String(data: data, encoding: .utf8) else {
            throw URLError(.cannotDecodeContentData)
        }
        return html
    }

    static func extractPassages(from html: String) throws -> String {
        let doc = try SwiftSoup.parse(html)
        let passages = try doc.select(".rp-passage")
        guard !passages.isEmpty() else {
            throw URLError(.resourceUnavailable)
        }
        return try passages.map(format).joined(separator: "\n\n")
    }

    static func format(_ passage: Element) throws -> String {
        let reference = try passage.select(".rp-passage-display").first()?.text() ?? ""

        guard let content = try passage.select(".rp-passage-text").first() else {
            return reference
        }

        try content.select(".crossreference, .footnote, .footnotes, .crossrefs").remove()

        let titles = try content.select("h3").map { try $0.text() }
        try content.select("h3").remove()

        for sc in try content.select(".small-caps") {
            try sc.text(sc.text().uppercased())
        }

        for num in try content.select(".versenum, .chapternum") {
            try num.prepend("||NL||")
        }

        let body = try content.text()
            .replacingOccurrences(of: "||NL||", with: "\n")
            .replacingOccurrences(of: "\n ", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let parts = titles + [reference, body]
        return parts.filter { !$0.isEmpty }.joined(separator: "\n\n")
    }
}
