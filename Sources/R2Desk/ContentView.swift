import R2DeskCore
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var state = AppState()

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .environmentObject(state)
        } detail: {
            ObjectBrowserView()
                .environmentObject(state)
        }
        .task {
            state.loadIfNeeded()
        }
        .sheet(isPresented: $state.showingBucketEditor) {
            BucketEditorView(bucket: state.editingBucket)
                .environmentObject(state)
        }
        .sheet(isPresented: $state.showingNewFolder) {
            NewFolderView()
                .environmentObject(state)
        }
        .sheet(isPresented: $state.showingRenameMove) {
            RenameMoveView()
                .environmentObject(state)
        }
        .sheet(isPresented: $state.showingDetails) {
            DetailsView()
                .environmentObject(state)
        }
        .sheet(isPresented: $state.showingHistory) {
            HistoryView()
                .environmentObject(state)
        }
    }
}

struct SidebarView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        VStack(spacing: 0) {
            List(selection: Binding(
                get: { state.selectedBucketID },
                set: { state.selectBucket($0) }
            )) {
                if !state.favoriteBuckets.isEmpty {
                    Section(L10n.t("favorites")) {
                        ForEach(state.favoriteBuckets) { bucket in
                            Label(bucket.displayName, systemImage: "star.fill")
                                .tag(Optional(bucket.id))
                        }
                    }
                }

                if !state.recentBuckets.isEmpty {
                    Section(L10n.t("recent")) {
                        ForEach(state.recentBuckets) { bucket in
                            Label(bucket.displayName, systemImage: "clock")
                                .tag(Optional(bucket.id))
                        }
                    }
                }

                Section(L10n.t("sidebar_title")) {
                    ForEach(state.config.profiles) { profile in
                        DisclosureGroup(profile.name) {
                            ForEach(profile.buckets) { bucket in
                                Label(bucket.displayName, systemImage: "externaldrive.connected.to.line.below")
                                    .tag(Optional(bucket.id))
                            }
                        }
                    }
                }
            }
            .listStyle(.sidebar)

            Divider()

            HStack {
                Button {
                    state.startAddingBucket()
                } label: {
                    Label(L10n.t("add_bucket"), systemImage: "plus")
                }
                .buttonStyle(.borderless)

                Spacer()

                Button {
                    state.startEditingBucket()
                } label: {
                    Image(systemName: "gearshape")
                }
                .help(L10n.t("settings"))
                .buttonStyle(.borderless)
                .disabled(state.selectedBucket == nil)
            }
            .padding(12)

            HStack {
                Button {
                    state.importConfig()
                } label: {
                    Image(systemName: "square.and.arrow.down")
                }
                .help(L10n.t("import_config"))
                .buttonStyle(.borderless)

                Button {
                    state.exportConfig()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .help(L10n.t("export_config"))
                .buttonStyle(.borderless)

                Spacer()

                Button {
                    state.showingHistory = true
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                }
                .help(L10n.t("history"))
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .navigationSplitViewColumnWidth(min: 220, ideal: 260)
    }
}

struct ObjectBrowserView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        VStack(spacing: 0) {
            HeaderView()
                .environmentObject(state)

            Divider()

            content

            Divider()

            HStack {
                if state.isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(state.uploadProgressText.isEmpty ? state.statusText : state.uploadProgressText)
                    if state.isUploading {
                        ProgressView(value: state.uploadProgressFraction)
                            .frame(width: 180)
                    }
                }
                    .foregroundStyle(.secondary)
                Spacer()
                if state.isUploading {
                    Button(L10n.t("cancel_upload")) {
                        state.cancelUpload()
                    }
                    .buttonStyle(.borderless)
                }
                if !state.failedUploadURLs.isEmpty {
                    Button(L10n.t("retry_failed")) {
                        state.retryFailedUploads()
                    }
                    .buttonStyle(.borderless)
                }
                Text(L10n.t("local_only"))
                    .foregroundStyle(.secondary)
            }
            .font(.footnote)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    Task { await state.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help(L10n.t("refresh"))
                .disabled(state.selectedBucket == nil || state.isLoading)
                .keyboardShortcut("r", modifiers: .command)

                Button {
                    state.upload()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .help(L10n.t("upload"))
                .disabled(state.selectedBucket == nil || state.isLoading)
                .keyboardShortcut("u", modifiers: .command)

                Button {
                    state.showingNewFolder = true
                } label: {
                    Image(systemName: "folder.badge.plus")
                }
                .help(L10n.t("new_folder"))
                .disabled(state.selectedBucket == nil || state.isLoading)
                .keyboardShortcut("n", modifiers: [.command, .shift])

                Button {
                    Task { await state.openSelectedObject() }
                } label: {
                    Image(systemName: "arrow.up.right.square")
                }
                .help(L10n.t("open"))
                .disabled(state.selectedCount != 1 || state.isLoading)
                .keyboardShortcut(.return, modifiers: [])

                Button {
                    state.downloadSelectedObjects()
                } label: {
                    Image(systemName: "arrow.down.circle")
                }
                .help(L10n.t("download"))
                .disabled(state.selectedCount == 0 || state.isLoading)
                .keyboardShortcut("d", modifiers: .command)

                Button {
                    state.startRenameMove()
                } label: {
                    Image(systemName: "arrowshape.turn.up.right")
                }
                .help(L10n.t("rename_move"))
                .disabled(state.selectedCount != 1 || state.isLoading)

                Button {
                    Task { await state.loadSelectedDetails() }
                } label: {
                    Image(systemName: "info.circle")
                }
                .help(L10n.t("details"))
                .disabled(state.selectedCount != 1 || state.isLoading)

                Button {
                    state.toggleFavoriteSelectedBucket()
                } label: {
                    Image(systemName: state.selectedBucketIsFavorite ? "star.fill" : "star")
                }
                .help(L10n.t("favorite"))
                .disabled(state.selectedBucket == nil)

                Button {
                    state.testConnection()
                } label: {
                    Image(systemName: "checkmark.seal")
                }
                .help(L10n.t("test_connection"))
                .disabled(state.selectedBucket == nil || state.isLoading)

                Button(role: .destructive) {
                    state.showingDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                }
                .help(L10n.t("delete"))
                .disabled(state.selectedCount == 0 || state.isLoading)
                .keyboardShortcut(.delete, modifiers: [])
            }
        }
        .alert(state.selectedCount > 1 ? L10n.t("batch_delete_confirm_title") : L10n.t("delete_confirm_title"), isPresented: $state.showingDeleteConfirm) {
            Button(L10n.t("delete"), role: .destructive) {
                Task { await state.deleteSelectedObjects() }
            }
            Button(L10n.t("cancel"), role: .cancel) {}
        } message: {
            Text(state.selectedCount > 1 ? L10n.t("batch_delete_confirm_message") : L10n.t("delete_confirm_message"))
        }
        .alert(L10n.t("overwrite_title"), isPresented: $state.showingUploadConflict) {
            Button(L10n.t("replace")) {
                state.resolveUploadConflict(replace: true)
            }
            Button(L10n.t("auto_rename")) {
                state.resolveUploadConflict(replace: false)
            }
            Button(L10n.t("cancel"), role: .cancel) {
                state.pendingUploadURLs = []
            }
        } message: {
            Text(L10n.t("overwrite_message"))
        }
        .alert(L10n.t("error_title"), isPresented: Binding(
            get: { state.errorMessage != nil },
            set: { if !$0 { state.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(state.errorMessage ?? "")
        }
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: $state.isDropTargeted) { providers in
            state.handleDrop(providers)
        }
        .overlay {
            if state.isDropTargeted {
                RoundedRectangle(cornerRadius: 18)
                    .fill(.blue.opacity(0.12))
                    .stroke(.blue.opacity(0.55), style: StrokeStyle(lineWidth: 2, dash: [7]))
                    .overlay {
                        Label(L10n.t("drop_to_upload"), systemImage: "square.and.arrow.up")
                            .font(.title2.weight(.semibold))
                            .padding(18)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(18)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if state.selectedBucket == nil {
            EmptyStateView(
                title: L10n.t("empty_title"),
                message: L10n.t("empty_message"),
                systemImage: "shippingbox"
            )
        } else if state.prefixes.isEmpty && state.objects.isEmpty && !state.isLoading {
            EmptyStateView(
                title: L10n.t("no_objects"),
                message: state.selectedBucket?.bucketName ?? "",
                systemImage: "tray"
            )
        } else {
            ObjectListView()
                .environmentObject(state)
        }
    }
}

struct HeaderView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(state.selectedBucket?.displayName ?? L10n.t("app_name"))
                    .font(.title2.weight(.semibold))
                HStack(spacing: 8) {
                    Text(state.selectedBucket?.endpoint.host() ?? "S3 / Cloudflare R2")
                    Text("·")
                    Text("\(L10n.t("path")): \(state.pathLabel)")
                }
                .font(.callout)
                .foregroundStyle(.secondary)
            }

            Spacer()

            if let bucket = state.selectedBucket {
                HStack(spacing: 12) {
                    TextField(L10n.t("search"), text: $state.searchText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 220)

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(bucket.bucketName)
                            .font(.callout.weight(.medium))
                        Text("\(L10n.t("usage")): \(ByteFormatter.string(from: state.bucketUsage?.totalBytes ?? 0)) · \(String(format: L10n.t("objects_count"), state.bucketUsage?.objectCount ?? state.objects.count))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(.regularMaterial)
    }
}

struct ObjectListView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        VStack(spacing: 0) {
            if !state.currentPrefix.isEmpty {
                HStack {
                    Button {
                        state.goUp()
                    } label: {
                        Label(L10n.t("up"), systemImage: "chevron.up")
                    }
                    .buttonStyle(.borderless)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }

            HStack {
                Text(L10n.t("name")).frame(maxWidth: .infinity, alignment: .leading)
                Text(L10n.t("size")).frame(width: 110, alignment: .trailing)
                Text(L10n.t("modified")).frame(width: 170, alignment: .leading)
                Text(L10n.t("storage_class")).frame(width: 120, alignment: .leading)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            List(selection: $state.selectedObjectKeys) {
                ForEach(state.displayedPrefixes) { prefix in
                    FolderRow(prefix: prefix) {
                        state.enterPrefix(prefix.prefix)
                    }
                }

                ForEach(state.displayedObjects) { object in
                    ObjectRow(object: object, displayName: state.objectName(for: object.key))
                        .tag(object.key)
                        .contextMenu {
                            Button(L10n.t("open")) {
                                state.selectedObjectKeys = [object.key]
                                Task { await state.openSelectedObject() }
                            }
                            Button(L10n.t("details")) {
                                state.selectedObjectKeys = [object.key]
                                Task { await state.loadSelectedDetails() }
                            }
                            Button(L10n.t("download")) {
                                state.selectedObjectKeys = [object.key]
                                state.downloadSelectedObjects()
                            }
                            Divider()
                            Button(L10n.t("copy_key")) {
                                state.selectedObjectKeys = [object.key]
                                state.copySelectedKey()
                            }
                            Button(L10n.t("copy_url")) {
                                state.selectedObjectKeys = [object.key]
                                state.copySelectedObjectURL()
                            }
                            Button(L10n.t("copy_presigned")) {
                                state.selectedObjectKeys = [object.key]
                                Task { await state.copyPresignedLink() }
                            }
                            Divider()
                            Button(L10n.t("rename_move")) {
                                state.selectedObjectKeys = [object.key]
                                state.startRenameMove()
                            }
                            Button(L10n.t("delete"), role: .destructive) {
                                state.selectedObjectKeys = [object.key]
                                state.showingDeleteConfirm = true
                            }
                        }
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
        }
    }
}

struct FolderRow: View {
    let prefix: ObjectPrefix
    let open: () -> Void

    var body: some View {
        Button(action: open) {
            HStack {
                Label(prefix.displayName, systemImage: "folder")
                    .labelStyle(.titleAndIcon)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(L10n.t("folder"))
                    .foregroundStyle(.secondary)
                    .frame(width: 110, alignment: .trailing)
                Text("-").foregroundStyle(.secondary).frame(width: 170, alignment: .leading)
                Text("-").foregroundStyle(.secondary).frame(width: 120, alignment: .leading)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct ObjectRow: View {
    let object: ObjectItem
    let displayName: String

    var body: some View {
        HStack {
            Label(displayName, systemImage: "doc")
                .labelStyle(.titleAndIcon)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(ByteFormatter.string(from: object.size))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 110, alignment: .trailing)

            Text(formattedDate(object.lastModified))
                .foregroundStyle(.secondary)
                .frame(width: 170, alignment: .leading)

            Text(object.storageClass ?? "-")
                .foregroundStyle(.secondary)
                .frame(width: 120, alignment: .leading)
        }
        .padding(.vertical, 4)
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date else { return "-" }
        return date.formatted(date: .abbreviated, time: .shortened)
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 48, weight: .regular))
                .foregroundStyle(.tertiary)
            Text(title)
                .font(.title3.weight(.semibold))
            Text(message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

struct BucketEditorView: View {
    @EnvironmentObject private var state: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var form: BucketForm

    init(bucket: BucketConfig?) {
        _form = State(initialValue: BucketForm(
            id: bucket?.id,
            profileName: "Cloudflare R2",
            displayName: bucket?.displayName ?? "",
            bucketName: bucket?.bucketName ?? "",
            endpoint: bucket?.endpoint.absoluteString ?? "",
            region: bucket?.region ?? "auto",
            accessKeyID: bucket?.accessKeyID ?? "",
            secretAccessKey: ""
        ))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(form.id == nil ? L10n.t("new_bucket") : L10n.t("edit_bucket"))
                .font(.title2.weight(.semibold))

            Form {
                TextField(L10n.t("profile_name"), text: $form.profileName)
                TextField(L10n.t("display_name"), text: $form.displayName)
                TextField(L10n.t("bucket_name"), text: $form.bucketName)
                HStack {
                    TextField(L10n.t("endpoint"), text: $form.endpoint)
                    Button(L10n.t("cloudflare_template")) {
                        form.endpoint = "https://<account-id>.r2.cloudflarestorage.com"
                        form.region = "auto"
                    }
                }
                TextField(L10n.t("region"), text: $form.region)
                TextField(L10n.t("access_key"), text: $form.accessKeyID)
                SecureField(L10n.t("secret_key"), text: $form.secretAccessKey)
            }
            .formStyle(.grouped)

            HStack {
                if form.id != nil {
                    Button(role: .destructive) {
                        state.showingBucketDeleteConfirm = true
                    } label: {
                        Label(L10n.t("delete_bucket"), systemImage: "trash")
                    }
                }

                Button(L10n.t("test_connection")) {
                    state.testConnection(form: form)
                }
                .disabled(form.bucketName.isEmpty || form.endpoint.isEmpty || form.accessKeyID.isEmpty)

                Spacer()

                Button(L10n.t("cancel")) {
                    dismiss()
                }

                Button(L10n.t("save")) {
                    state.saveBucket(form: form)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(form.bucketName.isEmpty || form.endpoint.isEmpty || form.accessKeyID.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 520)
        .alert(L10n.t("delete_bucket_confirm_title"), isPresented: $state.showingBucketDeleteConfirm) {
            Button(L10n.t("delete_bucket"), role: .destructive) {
                state.removeSelectedBucket()
                dismiss()
            }
            Button(L10n.t("cancel"), role: .cancel) {}
        } message: {
            Text(L10n.t("delete_bucket_confirm_message"))
        }
    }
}

struct HistoryView: View {
    @EnvironmentObject private var state: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(L10n.t("history"))
                    .font(.title2.weight(.semibold))
                Spacer()
                Button("OK") { dismiss() }
            }

            List(state.config.history) { entry in
                HStack(spacing: 12) {
                    Image(systemName: entry.succeeded ? "checkmark.circle" : "xmark.circle")
                        .foregroundStyle(entry.succeeded ? .green : .red)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(entry.action) · \(entry.bucketName)")
                            .font(.callout.weight(.medium))
                        Text(entry.detail)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            .frame(minHeight: 340)
        }
        .padding(24)
        .frame(width: 720, height: 460)
    }
}

struct NewFolderView: View {
    @EnvironmentObject private var state: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var folderName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(L10n.t("new_folder"))
                .font(.title2.weight(.semibold))
            TextField(L10n.t("folder_name"), text: $folderName)
                .textFieldStyle(.roundedBorder)
            HStack {
                Spacer()
                Button(L10n.t("cancel")) { dismiss() }
                Button(L10n.t("create")) {
                    state.createFolder(named: folderName)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(folderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 420)
    }
}

struct RenameMoveView: View {
    @EnvironmentObject private var state: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(L10n.t("rename_move"))
                .font(.title2.weight(.semibold))
            TextField(L10n.t("destination_key"), text: $state.moveDestinationKey)
                .textFieldStyle(.roundedBorder)
            HStack {
                Spacer()
                Button(L10n.t("cancel")) { dismiss() }
                Button(L10n.t("move")) {
                    state.moveSelectedObject(to: state.moveDestinationKey)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(state.moveDestinationKey.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 520)
    }
}

struct DetailsView: View {
    @EnvironmentObject private var state: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(L10n.t("details"))
                .font(.title2.weight(.semibold))

            if let details = state.objectDetails {
                Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 10) {
                    detailRow(L10n.t("name"), details.item.key)
                    detailRow(L10n.t("size"), ByteFormatter.string(from: details.item.size))
                    detailRow(L10n.t("modified"), details.item.lastModified?.formatted(date: .abbreviated, time: .shortened) ?? "-")
                    detailRow(L10n.t("storage_class"), details.item.storageClass ?? "-")
                    detailRow(L10n.t("content_type"), details.contentType ?? "-")
                    detailRow(L10n.t("etag"), details.eTag ?? "-")
                }

                if !details.metadata.isEmpty {
                    Divider()
                    Text(L10n.t("metadata"))
                        .font(.headline)
                    ForEach(details.metadata.keys.sorted(), id: \.self) { key in
                        HStack {
                            Text(key)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(details.metadata[key] ?? "")
                        }
                    }
                }
            }

            HStack {
                Spacer()
                Button("OK") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 560)
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        GridRow {
            Text(label)
                .foregroundStyle(.secondary)
            Text(value)
                .textSelection(.enabled)
        }
    }
}
