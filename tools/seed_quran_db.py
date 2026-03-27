import json
import os
import sqlite3
import urllib.request
import time


TANZIL_CONTENT_URL = "https://cdn.jsdelivr.net/npm/ar.tanzil.quran-simple.txt@1.0.0/content.json"
QURAN_API_PAGE = "https://api.quran.com/api/v4/verses/by_page"

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
}

# (name_ar, ayah_count) for 114 surahs
SURAH_INFO = [
    ("الفاتحة", 7),
    ("البقرة", 286),
    ("آل عمران", 200),
    ("النساء", 176),
    ("المائدة", 120),
    ("الأنعام", 165),
    ("الأعراف", 206),
    ("الأنفال", 75),
    ("التوبة", 129),
    ("يونس", 109),
    ("هود", 123),
    ("يوسف", 111),
    ("الرعد", 43),
    ("إبراهيم", 52),
    ("الحجر", 99),
    ("النحل", 128),
    ("الإسراء", 111),
    ("الكهف", 110),
    ("مريم", 98),
    ("طه", 135),
    ("الأنبياء", 112),
    ("الحج", 78),
    ("المؤمنون", 118),
    ("النور", 64),
    ("الفرقان", 77),
    ("الشعراء", 227),
    ("النمل", 93),
    ("القصص", 88),
    ("العنكبوت", 69),
    ("الروم", 60),
    ("لقمان", 34),
    ("السجدة", 30),
    ("الأحزاب", 73),
    ("سبأ", 54),
    ("فاطر", 45),
    ("يس", 83),
    ("الصافات", 182),
    ("ص", 88),
    ("الزمر", 75),
    ("غافر", 85),
    ("فصلت", 54),
    ("الشورى", 53),
    ("الزخرف", 89),
    ("الدخان", 59),
    ("الجاثية", 37),
    ("الأحقاف", 35),
    ("محمد", 38),
    ("الفتح", 29),
    ("الحجرات", 18),
    ("ق", 45),
    ("الذاريات", 60),
    ("الطور", 49),
    ("النجم", 62),
    ("القمر", 55),
    ("الرحمن", 78),
    ("الواقعة", 96),
    ("الحديد", 29),
    ("المجادلة", 22),
    ("الحشر", 24),
    ("الممتحنة", 13),
    ("الصف", 14),
    ("الجمعة", 11),
    ("المنافقون", 11),
    ("التغابن", 18),
    ("الطلاق", 12),
    ("التحريم", 12),
    ("الملك", 30),
    ("القلم", 52),
    ("الحاقة", 52),
    ("المعارج", 44),
    ("نوح", 28),
    ("الجن", 28),
    ("المزمل", 20),
    ("المدثر", 56),
    ("القيامة", 40),
    ("الإنسان", 31),
    ("المرسلات", 50),
    ("النبأ", 40),
    ("النازعات", 46),
    ("عبس", 42),
    ("التكوير", 29),
    ("الانفطار", 19),
    ("المطففين", 36),
    ("الانشقاق", 25),
    ("البروج", 22),
    ("الطارق", 17),
    ("الأعلى", 19),
    ("الغاشية", 26),
    ("الفجر", 30),
    ("البلد", 20),
    ("الشمس", 15),
    ("الليل", 21),
    ("الضحى", 11),
    ("الشرح", 8),
    ("التين", 8),
    ("العلق", 19),
    ("القدر", 5),
    ("البينة", 8),
    ("الزلزلة", 8),
    ("العاديات", 11),
    ("القارعة", 11),
    ("التكاثر", 8),
    ("العصر", 3),
    ("الهمزة", 9),
    ("الفيل", 5),
    ("قريش", 4),
    ("الماعون", 7),
    ("الكوثر", 3),
    ("الكافرون", 6),
    ("النصر", 3),
    ("المسد", 5),
    ("الإخلاص", 4),
    ("الفلق", 5),
    ("الناس", 6),
]


def fetch_json(url: str, retries: int = 3):
    for attempt in range(retries):
        try:
            req = urllib.request.Request(url, headers=HEADERS)
            with urllib.request.urlopen(req, timeout=20) as resp:
                return json.loads(resp.read().decode("utf-8"))
        except Exception:
            if attempt == retries - 1:
                raise
            time.sleep(1.5)


def download_verses() -> list[str]:
    print("Downloading Quran text from Tanzil...")
    req = urllib.request.Request(TANZIL_CONTENT_URL, headers=HEADERS)
    with urllib.request.urlopen(req) as resp:
        data = resp.read().decode("utf-8")
    verses: list[str] = json.loads(data)

    print(f"Downloaded {len(verses)} verses.")
    if len(verses) != 6236:
        raise ValueError(f"Expected 6236 verses, got {len(verses)}")

    return verses


def download_page_mapping() -> dict[tuple[int, int], int]:
    """Fetch (surah_id, ayah_number) -> page from Quran.com API."""
    mapping: dict[tuple[int, int], int] = {}

    for page_num in range(1, 605):
        url = f"{QURAN_API_PAGE}/{page_num}"

        try:
            data = fetch_json(url)
        except Exception as e:
            raise RuntimeError(f"Failed to fetch page {page_num}: {e}") from e

        verses = data.get("verses") or []

        for v in verses:
            key = v.get("verse_key") or ""
            parts = key.split(":")
            if len(parts) != 2:
                continue

            surah_id = int(parts[0])
            ayah_number = int(parts[1])
            mapping[(surah_id, ayah_number)] = page_num

        if page_num % 50 == 0:
            print(f"Fetched page mapping up to page {page_num}")

    print(f"Page mapping: {len(mapping)} verses.")
    return mapping


def init_db(db_path: str):
    os.makedirs(os.path.dirname(db_path), exist_ok=True)

    if os.path.exists(db_path):
        os.remove(db_path)

    conn = sqlite3.connect(db_path)
    cur = conn.cursor()

    cur.executescript(
        """
        PRAGMA foreign_keys = ON;

        CREATE TABLE surahs (
          id INTEGER PRIMARY KEY,
          name_ar TEXT NOT NULL,
          name_en TEXT,
          ayah_count INTEGER NOT NULL
        );

        CREATE TABLE ayahs (
          id INTEGER PRIMARY KEY,
          surah_id INTEGER NOT NULL,
          ayah_number INTEGER NOT NULL,
          text_ar TEXT NOT NULL,
          page INTEGER NOT NULL,
          FOREIGN KEY (surah_id) REFERENCES surahs(id)
        );

        CREATE TABLE bookmarks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          surah_id INTEGER NOT NULL,
          ayah_number INTEGER NOT NULL,
          created_at INTEGER NOT NULL,
          note TEXT,
          FOREIGN KEY (surah_id) REFERENCES surahs(id)
        );
        """
    )

    conn.commit()
    return conn


def seed_surahs(conn: sqlite3.Connection):
    cur = conn.cursor()

    for idx, (name_ar, ayah_count) in enumerate(SURAH_INFO, start=1):
        cur.execute(
            "INSERT INTO surahs (id, name_ar, name_en, ayah_count) VALUES (?, ?, ?, ?)",
            (idx, name_ar, None, ayah_count),
        )

    conn.commit()


def seed_ayahs(conn, verses, page_mapping):
    cur = conn.cursor()

    global_id = 1
    offset = 0

    for surah_id, (_, ayah_count) in enumerate(SURAH_INFO, start=1):
        for ayah_number in range(1, ayah_count + 1):

            text_ar = verses[offset]
            page = page_mapping.get((surah_id, ayah_number), 1)

            cur.execute(
                "INSERT INTO ayahs (id, surah_id, ayah_number, text_ar, page) VALUES (?, ?, ?, ?, ?)",
                (global_id, surah_id, ayah_number, text_ar, page),
            )

            global_id += 1
            offset += 1

    conn.commit()


def create_fts(conn):
    cur = conn.cursor()

    cur.executescript(
        """
        CREATE VIRTUAL TABLE ayahs_fts USING fts5(
          text_ar,
          surah_id UNINDEXED,
          ayah_number UNINDEXED,
          content='ayahs',
          content_rowid='id'
        );

        INSERT INTO ayahs_fts(rowid, text_ar, surah_id, ayah_number)
        SELECT id, text_ar, surah_id, ayah_number FROM ayahs;
        """
    )

    conn.commit()


def main():
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    db_path = os.path.join(project_root, "assets", "db", "quran.db")

    verses = download_verses()

    print("Downloading page mapping from Quran.com API...")
    page_mapping = download_page_mapping()

    conn = init_db(db_path)

    try:
        print("Seeding surahs...")
        seed_surahs(conn)

        print("Seeding ayahs...")
        seed_ayahs(conn, verses, page_mapping)

        print("Creating FTS index...")
        create_fts(conn)

        print(f"Done. Database created at: {db_path}")

    finally:
        conn.close()


if __name__ == "__main__":
    main()
