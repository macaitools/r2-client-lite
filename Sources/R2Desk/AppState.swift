import AppKit
import Foundation
import R2DeskCore
import SwiftUI
import UniformTypeIdentifiers
import UserNotifications

@MainActor
final class AppState: ObservableObject {
    @Published var config = AppConfig()
    @Published var selectedBucketID: UUID?
    @Published var selectedObjectKey: String?
    @Published var selectedObjectKeys: Set<String> = []
    @Published var objects: [ObjectItem] = []
    @Published var prefixes: [ObjectPrefix] = []
    @Published var currentPrefix = ""
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var isUploading = false
    @Published var uploadProgressText = ""
    @Published var uploadProgressFraction = 0.0
    @Published var failedUploadURLs: [URL] = []
    @Published var statusText = L10n.t("status_ready")
    @Published var errorMessage: String?
    @Published var showingBucketEditor = false
    @Published var editingBucket: BucketConfig?
    @Published var showingDeleteConfirm = false
    @Published var showingBucketDeleteConfirm = false
    @Published var showingNewFolder = false
    @Published var showingRenameMove = false
    @Published var moveDestinationKey = ""
    @Published var showingDetails = false
    @Published var objectDetails: ObjectDetails?
    @Published var isDropTargeted = false
    @Published var showingHistory = false
    @Published var showingUploadConflict = false
    @Published var bucketUsage: BucketUsage?
    @Published var pendingUploadURLs: [URL] = []

    private let configStore = ConfigStore()
    private let secretStore = KeychainSecretStore()
    private let client = S3Client()
    private var didLoad = false
    private var uploadTask: Task<Void, Never>?

    enum UploadConflictMode {
        case ask
        case replace
        case rename
    }

    var selectedBucket: BucketConfig? {
        guard let selectedBucketID else { return nil }
        return config.profiles.flatMap(\.buckets).first { $0.id == selectedBucketID }
    }

    var selectedObject: ObjectItem? {
        selectedObjects.first
    }

    var selectedObjects: [ObjectItem] {
        let keys = selectedObjectKeys.isEmpty ? Set(selectedObjectKey.map { [$0] } ?? []) : selectedObjectKeys
        return objects.filter { keys.contains($0.key) }
    }

    var hasBucket: Bool {
        !config.profiles.flatMap(\.buckets).isEmpty
    }

    var displayedPrefixes: [ObjectPrefix] {
        filtered(prefixes) { $0.displayName }
    }

    var displayedObjects: [ObjectItem] {
        filtered(objects.filter { object in
            object.key != currentPrefix && !object.key.hasSuffix("/")
        }) { objectName(for: $0.key) }
    }

    var selectedCount: Int {
        selectedObjects.count
    }

    var favoriteBuckets: [BucketConfig] {
        let buckets = config.profiles.flatMap(\.buckets)
        return config.favoriteBucketIDs.compactMap { id in buckets.first { $0.id == id } }
    }

    var recentBuckets: [BucketConfig] {
        let buckets = config.profiles.flatMap(\.buckets)
        return config.recentBucketIDs.compactMap { id in buckets.first { $0.id == id } }
    }

    var selectedBucketIsFavorite: Bool {
        guard let selectedBucketID else { return false }
        return config.favoriteBucketIDs.contains(selectedBucketID)
    }

    var pathLabel: String {
        currentPrefix.isEmpty ? L10n.t("root") : currentPrefix
    }

    func loadIfNeeded() {
        guard !didLoad else { return }
        didLoad = true
        do {
            config = try configStore.load()
            selectedBucketID = config.profiles.flatMap(\.buckets).first?.id
            requestNotificationPermission()
            if selectedBucketID != nil {
                updateRecentBucket()
                Task { await refresh() }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectBucket(_ id: UUID?) {
        selectedBucketID = id
        selectedObjectKey = nil
        selectedObjectKeys = []
        objects = []
        prefixes = []
        currentPrefix = ""
        searchText = ""
        if id != nil {
            updateRecentBucket()
            Task { await refresh() }
        }
    }

    func refresh() async {
        guard let bucket = selectedBucket else { return }
        await run(status: L10n.t("status_loading")) {
            let listing = try await self.client.list(in: bucket, credentials: self.credentials(for: bucket), prefix: self.currentPrefix)
            self.objects = listing.objects
            self.prefixes = listing.prefixes
            self.selectedObjectKey = nil
            self.selectedObjectKeys = []
            self.bucketUsage = BucketUsage(objects: try await self.client.listObjects(in: bucket, credentials: self.credentials(for: bucket)))
        }
    }

    func upload() {
        guard selectedBucket != nil else { return }
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = true
        guard panel.runModal() == .OK else { return }
        uploadFiles(panel.urls)
    }

    func uploadFiles(_ urls: [URL], conflictMode: UploadConflictMode = .ask) {
        guard let bucket = selectedBucket, !urls.isEmpty else { return }
        let existingKeys = Set(objects.map(\.key))
        let conflicts = urls.filter { fileURL in
            existingKeys.contains(PrefixNavigator.childObjectKey(fileName: fileURL.lastPathComponent, in: currentPrefix))
        }
        if conflictMode == .ask, !conflicts.isEmpty {
            pendingUploadURLs = urls
            showingUploadConflict = true
            return
        }

        uploadTask?.cancel()
        failedUploadURLs = []
        uploadProgressFraction = 0
        uploadProgressText = String(format: L10n.t("upload_progress"), 0, urls.count)
        isUploading = true
        isLoading = true
        statusText = L10n.t("status_uploading")

        uploadTask = Task {
            do {
                let credentials = try self.credentials(for: bucket)
                var failed: [URL] = []
                for (index, fileURL) in urls.enumerated() {
                    if Task.isCancelled { throw CancellationError() }
                    let desiredKey = PrefixNavigator.childObjectKey(fileName: fileURL.lastPathComponent, in: self.currentPrefix)
                    let key = conflictMode == .rename
                        ? UniqueKeyResolver.availableKey(for: desiredKey, existingKeys: existingKeys)
                        : desiredKey
                    self.uploadProgressText = String(format: L10n.t("upload_progress"), index + 1, urls.count)
                    self.uploadProgressFraction = Double(index) / Double(urls.count)
                    do {
                        try await self.client.upload(fileURL: fileURL, to: bucket, credentials: credentials, key: key)
                        self.recordHistory(action: L10n.t("upload"), detail: key, bucketName: bucket.bucketName, succeeded: true)
                    } catch {
                        failed.append(fileURL)
                        self.recordHistory(action: L10n.t("upload"), detail: fileURL.lastPathComponent, bucketName: bucket.bucketName, succeeded: false)
                    }
                }
                self.uploadProgressFraction = 1
                self.failedUploadURLs = failed
                if !Task.isCancelled {
                    await self.refresh()
                }
                if !failed.isEmpty {
                    self.errorMessage = String(format: L10n.t("upload_failed_count"), failed.count)
                } else {
                    self.notify(title: L10n.t("upload"), body: L10n.t("operation_done"))
                }
            } catch is CancellationError {
                self.statusText = L10n.t("status_ready")
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isUploading = false
            self.isLoading = false
            self.uploadProgressText = ""
            self.statusText = L10n.t("status_ready")
        }
    }

    func cancelUpload() {
        uploadTask?.cancel()
        uploadTask = nil
        isUploading = false
        isLoading = false
        uploadProgressText = ""
        statusText = L10n.t("status_ready")
    }

    func retryFailedUploads() {
        let urls = failedUploadURLs
        failedUploadURLs = []
        uploadFiles(urls)
    }

    func resolveUploadConflict(replace: Bool) {
        let urls = pendingUploadURLs
        pendingUploadURLs = []
        showingUploadConflict = false
        uploadFiles(urls, conflictMode: replace ? .replace : .rename)
    }

    func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard selectedBucket != nil else { return false }
        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                let url: URL?
                if let data = item as? Data {
                    url = URL(dataRepresentation: data, relativeTo: nil)
                } else {
                    url = item as? URL
                }
                guard let url else { return }
                Task { @MainActor in
                    self.uploadFiles([url])
                }
            }
        }
        return true
    }

    func openSelectedObject() async {
        guard let bucket = selectedBucket, let object = selectedObject else { return }
        await run(status: L10n.t("status_opening")) {
            let folder = FileManager.default.temporaryDirectory
                .appendingPathComponent("R2Desk", isDirectory: true)
                .appendingPathComponent(bucket.id.uuidString, isDirectory: true)
            let url = try await self.client.downloadObject(key: object.key, from: bucket, credentials: self.credentials(for: bucket), to: folder)
            NSWorkspace.shared.open(url)
            self.recordHistory(action: L10n.t("open"), detail: object.key, bucketName: bucket.bucketName, succeeded: true)
        }
    }

    func deleteSelectedObject() async {
        await deleteSelectedObjects()
    }

    func deleteSelectedObjects() async {
        guard let bucket = selectedBucket, !selectedObjects.isEmpty else { return }
        let objectsToDelete = selectedObjects
        await run(status: L10n.t("status_loading")) {
            let credentials = try self.credentials(for: bucket)
            for object in objectsToDelete {
                try await self.client.deleteObject(key: object.key, from: bucket, credentials: credentials)
                self.recordHistory(action: L10n.t("delete"), detail: object.key, bucketName: bucket.bucketName, succeeded: true)
            }
            let listing = try await self.client.list(in: bucket, credentials: credentials, prefix: self.currentPrefix)
            self.objects = listing.objects
            self.prefixes = listing.prefixes
            self.selectedObjectKey = nil
            self.selectedObjectKeys = []
            self.bucketUsage = BucketUsage(objects: listing.objects)
            self.notify(title: L10n.t("delete"), body: L10n.t("operation_done"))
        }
    }

    func downloadSelectedObjects() {
        guard let bucket = selectedBucket, !selectedObjects.isEmpty else { return }
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let folder = panel.url else { return }
        let objectsToDownload = selectedObjects

        Task {
            await run(status: L10n.t("status_opening")) {
                let credentials = try self.credentials(for: bucket)
                for object in objectsToDownload {
                    _ = try await self.client.downloadObject(key: object.key, from: bucket, credentials: credentials, to: folder)
                    self.recordHistory(action: L10n.t("download"), detail: object.key, bucketName: bucket.bucketName, succeeded: true)
                }
                self.notify(title: L10n.t("download"), body: L10n.t("download_done"))
            }
        }
    }

    func enterPrefix(_ prefix: String) {
        currentPrefix = prefix
        selectedObjectKey = nil
        searchText = ""
        Task { await refresh() }
    }

    func goUp() {
        guard !currentPrefix.isEmpty else { return }
        enterPrefix(PrefixNavigator.parent(of: currentPrefix))
    }

    func createFolder(named name: String) {
        guard let bucket = selectedBucket, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        Task {
            await run(status: L10n.t("status_loading")) {
                let credentials = try self.credentials(for: bucket)
                try await self.client.createFolder(named: name, in: self.currentPrefix, bucket: bucket, credentials: credentials)
                let listing = try await self.client.list(in: bucket, credentials: credentials, prefix: self.currentPrefix)
                self.objects = listing.objects
                self.prefixes = listing.prefixes
                self.bucketUsage = BucketUsage(objects: listing.objects)
            }
        }
    }

    func startRenameMove() {
        guard let object = selectedObject else { return }
        moveDestinationKey = object.key
        showingRenameMove = true
    }

    func moveSelectedObject(to destinationKey: String) {
        guard let bucket = selectedBucket, let object = selectedObject, !destinationKey.isEmpty, destinationKey != object.key else { return }
        Task {
            await run(status: L10n.t("status_loading")) {
                let credentials = try self.credentials(for: bucket)
                try await self.client.moveObject(from: object.key, to: destinationKey, in: bucket, credentials: credentials)
                let listing = try await self.client.list(in: bucket, credentials: credentials, prefix: self.currentPrefix)
                self.objects = listing.objects
                self.prefixes = listing.prefixes
                self.selectedObjectKey = nil
                self.selectedObjectKeys = []
                self.showingRenameMove = false
                self.recordHistory(action: L10n.t("rename_move"), detail: "\(object.key) -> \(destinationKey)", bucketName: bucket.bucketName, succeeded: true)
            }
        }
    }

    func copySelectedKey() {
        guard let object = selectedObject else { return }
        copyToPasteboard(object.key)
    }

    func copySelectedObjectURL() {
        guard let bucket = selectedBucket, let object = selectedObject, let url = try? S3RequestBuilder.objectURL(for: bucket, key: object.key) else { return }
        copyToPasteboard(url.absoluteString)
    }

    func copyPresignedLink() async {
        guard let bucket = selectedBucket, let object = selectedObject else { return }
        do {
            let url = try S3RequestBuilder.presignedDownloadURL(
                for: bucket,
                key: object.key,
                credentials: credentials(for: bucket),
                expiresIn: 3_600
            )
            copyToPasteboard(url.absoluteString)
            statusText = L10n.t("presigned_copied")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadSelectedDetails() async {
        guard let bucket = selectedBucket, let object = selectedObject else { return }
        await run(status: L10n.t("status_loading")) {
            self.objectDetails = try await self.client.details(for: object, in: bucket, credentials: self.credentials(for: bucket))
            self.showingDetails = true
        }
    }

    func testConnection(form: BucketForm? = nil) {
        let bucket: BucketConfig?
        let secret: String?
        if let form {
            guard let endpoint = URL(string: form.endpoint), !form.bucketName.isEmpty else {
                errorMessage = S3Error.invalidURL.localizedDescription
                return
            }
            bucket = BucketConfig(
                id: form.id ?? UUID(),
                displayName: form.displayName.isEmpty ? form.bucketName : form.displayName,
                bucketName: form.bucketName,
                endpoint: endpoint,
                region: form.region.isEmpty ? "auto" : form.region,
                accessKeyID: form.accessKeyID
            )
            secret = form.secretAccessKey
        } else {
            bucket = selectedBucket
            secret = nil
        }

        guard let bucket else { return }
        Task {
            await run(status: L10n.t("status_loading")) {
                let credentials = S3Credentials(
                    accessKeyID: bucket.accessKeyID,
                    secretAccessKey: try self.secretForTest(bucket: bucket, formSecret: secret)
                )
                _ = try await self.client.list(in: bucket, credentials: credentials, prefix: "", delimiter: "/")
                self.statusText = L10n.t("connection_ok")
            }
        }
    }

    func toggleFavoriteSelectedBucket() {
        guard let selectedBucketID else { return }
        if config.favoriteBucketIDs.contains(selectedBucketID) {
            config.favoriteBucketIDs.removeAll { $0 == selectedBucketID }
        } else {
            config.favoriteBucketIDs.insert(selectedBucketID, at: 0)
        }
        saveConfig()
    }

    func exportConfig() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "R2Desk-config.json"
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let data = try JSONEncoder.r2Desk.encode(config)
            try data.write(to: url, options: [.atomic])
            statusText = L10n.t("export_config")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func importConfig() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let data = try Data(contentsOf: url)
            let imported = try JSONDecoder.r2Desk.decode(AppConfig.self, from: data)
            config = imported
            try configStore.save(imported)
            selectedBucketID = imported.profiles.flatMap(\.buckets).first?.id
            selectedObjectKeys = []
            selectedObjectKey = nil
            Task { await refresh() }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveBucket(form: BucketForm) {
        do {
            guard let endpoint = URL(string: form.endpoint), !form.bucketName.isEmpty else {
                throw S3Error.invalidURL
            }

            let bucketID = form.id ?? UUID()
            let bucket = BucketConfig(
                id: bucketID,
                displayName: form.displayName.isEmpty ? form.bucketName : form.displayName,
                bucketName: form.bucketName,
                endpoint: endpoint,
                region: form.region.isEmpty ? "auto" : form.region,
                accessKeyID: form.accessKeyID
            )

            var next = config
            for index in next.profiles.indices {
                next.profiles[index].buckets.removeAll { $0.id == bucketID }
            }

            let profileName = form.profileName.isEmpty ? "Cloudflare R2" : form.profileName
            if let profileIndex = next.profiles.firstIndex(where: { $0.name == profileName }) {
                next.profiles[profileIndex].buckets.append(bucket)
            } else {
                next.profiles.append(StorageProfile(name: profileName, buckets: [bucket]))
            }
            next.profiles.removeAll { $0.buckets.isEmpty }

            try configStore.save(next)
            if !form.secretAccessKey.isEmpty {
                try secretStore.save(form.secretAccessKey, for: bucketID)
            }

            config = next
            selectedBucketID = bucketID
            updateRecentBucket()
            showingBucketEditor = false
            Task { await refresh() }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeSelectedBucket() {
        guard let selectedBucketID else { return }
        do {
            var next = config
            for index in next.profiles.indices {
                next.profiles[index].buckets.removeAll { $0.id == selectedBucketID }
            }
            next.profiles.removeAll { $0.buckets.isEmpty }
            try configStore.save(next)
            try secretStore.deleteSecret(for: selectedBucketID)
            config = next
            self.selectedBucketID = next.profiles.flatMap(\.buckets).first?.id
            objects = []
            prefixes = []
            selectedObjectKey = nil
            selectedObjectKeys = []
            if self.selectedBucketID != nil {
                Task { await refresh() }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func startAddingBucket() {
        editingBucket = nil
        showingBucketEditor = true
    }

    func startEditingBucket() {
        editingBucket = selectedBucket
        showingBucketEditor = selectedBucket != nil
    }

    private func credentials(for bucket: BucketConfig) throws -> S3Credentials {
        guard let secret = try secretStore.secret(for: bucket.id), !secret.isEmpty else {
            throw S3Error.missingSecret
        }
        return S3Credentials(accessKeyID: bucket.accessKeyID, secretAccessKey: secret)
    }

    private func secretForTest(bucket: BucketConfig, formSecret: String?) throws -> String {
        if let formSecret, !formSecret.isEmpty {
            return formSecret
        }
        guard let secret = try secretStore.secret(for: bucket.id), !secret.isEmpty else {
            throw S3Error.missingSecret
        }
        return secret
    }

    func objectName(for key: String) -> String {
        guard !currentPrefix.isEmpty, key.hasPrefix(currentPrefix) else {
            return key
        }
        return String(key.dropFirst(currentPrefix.count))
    }

    private func filtered<T>(_ values: [T], name: (T) -> String) -> [T] {
        let needle = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return values }
        return values.filter { name($0).localizedCaseInsensitiveContains(needle) }
    }

    private func copyToPasteboard(_ value: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(value, forType: .string)
        statusText = L10n.t("copied")
    }

    private func updateRecentBucket() {
        guard let selectedBucketID else { return }
        config.recentBucketIDs.removeAll { $0 == selectedBucketID }
        config.recentBucketIDs.insert(selectedBucketID, at: 0)
        config.recentBucketIDs = Array(config.recentBucketIDs.prefix(8))
        saveConfig()
    }

    private func recordHistory(action: String, detail: String, bucketName: String, succeeded: Bool) {
        config.history.insert(OperationHistoryEntry(bucketName: bucketName, action: action, detail: detail, succeeded: succeeded), at: 0)
        config.history = Array(config.history.prefix(100))
        saveConfig()
    }

    private func saveConfig() {
        do {
            try configStore.save(config)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func notify(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func run(status: String, operation: @escaping () async throws -> Void) async {
        isLoading = true
        errorMessage = nil
        statusText = status
        do {
            try await operation()
            statusText = L10n.t("status_ready")
        } catch {
            errorMessage = error.localizedDescription
            statusText = L10n.t("status_ready")
        }
        isLoading = false
    }
}

struct BucketForm {
    var id: UUID?
    var profileName = "Cloudflare R2"
    var displayName = ""
    var bucketName = ""
    var endpoint = ""
    var region = "auto"
    var accessKeyID = ""
    var secretAccessKey = ""
}
