import Foundation
import Testing
@testable import R2DeskCore

@Test
func byteFormatterUsesReadableUnits() {
    #expect(ByteFormatter.string(from: 0) == "0 B")
    #expect(ByteFormatter.string(from: 999) == "999 B")
    #expect(ByteFormatter.string(from: 1_536) == "1.5 KB")
    #expect(ByteFormatter.string(from: 5_242_880) == "5 MB")
}

@Test
func configRoundTripsProfilesAndBuckets() throws {
    let bucket = BucketConfig(
        id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        displayName: "Assets",
        bucketName: "assets",
        endpoint: URL(string: "https://abc.r2.cloudflarestorage.com")!,
        region: "auto",
        accessKeyID: "key-1"
    )
    let config = AppConfig(profiles: [
        StorageProfile(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            name: "Cloudflare",
            buckets: [bucket]
        )
    ], favoriteBucketIDs: [bucket.id], recentBucketIDs: [bucket.id])

    let data = try JSONEncoder.r2Desk.encode(config)
    let decoded = try JSONDecoder.r2Desk.decode(AppConfig.self, from: data)

    #expect(decoded.profiles.first?.name == "Cloudflare")
    #expect(decoded.profiles.first?.buckets.first?.bucketName == "assets")
    #expect(decoded.profiles.first?.buckets.first?.endpoint.absoluteString == "https://abc.r2.cloudflarestorage.com")
    #expect(decoded.favoriteBucketIDs == [bucket.id])
    #expect(decoded.recentBucketIDs == [bucket.id])
}

@Test
func pathStyleObjectURLPercentEncodesObjectKey() throws {
    let bucket = BucketConfig(
        displayName: "Docs",
        bucketName: "docs",
        endpoint: URL(string: "https://abc.r2.cloudflarestorage.com")!,
        region: "auto",
        accessKeyID: "key"
    )

    let url = try S3RequestBuilder.objectURL(for: bucket, key: "folder/a file.txt")

    #expect(url.absoluteString == "https://abc.r2.cloudflarestorage.com/docs/folder/a%20file.txt")
}

@Test
func canonicalQuerySortsAndEscapesValues() {
    let query = S3Signer.canonicalQuery([
        URLQueryItem(name: "prefix", value: "folder/a file"),
        URLQueryItem(name: "list-type", value: "2"),
        URLQueryItem(name: "delimiter", value: "/")
    ])

    #expect(query == "delimiter=%2F&list-type=2&prefix=folder%2Fa%20file")
}

@Test
func listURLSupportsFolderDelimiter() throws {
    let bucket = BucketConfig(
        displayName: "Docs",
        bucketName: "docs",
        endpoint: URL(string: "https://abc.r2.cloudflarestorage.com")!,
        region: "auto",
        accessKeyID: "key"
    )

    let url = try S3RequestBuilder.listURL(for: bucket, prefix: "images/", delimiter: "/")

    #expect(url.absoluteString.contains("list-type=2"))
    #expect(url.absoluteString.contains("prefix=images/"))
    #expect(url.absoluteString.contains("delimiter=/"))
}

@Test
func listParserReturnsObjectsAndCommonPrefixes() throws {
    let xml = """
    <ListBucketResult>
      <Contents>
        <Key>images/logo.png</Key>
        <LastModified>2026-05-05T10:00:00.000Z</LastModified>
        <Size>128</Size>
        <StorageClass>STANDARD</StorageClass>
      </Contents>
      <CommonPrefixes>
        <Prefix>images/raw/</Prefix>
      </CommonPrefixes>
    </ListBucketResult>
    """

    let listing = try S3ListParser.parse(Data(xml.utf8))

    #expect(listing.objects.first?.key == "images/logo.png")
    #expect(listing.prefixes.first?.prefix == "images/raw/")
    #expect(listing.prefixes.first?.displayName == "raw")
}

@Test
func mimeTypeDetectorUsesCommonExtensions() {
    #expect(MIMETypeDetector.contentType(for: URL(fileURLWithPath: "/tmp/photo.png")) == "image/png")
    #expect(MIMETypeDetector.contentType(for: URL(fileURLWithPath: "/tmp/page.html")) == "text/html")
    #expect(MIMETypeDetector.contentType(for: URL(fileURLWithPath: "/tmp/file.unknownext")) == "application/octet-stream")
}

@Test
func presignedURLContainsRequiredAWSQueryItems() throws {
    let bucket = BucketConfig(
        displayName: "Docs",
        bucketName: "docs",
        endpoint: URL(string: "https://abc.r2.cloudflarestorage.com")!,
        region: "auto",
        accessKeyID: "access"
    )
    let credentials = S3Credentials(accessKeyID: "access", secretAccessKey: "secret")
    let date = Date(timeIntervalSince1970: 1_714_909_600)

    let url = try S3RequestBuilder.presignedDownloadURL(
        for: bucket,
        key: "folder/file.txt",
        credentials: credentials,
        expiresIn: 900,
        date: date
    )

    let value = url.absoluteString
    #expect(value.contains("X-Amz-Algorithm=AWS4-HMAC-SHA256"))
    #expect(value.contains("X-Amz-Credential=access"))
    #expect(value.contains("X-Amz-Expires=900"))
    #expect(value.contains("X-Amz-Signature="))
}

@Test
func prefixNavigatorBuildsFolderKeys() {
    #expect(PrefixNavigator.parent(of: "images/raw/") == "images/")
    #expect(PrefixNavigator.parent(of: "images/") == "")
    #expect(PrefixNavigator.folderKey(named: "raw", in: "images/") == "images/raw/")
}

@Test
func configDecodesOlderFilesWithDefaults() throws {
    let json = """
    {
      "profiles": []
    }
    """

    let decoded = try JSONDecoder.r2Desk.decode(AppConfig.self, from: Data(json.utf8))

    #expect(decoded.favoriteBucketIDs.isEmpty)
    #expect(decoded.recentBucketIDs.isEmpty)
    #expect(decoded.history.isEmpty)
}

@Test
func uniqueKeyResolverAddsNumericSuffixBeforeExtension() {
    let existing: Set<String> = [
        "images/logo.png",
        "images/logo 2.png"
    ]

    let resolved = UniqueKeyResolver.availableKey(for: "images/logo.png", existingKeys: existing)

    #expect(resolved == "images/logo 3.png")
}

@Test
func bucketUsageSumsObjectSizes() {
    let usage = BucketUsage(objects: [
        ObjectItem(key: "a.txt", size: 10),
        ObjectItem(key: "b.txt", size: 20)
    ])

    #expect(usage.objectCount == 2)
    #expect(usage.totalBytes == 30)
}
