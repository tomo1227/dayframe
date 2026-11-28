import Foundation

#if os(iOS)
  enum MarkdownKeyboardKey: String {
    case heading = "markdown-insert-heading"
    case subheading = "markdown-insert-subheading"
    case backtick = "markdown-insert-backtick"
    case fence = "markdown-insert-fence"
    case asterisk = "markdown-insert-asterisk"
    case bullet = "markdown-insert-bullet"
    case quote = "markdown-insert-quote"
    case underscore = "markdown-insert-underscore"
    case strikethrough = "markdown-insert-strikethrough"
    case link = "markdown-insert-link"

    static let primary: [Self] = [.heading, .subheading, .backtick, .fence, .asterisk]
    static let additional: [Self] = [.bullet, .quote, .underscore, .strikethrough, .link]

    var symbol: String {
      switch self {
      case .heading: "#"
      case .subheading: "##"
      case .backtick: "`"
      case .fence: "```"
      case .asterisk: "*"
      case .bullet: "-"
      case .quote: ">"
      case .underscore: "_"
      case .strikethrough: "~~"
      case .link: "[]()"
      }
    }

    var insertion: String {
      switch self {
      case .heading, .subheading, .bullet, .quote: symbol + " "
      default: symbol
      }
    }

    var title: LocalizedStringResource {
      switch self {
      case .heading: "Insert heading marker"
      case .subheading: "Insert subheading marker"
      case .backtick: "Insert backtick"
      case .fence: "Insert code fence"
      case .asterisk: "Insert asterisk"
      case .bullet: "Insert list marker"
      case .quote: "Insert quote marker"
      case .underscore: "Insert underscore"
      case .strikethrough: "Insert strikethrough marker"
      case .link: "Insert link syntax"
      }
    }
  }
#endif
