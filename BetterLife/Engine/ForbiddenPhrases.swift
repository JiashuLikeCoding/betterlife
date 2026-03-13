import Foundation

enum ForbiddenPhrases {
    static let list: [String] = [
        "培養習慣",
        "保持動力",
        "持續練習",
        "改善自己",
        "提升效率",
        "試試看",
        "想想看",
        "做做看",
        "整理一下",
        "輕一點",
        "先做一些"
    ]

    // Optional hard ban list (single tokens)
    static let fuzzyTokens: [String] = [
        "選",
        "試試",
        "做做看",
        "想想",
        "一下",
        "一些",
        "輕一"
    ]
}
