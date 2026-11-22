import Foundation

/// GitHub ホームページ URL から README を取得 (フォールバック)
public enum BrewGitHubReadmeFetcher {
    public static func fetch(homepage: String?) async -> String? {
        guard let homepage,
              let repo = GitHubRepositoryReference.parse(homepage: homepage)
        else {
            return nil
        }

        let candidates = [
            "https://raw.githubusercontent.com/\(repo.owner)/\(repo.name)/\(repo.branch)/README.md",
            "https://raw.githubusercontent.com/\(repo.owner)/\(repo.name)/\(repo.branch)/Readme.md",
        ]

        for urlString in candidates {
            guard let url = URL(string: urlString) else { continue }
            var request = URLRequest(url: url)
            request.timeoutInterval = 12
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse,
                      (200 ..< 300).contains(http.statusCode),
                      let text = String(data: data, encoding: .utf8)?
                          .trimmingCharacters(in: .whitespacesAndNewlines),
                      text.count >= 40
                else {
                    continue
                }
                return text
            } catch {
                continue
            }
        }
        return nil
    }
}

struct GitHubRepositoryReference {
    let owner: String
    let name: String
    let branch: String

    static func parse(homepage: String) -> GitHubRepositoryReference? {
        let trimmed = homepage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let components = URLComponents(string: trimmed), components.host?.contains("github.com") == true else {
            return nil
        }
        let parts = components.path.split(separator: "/").map(String.init)
        guard parts.count >= 2 else { return nil }
        let owner = parts[0]
        var name = parts[1]
        if name.hasSuffix(".git") {
            name = String(name.dropLast(4))
        }
        return GitHubRepositoryReference(owner: owner, name: name, branch: "HEAD")
    }
}
