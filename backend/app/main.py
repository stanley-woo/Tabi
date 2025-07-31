import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from contextlib import asynccontextmanager

from .database import init_db
from .routers import users, itineraries, blocks, files, day_groups

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Initialize DB once at startup
    init_db()
    yield
    # (Optional) cleanup at shutdown

app = FastAPI(title="Tabi API", lifespan=lifespan)

# CORS — allow Flutter or other clients to call this API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Compute an absolute, file-relative path to backend/app/static
BASE_DIR = os.path.dirname(__file__)
STATIC_DIR = os.path.join(BASE_DIR, "static")
# Create that folder if it doesn’t already exist
os.makedirs(STATIC_DIR, exist_ok=True)
# Mount it under /static
app.mount("/static",StaticFiles(directory=STATIC_DIR), name="static")

# --- Register routers (each defines its own prefix & tags) ---
app.include_router(users.router)
app.include_router(itineraries.router)
app.include_router(blocks.router)
app.include_router(files.router)
app.include_router(day_groups.router)