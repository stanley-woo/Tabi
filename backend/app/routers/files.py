from fastapi import APIRouter, UploadFile, File, HTTPException
from fastapi.staticfiles import StaticFiles
import uuid, os

router = APIRouter()

# Making sure we have a place to store uploaded files
UPLOAD_DIR = os.path.join(os.path.dirname(__file__), "..", "static")
os.makedirs(UPLOAD_DIR, exist_ok=True)

@router.post("/upload-image", status_code=201)
async def upload_image(file: UploadFile = File(...)):
    """Accepts a single image file and returns a URL where it can be fetched."""
    ext = os.path.splitext(file.filename)[1].lower()
    if ext not in {".jpg", ".jpeg", ".png", ".gif"}:
        raise HTTPException(400, "Invalid image type.")
     
    new_name = f"{uuid.uuid4()}{ext}"
    out_path = os.path.join(UPLOAD_DIR, new_name)
    content = await file.read()
    with open(out_path, "wb") as f:
        f.write(content)
    return {"url": f"/static/{new_name}"}
    
