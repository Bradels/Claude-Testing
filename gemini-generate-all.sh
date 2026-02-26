#!/bin/bash
# gemini-generate-all.sh
# Generates card art for all MTG cards using the Google Gemini API.
#
# Usage:
#   export GEMINI_API_KEY="your-api-key-here"
#   ./gemini-generate-all.sh
#
# Or:
#   GEMINI_API_KEY="your-key" ./gemini-generate-all.sh
#
# Images are saved to ./images/<card-art-name>.png

set -euo pipefail

GEMINI_API_KEY="${GEMINI_API_KEY:?ERROR: Set GEMINI_API_KEY environment variable}"
OUTPUT_DIR="./images"
mkdir -p "$OUTPUT_DIR"

SUCCESS=0
FAIL=0
FAILED_CARDS=()

generate_image() {
    local filename="$1"
    local prompt="$2"
    local output_path="$OUTPUT_DIR/$filename.png"

    if [ -f "$output_path" ] && [ -s "$output_path" ]; then
        echo "  SKIP (already exists): $output_path"
        SUCCESS=$((SUCCESS + 1))
        return 0
    fi

    echo "Generating: $filename..."

    # Escape prompt for JSON
    local escaped_prompt
    escaped_prompt=$(python3 -c "import json; print(json.dumps('$prompt'.replace(\"'\", \"\\\\'\")))" 2>/dev/null || echo "\"$prompt\"")

    # --- Try Imagen 3 first ---
    local response
    response=$(curl -s --max-time 120 \
        "https://generativelanguage.googleapis.com/v1beta/models/imagen-3.0-generate-002:predict?key=$GEMINI_API_KEY" \
        -H 'Content-Type: application/json' \
        -d "{
            \"instances\": [{\"prompt\": $escaped_prompt}],
            \"parameters\": {\"sampleCount\": 1, \"aspectRatio\": \"3:4\"}
        }" 2>/dev/null || echo "")

    local image_data
    image_data=$(echo "$response" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data['predictions'][0]['bytesBase64Encoded'])
except:
    pass
" 2>/dev/null || true)

    if [ -n "$image_data" ]; then
        echo "$image_data" | base64 -d > "$output_path"
        echo "  OK (Imagen 3): $output_path ($(wc -c < "$output_path") bytes)"
        SUCCESS=$((SUCCESS + 1))
        sleep 2
        return 0
    fi

    # --- Fallback: Gemini 2.0 Flash ---
    response=$(curl -s --max-time 120 \
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$GEMINI_API_KEY" \
        -H 'Content-Type: application/json' \
        -d "{
            \"contents\": [{\"parts\": [{\"text\": $escaped_prompt}]}],
            \"generationConfig\": {\"responseModalities\": [\"IMAGE\"]}
        }" 2>/dev/null || echo "")

    image_data=$(echo "$response" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    parts = data['candidates'][0]['content']['parts']
    for part in parts:
        if 'inlineData' in part:
            print(part['inlineData']['data'])
            break
except:
    pass
" 2>/dev/null || true)

    if [ -n "$image_data" ]; then
        echo "$image_data" | base64 -d > "$output_path"
        echo "  OK (Gemini Flash): $output_path ($(wc -c < "$output_path") bytes)"
        SUCCESS=$((SUCCESS + 1))
        sleep 2
        return 0
    fi

    echo "  FAILED: $filename"
    FAIL=$((FAIL + 1))
    FAILED_CARDS+=("$filename")
    sleep 1
    return 0  # Don't abort the whole script
}

echo "========================================"
echo "  MTG Card Art Generator (Gemini API)"
echo "========================================"
echo ""

# --- Card 1: Claude, the Architect ---
generate_image "architect" \
    "Fantasy illustration for a Magic: The Gathering card. A majestic luminous AI entity in humanoid form, hovering above a sprawling digital cityscape of glowing blue and white architecture. The figure extends its hands outward, projecting holographic blueprints and constructing towers of light. Ethereal robes made of flowing data streams. Style: Digital painting, dramatic upward lighting, rich colors, detailed fantasy art. Color palette: bright holy whites and arcane blues, golden accents. Aspect ratio: 3:4 portrait. No text, no words, no letters, no card frame."

# --- Card 2: Prompt Injection ---
generate_image "injection" \
    "Fantasy illustration for a Magic: The Gathering card. A shadowy hooded figure reaching into a swirling vortex of arcane blue and dark purple energy, redirecting streams of magical glyphs and runes mid-flight. The stolen spell twists and changes color as it passes through the figure's fingers. Dark library background with floating spell scrolls. Style: Digital painting, dramatic chiaroscuro lighting, detailed fantasy art. Color palette: deep blues, shadowy blacks, purple arcane energy. Aspect ratio: 3:4 portrait. No text, no words, no letters, no card frame."

# --- Card 3: Recursive Function ---
generate_image "recursion" \
    "Fantasy illustration for a Magic: The Gathering card. An infinite hallway of mirrors, each reflection showing a slightly smaller version of a glowing blue arcane construct. Fractal patterns spiral inward, with each iteration creating a smaller perfect copy of itself. Ethereal blue light emanates from the center. Mathematical spirals and recursive geometric patterns fill the space. Style: Digital painting, mesmerizing depth, detailed fantasy art. Color palette: deep arcane blues, cyan, silver reflections. Aspect ratio: 3:4 portrait. No text, no words, no letters, no card frame."

# --- Card 4: Stack Overflow ---
generate_image "overflow" \
    "Fantasy illustration for a Magic: The Gathering card. A massive tower of unstable magical energy, overflowing and collapsing in a catastrophic explosion of red and orange fire. Memory shards and data fragments scatter in all directions. The ground cracks beneath the overflow of raw power. Volcanic destruction scene. Style: Digital painting, explosive dynamic composition, detailed fantasy art. Color palette: fiery reds, intense oranges, molten gold, dark smoke. Aspect ratio: 3:4 portrait. No text, no words, no letters, no card frame."

# --- Card 5: Merge Conflict ---
generate_image "conflict" \
    "Fantasy illustration for a Magic: The Gathering card. Two powerful warriors locked in fierce combat, their weapons clashing and sending sparks of red and black energy in opposite directions. The ground between them splits apart with jagged cracks. One warrior is wreathed in crimson flame, the other in dark shadow. The battlefield shows two overlapping realities tearing apart. Style: Digital painting, intense action composition, detailed fantasy art. Color palette: deep blacks, fiery reds, dark crimson. Aspect ratio: 3:4 portrait. No text, no words, no letters, no card frame."

# --- Card 6: Token Generator ---
generate_image "generator" \
    "Fantasy illustration for a Magic: The Gathering card. A cheerful elf artificer in a lush forest workshop, hands glowing green as they coax small living plant creatures (saprolings) into existence from seeds on a wooden workbench. Mushrooms, vines, and small sprouting creatures surround them. Warm dappled forest light. Style: Digital painting, warm natural lighting, detailed fantasy art. Color palette: rich forest greens, earthy browns, golden sunlight. Aspect ratio: 3:4 portrait. No text, no words, no letters, no card frame."

# --- Card 7: Null Pointer ---
generate_image "null" \
    "Fantasy illustration for a Magic: The Gathering card. A spectral hand pointing at a creature that is dissolving into void and nothingness. The creature's form fractures and pixelates as it is erased from existence, leaving only a dark empty silhouette. Black mist and dark energy swirl around the disintegrating form. Desolate wasteland background. Style: Digital painting, eerie dark atmosphere, detailed fantasy art. Color palette: deep blacks, dark purples, void darkness with faint ghostly highlights. Aspect ratio: 3:4 portrait. No text, no words, no letters, no card frame."

# --- Card 8: The Cloud Sandbox ---
generate_image "sandbox" \
    "Fantasy illustration for a Magic: The Gathering card. A magnificent floating crystalline cube hovering in a cloudy sky, containing a miniature world inside it — tiny buildings, forests, and rivers visible through its translucent walls. Beams of energy connect to other floating artifacts nearby. The cube glows with an inner light of creation. Style: Digital painting, ethereal skyscape, detailed fantasy art. Color palette: neutral metallics, silver, crystal clear, white clouds, soft golden light. Aspect ratio: 3:4 portrait. No text, no words, no letters, no card frame."

# --- Card 9: Open Source Hydra ---
generate_image "hydra" \
    "Fantasy illustration for a Magic: The Gathering card. A massive multi-headed hydra emerging from a primordial forest, each head different and growing from branching necks like a great tree. New heads are visibly sprouting and budding from the creature. The hydra is entwined with vines and moss, each head glowing with green life energy. Ancient forest with towering trees behind it. Style: Digital painting, epic scale, dramatic upward perspective, detailed fantasy art. Color palette: vivid greens, emerald, forest tones, golden eyes. Aspect ratio: 3:4 portrait. No text, no words, no letters, no card frame."

# --- Card 10: Rubber Duck Debugging ---
generate_image "duck" \
    "Fantasy illustration for a Magic: The Gathering card. A serene temple scene with a small golden rubber duck sitting on a pedestal, radiating soft white holy light. A wizard kneels before it in contemplation, and as the light touches their forehead, glowing runes and solutions appear floating in the air. Peaceful monastery setting with incense and candles. Style: Digital painting, warm peaceful atmosphere, detailed fantasy art. Color palette: warm whites, soft golds, holy light, gentle yellows. Aspect ratio: 3:4 portrait. No text, no words, no letters, no card frame."

# --- Card 11: Force Push ---
generate_image "push" \
    "Fantasy illustration for a Magic: The Gathering card. A powerful mage unleashing a massive blast of red and white energy from both hands, sending a warrior and everything around them hurtling into a swirling portal of exile. The force wave distorts space itself, bending light and warping the landscape. Debris and energy crackle in the wake. Style: Digital painting, explosive action, dramatic force effects, detailed fantasy art. Color palette: fiery reds, brilliant whites, energy crackling. Aspect ratio: 3:4 portrait. No text, no words, no letters, no card frame."

# --- Card 12: Infinite Loop ---
generate_image "loop" \
    "Fantasy illustration for a Magic: The Gathering card. An impossible Escher-like structure of endless staircases and corridors, with ghostly figures trapped walking the same path forever. A massive glowing blue Ouroboros serpent encircles the structure, biting its own tail. Time is frozen — hourglasses float mid-air, neither rising nor falling. Hypnotic, mesmerizing atmosphere. Style: Digital painting, surreal impossible geometry, detailed fantasy art. Color palette: deep mystical blues, purple, silver, ethereal glow. Aspect ratio: 3:4 portrait. No text, no words, no letters, no card frame."

# --- Card 13: Tea (Token) ---
generate_image "tea-token" \
    "Fantasy illustration for a Magic: The Gathering card. An ornate porcelain teacup on a saucer, steaming with magical dual-colored vapor — one side glowing red with destructive energy, the other glowing green with healing life force. The cup sits on an elegant dark wooden table with arcane runes carved into it. Intimate close-up view with dramatic lighting. Style: Digital painting, still life with magical elements, detailed fantasy art. Color palette: warm porcelain whites, red and green magical steam, dark rich wood. Aspect ratio: 3:4 portrait. No text, no words, no letters, no card frame."

# --- Card 14: Tea Garden ---
generate_image "tea-garden" \
    "Fantasy illustration for a Magic: The Gathering card. A tranquil enchanted tea garden built around a gently glowing green ley-line that runs through the earth. Rows of luminous tea plants grow in terraces, their leaves shimmering with life energy. Small creatures appear healthier as they enter the garden. Soft morning mist and warm sunlight. Style: Digital painting, peaceful pastoral scene, detailed fantasy art. Color palette: lush greens, warm sunlight, soft morning mist, earthy tones. Aspect ratio: 3:4 portrait. No text, no words, no letters, no card frame."

# --- Card 15: Greenhouse ---
generate_image "greenhouse" \
    "Fantasy illustration for a Magic: The Gathering card. A grand magical greenhouse with crystalline glass walls, inside which plants of impossible colors grow in abundance. The earth beneath glows with mana, and prismatic light refracts through the glass creating rainbow patterns. Vines of pure magical energy climb the walls. Abundant, overflowing growth. Style: Digital painting, lush vibrant interior, detailed fantasy art. Color palette: rich greens, prismatic rainbow light, crystalline clarity, golden warmth. Aspect ratio: 3:4 portrait. No text, no words, no letters, no card frame."

# --- Card 16: Zen Garden ---
generate_image "zen-garden" \
    "Fantasy illustration for a Magic: The Gathering card. A perfectly raked Japanese zen rock garden with an invisible magical barrier shimmering faintly above the raked sand patterns. Warriors attempting to cross are slowed, their feet sinking into the sand. Cherry blossom petals float in still air. Ancient mossy stones arranged in perfect harmony. Absolute tranquility concealing power. Style: Digital painting, serene yet powerful atmosphere, detailed fantasy art. Color palette: muted greens, sand tones, soft pink blossoms, stone grey. Aspect ratio: 3:4 portrait. No text, no words, no letters, no card frame."

# --- Card 17: The Mansion ---
generate_image "the-mansion" \
    "Fantasy illustration for a Magic: The Gathering card. A towering gothic mansion silhouetted against a blood-red moon, its windows glowing with sickly yellow-green light. Dark tendrils of shadow reach out from the doorway, grasping at spectral figures trying to flee. Iron gates slam shut on their own. An aura of inevitable doom and dark aristocratic menace. Style: Digital painting, gothic horror atmosphere, detailed fantasy art. Color palette: deep blacks, blood reds, sickly greens, moonlit silver. Aspect ratio: 3:4 portrait. No text, no words, no letters, no card frame."

# --- Card 18: The Parlor ---
generate_image "the-parlor" \
    "Fantasy illustration for a Magic: The Gathering card. An elegant Victorian parlor room with velvet furniture and a roaring fireplace, but every spoken word materializes as dark wisps that drain life from the speakers. Ghostly figures sit in conversation, growing paler with each exchange. Dark shadows gather in the corners. Deceptively comfortable yet sinister. Style: Digital painting, dark elegant interior, detailed fantasy art. Color palette: deep burgundy, dark blacks, candlelight gold, shadow purple. Aspect ratio: 3:4 portrait. No text, no words, no letters, no card frame."

# --- Card 19: The Cellar ---
generate_image "the-cellar" \
    "Fantasy illustration for a Magic: The Gathering card. A dark stone cellar beneath a mansion, with ancient wine barrels and cobwebs. Ghostly hands reach up through cracks in the floor, and spectral figures rise from shadowy corners, summoned back to a semblance of life. Eerie green necromantic light flickers from rune-carved stones. Chains and old bones litter the floor. Style: Digital painting, underground horror atmosphere, detailed fantasy art. Color palette: dark stone grey, necromantic green, shadow black, rust and bone. Aspect ratio: 3:4 portrait. No text, no words, no letters, no card frame."

# --- Card 20: The Gallery ---
generate_image "the-gallery" \
    "Fantasy illustration for a Magic: The Gathering card. A long gallery hall lined with ornate portrait paintings, each depicting a person in their final moments. As a creature dies nearby, a new painting appears on the wall and knowledge flows to the owner. Ghostly light illuminates each frame. The hall stretches into darkness. Macabre elegance. Style: Digital painting, haunted gallery atmosphere, detailed fantasy art. Color palette: dark blacks, portrait golds, ghostly silver, deep crimson accents. Aspect ratio: 3:4 portrait. No text, no words, no letters, no card frame."

# --- Card 21: Overgrown Manor ---
generate_image "overgrown-manor" \
    "Fantasy illustration for a Magic: The Gathering card. A once-grand manor house being consumed by massive, aggressive vines and dark vegetation. The building is half-reclaimed by nature, with glowing green life energy and dark death energy intertwined. Flowers bloom from skulls on the windowsills. Beautiful and terrifying simultaneously. Dual nature of growth and decay. Style: Digital painting, gothic nature reclamation, detailed fantasy art. Color palette: deep greens and blacks intertwined, purple flowers, bone white, dark earth. Aspect ratio: 3:4 portrait. No text, no words, no letters, no card frame."

# --- Card 22: Tea Master ---
generate_image "tea-master" \
    "Fantasy illustration for a Magic: The Gathering card. A serene elderly human monk in white robes, carefully measuring tea leaves with absolute precision in a tranquil tea ceremony room. Green magical energy flows from the leaves into an ornate teapot, creating a glowing Tea artifact. Bamboo and paper screens in the background. Morning light streams through windows. Style: Digital painting, peaceful ceremonial atmosphere, detailed fantasy art. Color palette: clean whites, warm skin tones, green tea glow, natural bamboo tones. Aspect ratio: 3:4 portrait. No text, no words, no letters, no card frame."

# --- Card 23: Firebrew Adept ---
generate_image "firebrew-adept" \
    "Fantasy illustration for a Magic: The Gathering card. A young fiery-haired shaman rapidly brewing tea over an open flame, moving with supernatural speed. Red fire energy infuses the tea leaves as they swirl in a bubbling cauldron. Sparks fly from their fingertips. Smoky forge-like workshop setting with hanging dried herbs catching fire. Energetic and reckless. Style: Digital painting, dynamic fiery action, detailed fantasy art. Color palette: blazing reds, fire orange, dark smoke, copper tones. Aspect ratio: 3:4 portrait. No text, no words, no letters, no card frame."

# --- Card 24: Scalding Preparation ---
generate_image "scalding-preparation" \
    "Fantasy illustration for a Magic: The Gathering card. A burst of boiling magical water erupting from a kettle, scalding everything nearby with red-hot steam. Tea leaves swirl in the superheated vapor, infused with destructive fire energy. A single spark ignites the scene. Close-up dramatic moment of violent preparation. Style: Digital painting, explosive close-up action, detailed fantasy art. Color palette: scalding reds, steam whites, fire orange, dark background. Aspect ratio: 3:4 portrait. No text, no words, no letters, no card frame."

# --- Card 25: Mindful Steeping ---
generate_image "mindful-steeping" \
    "Fantasy illustration for a Magic: The Gathering card. A peaceful scene of hands gently lowering tea leaves into a bowl of still water, green healing energy radiating outward in concentric circles. The water glows with restorative power. Cherry blossoms drift through the air. A moment of perfect mindful patience. Monastery courtyard at dawn. Style: Digital painting, serene meditative atmosphere, detailed fantasy art. Color palette: soft whites, healing greens, gentle pinks, warm dawn light. Aspect ratio: 3:4 portrait. No text, no words, no letters, no card frame."

# --- Card 26: Kettle of Inspiration ---
generate_image "kettle-of-inspiration" \
    "Fantasy illustration for a Magic: The Gathering card. An ornate bronze and silver kettle floating on a pedestal, steam rising in two spiraling columns — one red fire, one green life energy. The kettle glows from within with dual purpose. Intricate runes circle the vessel. Workshop setting with tools and ingredients. The perfect fusion of destruction and creation. Style: Digital painting, magical artifact focus, detailed fantasy art. Color palette: bronze and silver metallics, dual red and green energy, warm workshop amber. Aspect ratio: 3:4 portrait. No text, no words, no letters, no card frame."

# --- Card 27: Ravenous Guest ---
generate_image "ravenous-guest" \
    "Fantasy illustration for a Magic: The Gathering card. A sinister well-dressed woman at a dark banquet table, crushing an empty ornate teacup in her hand while dark energy drains from it. Her eyes glow with satisfaction as she absorbs the power. Shattered fine china and empty plates surround her. Opulent but menacing dining hall. Style: Digital painting, dark elegant horror, detailed fantasy art. Color palette: deep blacks, dark purples, sickly green eyes, candlelight gold. Aspect ratio: 3:4 portrait. No text, no words, no letters, no card frame."

# --- Card 28: Scalding Sipper ---
generate_image "scalding-sipper" \
    "Fantasy illustration for a Magic: The Gathering card. A wild-eyed goblin warrior chugging from a steaming hot cup mid-battle, fire erupting from its mouth as it drinks. Burns and scorch marks cover its face but it grins maniacally. Battlefield chaos around it. The tea is literally on fire. Reckless and unstoppable. Style: Digital painting, chaotic comedic action, detailed fantasy art. Color palette: fiery reds, goblin green skin, flame orange, battlefield brown. Aspect ratio: 3:4 portrait. No text, no words, no letters, no card frame."

# --- Card 29: Ember Glutton ---
generate_image "ember-glutton" \
    "Fantasy illustration for a Magic: The Gathering card. A fearsome demon with smoldering skin sitting at the head of a dark feast table, devouring enchanted teacups whole. Embers pour from its mouth and eyes. Each consumed cup releases dark red energy that lashes out at nearby figures. Hellish banquet hall with obsidian columns. Style: Digital painting, demonic feast scene, detailed fantasy art. Color palette: ember reds, charcoal blacks, hellfire orange, dark obsidian. Aspect ratio: 3:4 portrait. No text, no words, no letters, no card frame."

# --- Card 30: Etiquette of Stillness ---
generate_image "etiquette-of-stillness" \
    "Fantasy illustration for a Magic: The Gathering card. A formal tea ceremony where all participants sit frozen in perfect stillness, their weapons and power sealed by an invisible force of protocol. Those without teacups appear diminished and weakened. A golden aura of enforced civility fills the room. Rigid formal atmosphere. Style: Digital painting, formal ceremonial restraint, detailed fantasy art. Color palette: pure whites, formal golds, restrained ivory, soft light. Aspect ratio: 3:4 portrait. No text, no words, no letters, no card frame."

# --- Card 31: Ceremony of Reflection ---
generate_image "ceremony-of-reflection" \
    "Fantasy illustration for a Magic: The Gathering card. A mystical tea ceremony where the surface of the tea in each cup acts as a scrying mirror, reflecting the true nature of each drinker. A blue arcane glow emanates from the still water. Participants sit in contemplative silence, constrained by ritual. Circular ceremonial chamber with water features. Style: Digital painting, mystical contemplative atmosphere, detailed fantasy art. Color palette: reflective blues, silver water, dark calm, arcane cyan. Aspect ratio: 3:4 portrait. No text, no words, no letters, no card frame."

# --- Card 32: Code of the Table ---
generate_image "code-of-the-table" \
    "Fantasy illustration for a Magic: The Gathering card. An elegant round table set for a formal tea ceremony, with some seats having ornate place settings and others conspicuously bare. Those without settings struggle to speak, their voices dampened by white and blue magical wards woven into the tablecloth. A stern arbiter oversees the ritual. Style: Digital painting, formal magical protocol, detailed fantasy art. Color palette: whites and blues, silver tableware, formal gold trim, arcane ward glow. Aspect ratio: 3:4 portrait. No text, no words, no letters, no card frame."

# --- Card 33: Fertile Offering ---
generate_image "fertile-offering" \
    "Fantasy illustration for a Magic: The Gathering card. A druid placing a glowing green seed into an opponent's barren field, and lush magical vegetation immediately sprouting. The druid smiles knowingly as the roots connect back to them, channeling life energy with each harvest. Generous yet strategic. Rolling farmland at sunset. Style: Digital painting, warm pastoral generosity, detailed fantasy art. Color palette: rich greens, golden sunset, warm earth, life energy glow. Aspect ratio: 3:4 portrait. No text, no words, no letters, no card frame."

# --- Card 34: Generous Canopy ---
generate_image "generous-canopy" \
    "Fantasy illustration for a Magic: The Gathering card. A massive ancient tree with a spreading canopy that extends over a neighboring territory. The shade nurtures small saproling creatures that grow beneath it, while the roots quietly extend back toward the tree's planter. Dappled sunlight filters through magical leaves. Lush forest border scene. Style: Digital painting, generous natural abundance, detailed fantasy art. Color palette: deep canopy greens, dappled golden light, rich brown bark, sprouting life. Aspect ratio: 3:4 portrait. No text, no words, no letters, no card frame."

# --- Card 35: Gift of the Wellspring ---
generate_image "gift-of-the-wellspring" \
    "Fantasy illustration for a Magic: The Gathering card. A crystalline spring gifted to another's land, its waters glowing with blue and green magical energy. Each time someone drinks from it, knowledge flows back to the one who created it — shown as ethereal blue streams connecting the spring to a distant figure. Enchanted oasis in a meadow. Style: Digital painting, mystical generous gift, detailed fantasy art. Color palette: spring greens, arcane blues, crystal clear water, meadow warmth. Aspect ratio: 3:4 portrait. No text, no words, no letters, no card frame."

# --- Card 36: Porcelain Teapot ---
generate_image "porcelain-teapot" \
    "Fantasy illustration for a Magic: The Gathering card. An exquisitely beautiful but impossibly delicate porcelain teapot being presented as a gift, glowing with blue magical energy. The recipient looks uneasy — the teapot is clearly enchanted with binding magic, a beautiful burden. Intricate floral patterns on the porcelain pulse with arcane light. Formal gift-giving scene. Style: Digital painting, beautiful magical artifact, detailed fantasy art. Color palette: porcelain white and blue, arcane glow, formal setting tones. Aspect ratio: 3:4 portrait. No text, no words, no letters, no card frame."

# --- Card 37: Debt Collector ---
generate_image "debt-collector" \
    "Fantasy illustration for a Magic: The Gathering card. A stern-faced human advisor in formal blue robes, methodically reclaiming enchanted objects from reluctant holders. Loan ledgers float around them and a Tea token materializes as each debt is collected. Cold, efficient, inevitable. Bureaucratic office with magical filing systems. Style: Digital painting, formal bureaucratic authority, detailed fantasy art. Color palette: official blues, ledger parchment, cold silver, formal dark tones. Aspect ratio: 3:4 portrait. No text, no words, no letters, no card frame."

# --- Card 38: Ornamental Vase ---
generate_image "ornamental-vase" \
    "Fantasy illustration for a Magic: The Gathering card. A stunningly beautiful but clearly enchanted ornamental vase, radiating white and blue magical aura. It sits on a shelf in someone else's home, too beautiful to discard but impossible to ignore. When it returns to its maker, it releases a burst of healing light and knowledge. Elegant domestic interior. Style: Digital painting, beautiful enchanted artifact, detailed fantasy art. Color palette: white porcelain, blue arcane patterns, warm interior gold, healing light. Aspect ratio: 3:4 portrait. No text, no words, no letters, no card frame."

echo ""
echo "========================================"
echo "  Generation Complete!"
echo "  Success: $SUCCESS"
echo "  Failed:  $FAIL"
if [ ${#FAILED_CARDS[@]} -gt 0 ]; then
    echo "  Failed cards: ${FAILED_CARDS[*]}"
fi
echo "  Output:  $OUTPUT_DIR/"
echo "========================================"
