/// Command-line utility that takes an input file in the Amazon Transcribe API JSON format
/// and converts it to Markdown.
///
/// Usage:
///
///     TranscribeCLI --json FILE
///     TranscribeCLI --json FILE --names SPEAKER SPEAKER
///
///     FILE: The input file. Must be in Amazon Transcribe JSON format.
///     SPEAKER: Name of the speaker. Should be ordered by appearance.
///
///     The resulting Markdown and WebVTT file is saved to the current directory with the
///     same basename as the input file.

import Foundation
import Transcribe
import Utility

// MARK: - Main program

do {
    // setup the argument parser
    let parser = ArgumentParser(usage: "<options>",
                                overview: "A Swift parser for output files from automated transcription services.")
    let rawInputFilename = parser.add(option: "--json", shortName: "-j", kind: PathArgument.self, usage: "Amazon transcribe json file, e.g. './TestFixtures/amazon-transcribe-swift-community-podcast-0001-formatted-short.json'")
    let rawSpeakerNames = parser.add(option: "--names", shortName: "-n", kind: [String].self, usage: "Array of speaker names, e.g. 'alice bob'")
    
    // The first argument is always the executable, drop it
    let arguments = Array(ProcessInfo.processInfo.arguments.dropFirst())
    let parsedArguments = try parser.parse(arguments)
    guard let inputFilename = parsedArguments.get(rawInputFilename),
        inputFilename.path.asString.lowercased().hasSuffix("json") else {
        throw ArgumentParserError.invalidValue(argument: "--json", error: ArgumentConversionError.custom("No json file specified"))
    }
   
    // validate json filename
    let inputFile = URL(fileURLWithPath: inputFilename.path.asString).standardizedFileURL
    guard let isRegularFile = try? inputFile.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile, isRegularFile == true else {
        throw ArgumentParserError.invalidValue(argument: "--json", error: ArgumentConversionError.custom("File not found"))
    }

    // parse the amazon transcription json file
    var transcript = try AmazonTranscribe.Transcript(file: inputFile)
    let outputDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

    // Set speaker names
    if let speakerNames = parsedArguments.get(rawSpeakerNames),
        speakerNames.count == transcript.speakers.count {
        for (index, speaker) in transcript.speakers.enumerated() {
            transcript[speaker: speaker.speakerLabel]?.name = speakerNames[index]
        }
    } else {
        throw ArgumentParserError.invalidValue(argument: "--names", error: ArgumentConversionError.custom("Wrong number of speaker names (should be \(transcript.speakers.count))"))
    }
    
    // write markdown file
    let markdown = transcript.makeMarkdown()
    let markdownOutputFilename = inputFile.deletingPathExtension().appendingPathExtension("md").lastPathComponent
    let markdownOutputFile = outputDirectory.appendingPathComponent(markdownOutputFilename)
    try Data(markdown.utf8).write(to: markdownOutputFile)

    // write webvtt file
    let webvtt = transcript.makeWebVTT()
    let webvttOutputFilename = inputFile.deletingPathExtension().appendingPathExtension("vtt").lastPathComponent
    let webvttOutputFile = outputDirectory.appendingPathComponent(webvttOutputFilename)
    try Data(webvtt.utf8).write(to: webvttOutputFile)

} catch let error as ArgumentParserError {
    print(error.description)
} catch {
    print("Error: \(error)", to: &stdError)
    exit(-1)
}
