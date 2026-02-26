#!/usr/bin/env python3
"""Fetch themed stock images from Unsplash for all MTG cards."""

import json
import urllib.request
import urllib.parse
import time
import os
import sys

CARDS_FILE = "data/cards.json"
OUTPUT_DIR = "images"
# 3:4 portrait ratio for card art
WIDTH = 512
HEIGHT = 682

# Map each card's art field to search keywords that will find thematic stock photos
CARD_SEARCH_QUERIES = {
    "architect": "futuristic city architecture blueprint glowing",
    "injection": "dark magic purple vortex swirl",
    "recursion": "infinite mirror reflection hallway",
    "overflow": "volcanic eruption fire explosion",
    "conflict": "sword clash sparks battle",
    "generator": "forest workshop crafting nature",
    "null": "void darkness abstract black",
    "sandbox": "crystal cube floating clouds",
    "hydra": "ancient tree branches forest mystical",
    "duck": "rubber duck golden light",
    "push": "energy blast shockwave force",
    "loop": "infinite staircase spiral escher",
    "tea-token": "ornate teacup steam magical",
    "tea-garden": "tea garden terraced green morning",
    "greenhouse": "greenhouse plants glass sunlight",
    "zen-garden": "japanese zen garden raked sand",
    "the-mansion": "gothic mansion dark moonlight",
    "the-parlor": "victorian parlor fireplace dark elegant",
    "the-cellar": "dark cellar underground stone",
    "the-gallery": "portrait gallery hall paintings",
    "overgrown-manor": "overgrown abandoned building vines",
    "tea-master": "tea ceremony monk meditation",
    "firebrew-adept": "fire brewing cauldron flames",
    "scalding-preparation": "boiling water steam kettle",
    "mindful-steeping": "meditation peaceful water calm",
    "kettle-of-inspiration": "bronze kettle antique ornate",
    "ravenous-guest": "dark banquet gothic dining",
    "scalding-sipper": "fire goblet drinking flames",
    "ember-glutton": "demon fire dark feast",
    "etiquette-of-stillness": "formal ceremony stillness golden",
    "ceremony-of-reflection": "water reflection ceremony mystical",
    "code-of-the-table": "formal table setting silverware elegant",
    "fertile-offering": "planting seeds field golden sunset",
    "generous-canopy": "large tree canopy sunlight forest",
    "gift-of-the-wellspring": "crystal spring oasis water glowing",
    "porcelain-teapot": "porcelain teapot ornate blue white",
    "debt-collector": "formal ledger books office dark",
    "ornamental-vase": "ornamental vase porcelain decorated",
}


def search_unsplash(query, per_page=1):
    """Search Unsplash and return image URLs."""
    encoded = urllib.parse.quote(query)
    url = f"https://unsplash.com/napi/search/photos?query={encoded}&per_page={per_page}&orientation=portrait"
    req = urllib.request.Request(url, headers={
        "Accept": "application/json",
        "User-Agent": "Mozilla/5.0"
    })
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = json.loads(resp.read().decode())
            results = []
            for r in data.get("results", []):
                raw_url = r.get("urls", {}).get("raw", "")
                if raw_url:
                    # Add sizing parameters for card art dimensions
                    sized_url = f"{raw_url}&w={WIDTH}&h={HEIGHT}&fit=crop&crop=entropy"
                    results.append({
                        "url": sized_url,
                        "desc": r.get("alt_description", ""),
                        "id": r.get("id", ""),
                        "photographer": r.get("user", {}).get("name", "unknown"),
                    })
            return results
    except Exception as e:
        print(f"  Search error: {e}")
        return []


def download_image(url, output_path):
    """Download an image from URL to file."""
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            data = resp.read()
            with open(output_path, "wb") as f:
                f.write(data)
            return len(data)
    except Exception as e:
        print(f"  Download error: {e}")
        return 0


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    # Load cards to verify art fields
    with open(CARDS_FILE) as f:
        cards = json.load(f)

    card_arts = {c["art"]: c["name"] for c in cards}
    print(f"Found {len(card_arts)} cards in {CARDS_FILE}")
    print(f"Have search queries for {len(CARD_SEARCH_QUERIES)} cards")
    print()

    success = 0
    failed = []
    credits = []  # Track photographer credits

    for art_name, card_name in card_arts.items():
        output_path = os.path.join(OUTPUT_DIR, f"{art_name}.jpg")

        # Skip if already downloaded
        if os.path.exists(output_path) and os.path.getsize(output_path) > 1000:
            print(f"SKIP (exists): {art_name} -> {output_path}")
            success += 1
            continue

        query = CARD_SEARCH_QUERIES.get(art_name, art_name.replace("-", " "))
        print(f"[{success + len(failed) + 1}/{len(card_arts)}] {card_name} ({art_name})")
        print(f"  Searching: {query}")

        results = search_unsplash(query, per_page=3)
        if not results:
            print(f"  FAILED: No results found")
            failed.append(art_name)
            time.sleep(1)
            continue

        # Use the first result
        img = results[0]
        print(f"  Found: {img['desc'][:60]}...")
        print(f"  Downloading...")

        size = download_image(img["url"], output_path)
        if size > 1000:
            print(f"  OK: {output_path} ({size:,} bytes)")
            success += 1
            credits.append(f"{card_name}: Photo by {img['photographer']} on Unsplash")
        else:
            print(f"  FAILED: Download too small ({size} bytes)")
            failed.append(art_name)
            if os.path.exists(output_path):
                os.remove(output_path)

        # Rate limit: be respectful to Unsplash
        time.sleep(2)

    # Save credits file
    credits_path = os.path.join(OUTPUT_DIR, "CREDITS.txt")
    with open(credits_path, "w") as f:
        f.write("Image Credits - All photos from Unsplash (https://unsplash.com)\n")
        f.write("License: Unsplash License (free for commercial and non-commercial use)\n\n")
        for credit in credits:
            f.write(credit + "\n")

    print()
    print("=" * 50)
    print(f"  Done! Success: {success}/{len(card_arts)}")
    if failed:
        print(f"  Failed: {', '.join(failed)}")
    print(f"  Credits saved to {credits_path}")
    print("=" * 50)


if __name__ == "__main__":
    main()
