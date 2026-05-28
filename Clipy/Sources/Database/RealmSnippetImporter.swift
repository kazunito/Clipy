//
//  RealmSnippetImporter.swift
//
//  Clipy (kazunito fork)
//
//  One-shot import of legacy Realm-backed snippets into the new SQLite store
//  introduced by upstream #609. Upstream ships no data migration, so without
//  this importer existing users see an empty snippet list after upgrade.
//

import Dependencies
import Foundation
import RealmSwift
import SQLiteData

enum RealmSnippetImporter {
    static func importIfNeeded() {
        @Dependency(\.defaultDatabase) var database
        do {
            let realm: Realm
            do {
                realm = try Realm()
            } catch {
                NSLog("[Clipy] RealmSnippetImporter: cannot open Realm: \(String(describing: error))")
                return
            }
            let realmFolders = realm.objects(CPYFolder.self).sorted(byKeyPath: "index", ascending: true)
            NSLog("[Clipy] RealmSnippetImporter: Realm has \(realmFolders.count) folder(s)")
            guard !realmFolders.isEmpty else { return }

            try database.write { dbConnection in
                let existing = try SnippetFolder.all.fetchCount(dbConnection)
                NSLog("[Clipy] RealmSnippetImporter: SQLite has \(existing) existing folder(s)")
                guard existing == 0 else { return }

                var importedFolders = 0
                var importedSnippets = 0
                for folder in realmFolders {
                    guard let folderUUID = UUID(uuidString: folder.identifier) else {
                        NSLog("[Clipy] RealmSnippetImporter: skip folder with invalid identifier: \(folder.identifier)")
                        continue
                    }
                    let folderDraft = SnippetFolder.Draft(
                        id: SnippetFolder.ID(rawValue: folderUUID),
                        title: folder.title,
                        index: folder.index,
                        isEnabled: folder.enable
                    )
                    _ = try SnippetFolder.insert { folderDraft }.returning(\.self).fetchOne(dbConnection)
                    importedFolders += 1

                    let sortedSnippets = folder.snippets.sorted(byKeyPath: "index", ascending: true)
                    for snippet in sortedSnippets {
                        guard let snippetUUID = UUID(uuidString: snippet.identifier) else {
                            NSLog("[Clipy] RealmSnippetImporter: skip snippet with invalid identifier: \(snippet.identifier)")
                            continue
                        }
                        let snippetDraft = Snippet.Draft(
                            id: Snippet.ID(rawValue: snippetUUID),
                            folderID: SnippetFolder.ID(rawValue: folderUUID),
                            title: snippet.title,
                            content: snippet.content,
                            index: snippet.index,
                            isEnabled: snippet.enable
                        )
                        _ = try Snippet.insert { snippetDraft }.returning(\.self).fetchOne(dbConnection)
                        importedSnippets += 1
                    }
                }
                NSLog("[Clipy] RealmSnippetImporter: imported \(importedFolders) folder(s) and \(importedSnippets) snippet(s)")
            }
        } catch {
            NSLog("[Clipy] RealmSnippetImporter failed: \(String(describing: error))")
        }
    }
}
