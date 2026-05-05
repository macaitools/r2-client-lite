from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "screens"
OUT.mkdir(exist_ok=True)

W, H = 1440, 940


def font(size, weight="regular"):
    names = {
        "regular": ["/System/Library/Fonts/SFNS.ttf", "/System/Library/Fonts/Supplemental/Arial.ttf"],
        "bold": ["/System/Library/Fonts/SFNS.ttf", "/System/Library/Fonts/Supplemental/Arial Bold.ttf"],
    }
    for name in names.get(weight, names["regular"]):
        try:
            return ImageFont.truetype(name, size=size)
        except Exception:
            pass
    return ImageFont.load_default()


F_TITLE = font(30, "bold")
F_HEAD = font(18, "bold")
F_BODY = font(16)
F_SMALL = font(13)


def rr(draw, box, radius, fill, outline=None, width=1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def text(draw, xy, value, fill=(20, 24, 33), fnt=F_BODY, anchor=None):
    draw.text(xy, value, fill=fill, font=fnt, anchor=anchor)


def base(title="Assets"):
    img = Image.new("RGB", (W, H), (236, 240, 245))
    overlay = Image.new("RGBA", (W, H), (255, 255, 255, 0))
    d = ImageDraw.Draw(overlay)

    rr(d, (70, 58, W - 70, H - 58), 22, (250, 252, 255, 245), (216, 224, 234, 255))
    rr(d, (70, 58, 365, H - 58), 22, (232, 238, 247, 218))
    d.rectangle((345, 59, 365, H - 59), fill=(232, 238, 247, 218))
    d.line((365, 58, 365, H - 58), fill=(208, 216, 227, 255))

    for i, c in enumerate([(255, 95, 86), (255, 189, 46), (39, 201, 63)]):
        d.ellipse((94 + i * 25, 84, 108 + i * 25, 98), fill=c)

    text(d, (100, 137), "Buckets", fnt=F_HEAD)
    text(d, (110, 185), "Cloudflare R2", fill=(78, 88, 102), fnt=F_SMALL)
    rr(d, (96, 212, 340, 252), 10, (209, 226, 245, 230))
    text(d, (122, 224), "Assets", fnt=F_BODY)
    text(d, (122, 273), "Backups", fill=(63, 73, 88), fnt=F_BODY)
    text(d, (122, 318), "Public media", fill=(63, 73, 88), fnt=F_BODY)

    rr(d, (100, H - 118, 220, H - 82), 9, (20, 107, 170, 255))
    text(d, (130, H - 109), "+  Add", fill=(255, 255, 255), fnt=F_SMALL)
    rr(d, (306, H - 118, 338, H - 82), 9, (215, 224, 235, 255))
    d.ellipse((317, H - 103, 327, H - 93), outline=(41, 50, 65), width=2)
    for dx, dy in [(-8, 0), (8, 0), (0, -8), (0, 8)]:
        d.line((322, H - 98, 322 + dx, H - 98 + dy), fill=(41, 50, 65), width=2)

    text(d, (410, 95), title, fnt=F_TITLE)
    text(d, (410, 132), "abc123.r2.cloudflarestorage.com", fill=(92, 102, 117), fnt=F_SMALL)
    text(d, (W - 210, 103), "assets", fnt=F_BODY)
    text(d, (W - 210, 129), "128 objects", fill=(92, 102, 117), fnt=F_SMALL)

    for x, label in [(410, "Name"), (1010, "Size"), (1130, "Modified"), (1250, "Storage")]:
        text(d, (x, 195), label, fill=(92, 102, 117), fnt=F_SMALL)
    d.line((390, 220, W - 100, 220), fill=(219, 226, 236, 255))

    rows = [
        ("hero/banner@2x.png", "840 KB", "Today 14:21", "STANDARD"),
        ("exports/report-may.csv", "55 KB", "Today 11:08", "STANDARD"),
        ("video/launch.mp4", "48 MB", "Yesterday", "STANDARD"),
        ("archive/2026-04.zip", "1.3 GB", "Apr 30", "STANDARD"),
        ("docs/privacy.pdf", "210 KB", "Apr 18", "STANDARD"),
    ]
    y = 242
    for idx, row in enumerate(rows):
        if idx == 1:
            rr(d, (392, y - 8, W - 100, y + 34), 8, (222, 235, 250, 255))
        elif idx % 2 == 0:
            rr(d, (392, y - 8, W - 100, y + 34), 8, (247, 249, 252, 255))
        text(d, (410, y), row[0], fnt=F_BODY)
        text(d, (1062, y), row[1], fill=(72, 82, 96), fnt=F_BODY, anchor="ra")
        text(d, (1130, y), row[2], fill=(72, 82, 96), fnt=F_BODY)
        text(d, (1250, y), row[3], fill=(72, 82, 96), fnt=F_BODY)
        y += 54

    text(d, (410, H - 91), "Ready", fill=(92, 102, 117), fnt=F_SMALL)
    text(d, (W - 260, H - 91), "Local config + Keychain", fill=(92, 102, 117), fnt=F_SMALL)

    return Image.alpha_composite(img.convert("RGBA"), overlay)


def modal(img, title, fields, primary="Save", destructive=None):
    blur = img.filter(ImageFilter.GaussianBlur(5))
    shade = Image.new("RGBA", (W, H), (12, 20, 30, 82))
    out = Image.alpha_composite(blur, shade)
    d = ImageDraw.Draw(out)
    x1, y1, x2, y2 = 460, 190, 980, 735
    rr(d, (x1, y1, x2, y2), 18, (251, 253, 255, 250), (215, 223, 234, 255))
    text(d, (x1 + 34, y1 + 34), title, fnt=F_TITLE)
    y = y1 + 96
    for label, value, secure in fields:
        text(d, (x1 + 36, y), label, fill=(92, 102, 117), fnt=F_SMALL)
        rr(d, (x1 + 34, y + 22, x2 - 34, y + 58), 8, (241, 245, 250, 255), (213, 222, 233, 255))
        text(d, (x1 + 48, y + 32), "••••••••••••" if secure else value, fill=(35, 43, 56), fnt=F_BODY)
        y += 70
    if destructive:
        rr(d, (x1 + 34, y2 - 70, x1 + 178, y2 - 34), 9, (255, 232, 232, 255), (247, 188, 188, 255))
        text(d, (x1 + 56, y2 - 60), destructive, fill=(177, 42, 42), fnt=F_SMALL)
    rr(d, (x2 - 210, y2 - 70, x2 - 120, y2 - 34), 9, (234, 239, 246, 255), (213, 222, 233, 255))
    text(d, (x2 - 184, y2 - 60), "Cancel", fill=(40, 48, 60), fnt=F_SMALL)
    rr(d, (x2 - 108, y2 - 70, x2 - 34, y2 - 34), 9, (20, 107, 170, 255))
    text(d, (x2 - 86, y2 - 60), primary, fill=(255, 255, 255), fnt=F_SMALL)
    return out


def banner(img, label):
    out = img.copy()
    d = ImageDraw.Draw(out)
    rr(d, (1030, 68, 1338, 116), 14, (22, 122, 188, 245))
    text(d, (1054, 82), label, fill=(255, 255, 255), fnt=F_BODY)
    return out


def search_screen():
    img = base()
    d = ImageDraw.Draw(img)
    rr(d, (880, 92, 1110, 128), 9, (241, 245, 250, 255), (213, 222, 233, 255))
    text(d, (898, 101), "report", fill=(35, 43, 56), fnt=F_BODY)
    rr(d, (392, 340, W - 100, 493), 8, (252, 253, 255, 235))
    text(d, (410, 390), "Search filters the current path instantly", fill=(78, 88, 102), fnt=F_HEAD)
    return img


def folder_screen():
    img = base("Assets / images/")
    d = ImageDraw.Draw(img)
    text(d, (410, 132), "Path: images/", fill=(92, 102, 117), fnt=F_SMALL)
    rr(d, (392, 242, W - 100, 284), 8, (247, 249, 252, 255))
    rr(d, (410, 250, 434, 270), 5, (91, 148, 220, 255))
    text(d, (444, 252), "raw", fnt=F_BODY)
    text(d, (1010, 252), "Folder", fill=(72, 82, 96), fnt=F_BODY)
    return img


def rename_screen():
    return modal(base(), "Rename / Move", [
        ("Destination Key", "exports/report-final.csv", False),
    ], primary="Move")


def details_screen():
    img = base()
    blur = img.filter(ImageFilter.GaussianBlur(4))
    d = ImageDraw.Draw(blur)
    rr(d, (465, 250, 975, 640), 18, (252, 253, 255, 252), (215, 223, 234, 255))
    text(d, (500, 286), "Details", fnt=F_TITLE)
    rows = [
        ("Name", "exports/report-may.csv"),
        ("Size", "55 KB"),
        ("Modified", "Today 11:08"),
        ("Storage Class", "STANDARD"),
        ("Content-Type", "text/csv"),
        ("ETag", "8f14e45fceea167a5a36dedd4bea2543"),
    ]
    y = 348
    for label, value in rows:
        text(d, (500, y), label, fill=(92, 102, 117), fnt=F_BODY)
        text(d, (670, y), value, fill=(35, 43, 56), fnt=F_BODY)
        y += 42
    return blur


def batch_screen():
    img = base()
    d = ImageDraw.Draw(img)
    rr(d, (392, 235, W - 100, 331), 8, (222, 235, 250, 255))
    text(d, (410, 252), "exports/report-may.csv", fnt=F_BODY)
    text(d, (410, 306), "video/launch.mp4", fnt=F_BODY)
    rr(d, (965, 70, 1270, 118), 14, (22, 122, 188, 245))
    text(d, (990, 84), "2 selected · Download or Delete", fill=(255, 255, 255), fnt=F_BODY)
    return img


def favorites_screen():
    img = base()
    d = ImageDraw.Draw(img)
    text(d, (100, 170), "Favorites", fnt=F_SMALL, fill=(78, 88, 102))
    rr(d, (96, 192, 340, 232), 10, (245, 236, 204, 230))
    text(d, (122, 204), "★ Assets", fnt=F_BODY)
    text(d, (100, 264), "Recent", fnt=F_SMALL, fill=(78, 88, 102))
    text(d, (122, 294), "Backups", fnt=F_BODY, fill=(63, 73, 88))
    return img


def conflict_screen():
    img = base()
    blur = img.filter(ImageFilter.GaussianBlur(4))
    d = ImageDraw.Draw(blur)
    rr(d, (500, 330, 940, 525), 18, (252, 253, 255, 252), (215, 223, 234, 255))
    text(d, (534, 366), "Files already exist", fnt=F_TITLE)
    text(d, (534, 412), "Choose how to handle files with the same object key.", fill=(80, 90, 104), fnt=F_BODY)
    rr(d, (610, 462, 712, 498), 9, (234, 239, 246, 255), (213, 222, 233, 255))
    text(d, (634, 472), "Cancel", fnt=F_SMALL)
    rr(d, (724, 462, 814, 498), 9, (234, 239, 246, 255), (213, 222, 233, 255))
    text(d, (748, 472), "Replace", fnt=F_SMALL)
    rr(d, (826, 462, 906, 498), 9, (20, 107, 170, 255))
    text(d, (842, 472), "Rename", fill=(255, 255, 255), fnt=F_SMALL)
    return blur


def history_screen():
    img = base()
    blur = img.filter(ImageFilter.GaussianBlur(4))
    d = ImageDraw.Draw(blur)
    rr(d, (360, 230, 1080, 660), 18, (252, 253, 255, 252), (215, 223, 234, 255))
    text(d, (396, 270), "History", fnt=F_TITLE)
    rows = [
        ("Upload · assets", "hero/banner@2x.png", "Today 14:21"),
        ("Download · assets", "exports/report-may.csv", "Today 13:08"),
        ("Delete · backups", "archive/old.zip", "Yesterday"),
    ]
    y = 336
    for title, detail, date in rows:
        rr(d, (396, y - 12, 1040, y + 50), 8, (247, 249, 252, 255))
        text(d, (426, y), title, fnt=F_BODY)
        text(d, (426, y + 24), detail, fill=(92, 102, 117), fnt=F_SMALL)
        text(d, (940, y + 10), date, fill=(92, 102, 117), fnt=F_SMALL)
        y += 76
    return blur


def delete_confirm(img):
    out = img.filter(ImageFilter.GaussianBlur(4))
    d = ImageDraw.Draw(out)
    rr(d, (500, 330, 940, 510), 18, (252, 253, 255, 252), (215, 223, 234, 255))
    text(d, (534, 366), "Delete object?", fnt=F_TITLE)
    text(d, (534, 412), "This removes exports/report-may.csv from the remote bucket.", fill=(80, 90, 104), fnt=F_BODY)
    rr(d, (700, 452, 790, 488), 9, (234, 239, 246, 255), (213, 222, 233, 255))
    text(d, (724, 462), "Cancel", fnt=F_SMALL)
    rr(d, (802, 452, 906, 488), 9, (208, 55, 66, 255))
    text(d, (834, 462), "Delete", fill=(255, 255, 255), fnt=F_SMALL)
    return out


screens = {
    "01-bucket-browser.png": base(),
    "02-add-bucket.png": modal(base(), "New Bucket", [
        ("Connection Name", "Cloudflare R2", False),
        ("Display Name", "Assets", False),
        ("Bucket Name", "assets", False),
        ("Endpoint URL", "https://abc123.r2.cloudflarestorage.com", False),
        ("Region", "auto", False),
        ("Access Key ID", "••••••••", False),
    ]),
    "03-upload-flow.png": banner(base(), "Uploading 3 files..."),
    "04-open-file.png": banner(base(), "Opening exports/report-may.csv in the system app..."),
    "05-delete-confirmation.png": delete_confirm(base()),
    "06-bucket-settings.png": modal(base(), "Bucket Settings", [
        ("Connection Name", "Cloudflare R2", False),
        ("Display Name", "Assets", False),
        ("Bucket Name", "assets", False),
        ("Endpoint URL", "https://abc123.r2.cloudflarestorage.com", False),
        ("Region", "auto", False),
        ("Secret Access Key", "", True),
    ], destructive="Remove Bucket"),
    "07-folder-browsing.png": folder_screen(),
    "08-search-filter.png": search_screen(),
    "09-presigned-link.png": banner(base(), "Presigned link copied"),
    "10-rename-move.png": rename_screen(),
    "11-details-panel.png": details_screen(),
    "12-batch-selection.png": batch_screen(),
    "13-favorites-recent.png": favorites_screen(),
    "14-upload-conflict.png": conflict_screen(),
    "15-operation-history.png": history_screen(),
}

for name, image in screens.items():
    image.convert("RGB").save(OUT / name, quality=94)

print(f"Rendered {len(screens)} screenshots to {OUT}")
