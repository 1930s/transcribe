extension AmazonTranscribe.Transcript {
    /// Formats a Transcript data structure as a Markdown string.
    public func makeMarkdown() -> String {
        let paragraphs: [String] = segments.map { segment in
            var speakerName = self[speaker: segment.speakerLabel]?.name ?? segment.speakerLabel
            if speakerName.isEmpty {
                speakerName = "(Unknown)"
            }
            return """
            \(segment.time.lowerBound.seconds)–\(segment.time.upperBound.seconds)<br>
            **\(speakerName)** \(segment.text)
            """
        }
        return paragraphs.joined(separator: "\n\n")
    }
}
