import os
import uuid
from fastapi import APIRouter, UploadFile, File, HTTPException, status
from fastapi.staticfiles import StaticFiles

router = APIRouter(prefix="/files", tags=["files"])

# Ensure upload directory exists
UPLOAD_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "static"))
os.makedirs(UPLOAD_DIR, exist_ok=True)

# Serve uploaded files at /static
router.mount("/static", StaticFiles(directory=UPLOAD_DIR), name="static")

@router.post("/upload-image", status_code=status.HTTP_201_CREATED)
async def upload_image(file: UploadFile = File(...)):
    """Accept a single image and return its public URL."""
    ext = os.path.splitext(file.filename)[1].lower()
    if ext not in {".jpg", ".jpeg", ".png", ".gif"}:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid image type")
    filename = f"{uuid.uuid4()}{ext}"
    path = os.path.join(UPLOAD_DIR, filename)
    content = await file.read()
    with open(path, "wb") as out:
        out.write(content)
    return {"url": f"/static/{filename}"}
