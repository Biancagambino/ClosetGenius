import os
import re
import sys
import types
import importlib.machinery
import tempfile

import torch
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from PIL import Image
from transformers import AutoProcessor, AutoModelForCausalLM
from groq import Groq

# ──────────────────────────────────────────────
# flash_attn mock (Florence-2 checks for it)
# ──────────────────────────────────────────────
_mock = types.ModuleType("flash_attn")
_mock.__spec__ = importlib.machinery.ModuleSpec("flash_attn", None)
for _mod in ["flash_attn", "flash_attn.flash_attn_interface",
             "flash_attn.bert_padding", "flash_attn.flash_attn_utils"]:
    sys.modules[_mod] = _mock

# ──────────────────────────────────────────────
# Florence-2 — lazy loaded on first /scan request
# ──────────────────────────────────────────────
FLORENCE_MODEL_ID = "microsoft/Florence-2-base"
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
dtype = torch.float16 if torch.cuda.is_available() else torch.float32

florence_model = None
florence_processor = None

def _load_florence():
    global florence_model, florence_processor
    if florence_model is not None:
        return
    print(f"Loading Florence-2 on {device} ({dtype})...")
    florence_model = AutoModelForCausalLM.from_pretrained(
        FLORENCE_MODEL_ID,
        torch_dtype=dtype,
        trust_remote_code=True,
        attn_implementation="eager",
    )
    florence_model.config.forced_bos_token_id = None
    florence_model = florence_model.to(device)
    florence_model.eval()
    florence_processor = AutoProcessor.from_pretrained(
        FLORENCE_MODEL_ID, trust_remote_code=True
    )
    print("Florence-2 ready.")

# ──────────────────────────────────────────────
# Groq / Llama
# ──────────────────────────────────────────────
GROQ_API_KEY = os.environ["GROQ_API_KEY"]
GROQ_MODEL = "llama-3.3-70b-versatile"
groq_client = Groq(api_key=GROQ_API_KEY)
print(f"Groq client ready: {GROQ_MODEL}")

# ──────────────────────────────────────────────
# Label maps
# ──────────────────────────────────────────────
CATEGORY_MAP = {
    "t-shirt": "Tshirts", "tshirt": "Tshirts", "tee": "Tshirts",
    "shirt": "Shirts", "blouse": "Tops", "top": "Tops",
    "tank": "Tops", "camisole": "Tops",
    "dress": "Dresses", "gown": "Dresses", "maxi": "Dresses",
    "skirt": "Skirts", "midi": "Skirts",
    "jeans": "Jeans", "denim": "Jeans",
    "pants": "Trousers", "trousers": "Trousers", "chinos": "Trousers",
    "shorts": "Shorts", "leggings": "Leggings",
    "joggers": "Track Pants", "sweatpants": "Track Pants",
    "jacket": "Jackets", "coat": "Jackets", "blazer": "Blazers",
    "hoodie": "Sweatshirts", "sweatshirt": "Sweatshirts",
    "sweater": "Sweaters", "pullover": "Sweaters", "cardigan": "Sweaters",
    "vest": "Waistcoat", "waistcoat": "Waistcoat",
    "sneakers": "Sports Shoes", "sneaker": "Sports Shoes",
    "shoes": "Casual Shoes", "loafers": "Casual Shoes", "boots": "Casual Shoes",
    "heels": "Heels", "pumps": "Heels",
    "sandals": "Sandals", "flip flops": "Flip Flops", "flats": "Casual Shoes",
    "watch": "Watches", "bag": "Handbags", "handbag": "Handbags",
    "purse": "Handbags", "backpack": "Backpacks",
    "belt": "Belts", "tie": "Ties",
    "hat": "Caps", "cap": "Caps", "beanie": "Caps",
    "sunglasses": "Sunglasses",
    "earrings": "Earrings", "necklace": "Necklace and Chains",
    "scarf": "Scarves", "socks": "Socks",
    "kurta": "Kurtas", "saree": "Sarees",
    "jumpsuit": "Jumpsuit", "tracksuit": "Tracksuits",
    "swimsuit": "Swimwear", "bikini": "Swimwear",
}

COLOUR_MAP = {
    "black": "Black", "white": "White",
    "blue": "Blue", "navy": "Navy Blue",
    "red": "Red", "maroon": "Maroon", "burgundy": "Maroon",
    "green": "Green", "olive": "Green",
    "yellow": "Yellow", "mustard": "Yellow",
    "orange": "Orange",
    "purple": "Purple", "violet": "Purple", "lavender": "Lavender",
    "pink": "Pink", "rose": "Pink", "coral": "Pink",
    "brown": "Brown", "tan": "Brown", "camel": "Brown",
    "grey": "Grey", "gray": "Grey", "charcoal": "Grey",
    "beige": "Beige", "cream": "Cream",
    "gold": "Gold", "silver": "Silver",
    "teal": "Teal", "turquoise": "Teal",
    "khaki": "Khaki",
}

SEASON_MAP = {
    "summer": "Summer", "lightweight": "Summer", "sleeveless": "Summer",
    "winter": "Winter", "wool": "Winter", "knit": "Winter",
    "fall": "Fall", "autumn": "Fall",
    "spring": "Spring", "trench": "Spring",
    "coat": "Winter", "puffer": "Winter",
    "shorts": "Summer", "hoodie": "Fall",
}

USAGE_MAP = {
    "casual": "Casual", "everyday": "Casual",
    "formal": "Formal", "business": "Formal", "office": "Formal",
    "sports": "Sports", "athletic": "Sports", "gym": "Sports",
    "workout": "Sports", "activewear": "Sports",
    "ethnic": "Ethnic", "traditional": "Ethnic",
    "party": "Party", "evening": "Party",
    "smart casual": "Smart Casual",
    "travel": "Travel",
    "home": "Home", "lounge": "Home",
}

FASHION_KEYWORDS = {
    "shirt", "blouse", "dress", "pants", "jeans", "jacket", "coat",
    "skirt", "sweater", "hoodie", "shorts", "suit", "vest", "top",
    "red", "blue", "green", "black", "white", "gray", "grey", "pink",
    "yellow", "orange", "purple", "brown", "navy", "beige", "cream",
    "striped", "floral", "plaid", "solid", "printed", "patterned",
    "casual", "formal", "sporty", "elegant", "slim", "oversized",
    "cotton", "denim", "wool", "silk", "polyester", "linen",
    "long", "short", "sleeveless", "cropped", "fitted", "loose",
}


# ──────────────────────────────────────────────
# Helper functions
# ──────────────────────────────────────────────
def _run_florence_task(image: Image.Image, task_prompt: str, text_input: str = "") -> str:
    _load_florence()
    inputs = florence_processor(
        text=task_prompt + text_input, images=image, return_tensors="pt"
    )
    inputs = {k: v.to(device) for k, v in inputs.items()}
    if "pixel_values" in inputs:
        inputs["pixel_values"] = inputs["pixel_values"].to(dtype)
    with torch.no_grad():
        output_ids = florence_model.generate(**inputs, max_new_tokens=128, do_sample=False)
    output_text = florence_processor.batch_decode(output_ids, skip_special_tokens=False)[0]
    parsed = florence_processor.post_process_generation(
        output_text, task=task_prompt, image_size=(image.width, image.height)
    )
    return parsed.get(task_prompt, "")


def describe_image(image: Image.Image) -> dict:
    caption = _run_florence_task(image, "<CAPTION>")
    detailed = _run_florence_task(image, "<DETAILED_CAPTION>")
    words = re.findall(r"\b[a-zA-Z]{3,}\b", detailed.lower())
    tags = list({w for w in words if w in FASHION_KEYWORDS})
    return {"caption": caption, "detailed_caption": detailed, "tags": tags}


def extract_labels(florence_result: dict) -> dict:
    tags = [t.lower() for t in florence_result.get("tags", [])]
    all_text = (
        florence_result.get("detailed_caption", "")
        + " "
        + florence_result.get("caption", "")
    ).lower()
    words = set(tags) | set(re.findall(r"\b[a-zA-Z]{3,}\b", all_text))
    word_list = re.findall(r"\b[a-zA-Z]{3,}\b", all_text)
    bigrams = {f"{word_list[i]} {word_list[i+1]}" for i in range(len(word_list) - 1)}

    def first_match(mapping):
        for phrase in bigrams:
            if phrase in mapping:
                return mapping[phrase]
        for word in words:
            if word in mapping:
                return mapping[word]
        return None

    return {
        "category": first_match(CATEGORY_MAP) or "Tops",
        "color": first_match(COLOUR_MAP) or "Black",
        "season": first_match(SEASON_MAP) or "Summer",
        "usage": first_match(USAGE_MAP) or "Casual",
    }


def build_system_prompt(closet_items: list) -> str:
    if not closet_items:
        desc = "The user's closet is currently empty."
    else:
        lines = []
        for item in closet_items:
            parts = [
                item.get("name", ""),
                f"({item.get('category', '')})",
                item.get("color", ""),
                item.get("style", ""),
                item.get("formality", ""),
            ]
            if item.get("notes"):
                parts.append(f'— "{item["notes"]}"')
            if item.get("custom_tags"):
                parts.append(f'[{", ".join(item["custom_tags"])}]')
            lines.append(" | ".join(p for p in parts if p))
        desc = "\n".join(f"- {l}" for l in lines)
    return (
        "You are ClosetGenius Assistant, a friendly personal stylist AI.\n"
        f"USER'S CLOSET:\n{desc}\n"
        "Suggest specific items from the closet by name. Group into complete outfits.\n"
        "Keep responses concise and friendly (under 250 words). Never invent items."
    )


# ──────────────────────────────────────────────
# FastAPI app
# ──────────────────────────────────────────────
app = FastAPI(title="ClosetGenius API")


@app.get("/health")
def health():
    return {"status": "ok", "models": ["Florence-2", "Llama-3.3-70b"]}


@app.post("/scan")
async def scan(image: UploadFile = File(...)):
    contents = await image.read()
    with tempfile.NamedTemporaryFile(suffix=".jpg", delete=False) as tmp:
        tmp.write(contents)
        tmp_path = tmp.name
    try:
        pil_image = Image.open(tmp_path).convert("RGB")
        florence_result = describe_image(pil_image)
        labels = extract_labels(florence_result)
        return {
            "category": labels["category"],
            "color": labels["color"],
            "season": labels["season"],
            "usage": labels["usage"],
            "description": florence_result.get("detailed_caption", ""),
            "tags": florence_result.get("tags", []),
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        os.unlink(tmp_path)


class ChatMessage(BaseModel):
    role: str
    content: str


class ChatRequest(BaseModel):
    message: str
    closet: list = []
    history: list[ChatMessage] = []


@app.post("/chat")
def chat(body: ChatRequest):
    if not body.message.strip():
        raise HTTPException(status_code=400, detail="Missing 'message' field")
    conversation = [
        {"role": "system", "content": build_system_prompt(body.closet)},
        *[{"role": m.role, "content": m.content} for m in body.history],
        {"role": "user", "content": body.message},
    ]
    try:
        response = groq_client.chat.completions.create(
            model=GROQ_MODEL,
            messages=conversation,
            max_tokens=512,
            temperature=0.7,
        )
        return {"reply": response.choices[0].message.content}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
