# backend/app/main.py

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from contextlib import asynccontextmanager

from .database import init_db
from .routers import users, itineraries, blocks, files

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Run once at startup
    init_db()
    yield
    # (Optional) cleanup at shutdown

app = FastAPI(
    title="Tabi API",
    lifespan=lifespan,
)

# CORS — allow your Flutter app to call this API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/static", StaticFiles(directory = "app/static"), name= "static")

# Mount each router under its own prefix
app.include_router(users.router,       prefix="", tags=["users"])
app.include_router(itineraries.router, prefix="", tags=["itineraries"])
app.include_router(blocks.router,      prefix="", tags=["blocks"])
app.include_router(files.router,       prefix="", tags=["files"])

# from fastapi import FastAPI, Depends, HTTPException, Path, status, Body, Query
# # from pydantic import BaseModel
# from sqlmodel import Session, select
# from sqlalchemy.orm import selectinload
# from slugify import slugify
# from sqlalchemy import or_
# from sqlalchemy.exc import IntegrityError
# from typing import Optional
# from .models import User, Itinerary
# from .schemas import UserCreate, ItineraryCreate, UserRead, ItineraryRead, ItineraryUpdate, ItineraryDelete, ItineraryFork, ItineraryBlockCreate, ItineraryBlockRead
# from .crud import get_blocks, create_block
# from .database import init_db, get_session
# import uuid
# from fastapi.middleware.cors import CORSMiddleware

# app = FastAPI()

# app.add_middleware(
#   CORSMiddleware,
#   allow_origins=["*"], 
#   allow_methods=["*"],
#   allow_headers=["*"],
# )

# @app.on_event("startup")
# def on_startup():
#     init_db()

# def generate_unique_slug(title: str, user_id : int, session: Session) -> str:
#     base_slug = slugify(title)
#     slug = base_slug
#     i = 1
#     while session.exec(select(Itinerary).where(Itinerary.slug == slug, Itinerary.creator_id == user_id)).first():
#         slug = f"{base_slug}-{i}"
#         i += 1
#     return slug


# # Post Methods
# @app.post("/users/", response_model=UserRead)
# def create_user(user: UserCreate, session: Session = Depends(get_session)):
#     db_user = User(username=user.username)
#     session.add(db_user)
#     session.commit()
#     session.refresh(db_user)
#     return db_user

# @app.post("/itineraries/", response_model = ItineraryRead)
# def create_itinerary(itin: ItineraryCreate, session: Session = Depends(get_session)):
#     slug = generate_unique_slug(itin.title, itin.creator_id ,session)
#     itinerary = Itinerary(**itin.dict(), slug=slug)
#     session.add(itinerary)
#     try:
#         session.commit()
#     except IntegrityError:
#         session.rollback()
#         raise HTTPException(status_code=409, detail="Itinerary with this title already exists for this user.")
#     session.refresh(itinerary)
#     return itinerary

# @app.post("/itineraries/{id}/fork", response_model = ItineraryRead, status_code=status.HTTP_201_CREATED)
# def fork_itinerary(id: int, fork_data: ItineraryFork, session : Session = Depends(get_session)):
#     original = session.get(Itinerary, id)

#     if not original:
#         raise HTTPException(status_code=404, detail="Original Itinerary Not Found.")

#     new_title = f"{original.title} (forked)"
#     suffix = 1
#     while session.exec(
#         select(Itinerary).where(
#             Itinerary.title == new_title,
#             Itinerary.creator_id == fork_data.creator_id
#         )
#     ).first():
#         suffix += 1
#         new_title = f"{original.title} (forked {suffix})"

#     forked = Itinerary(title = new_title, description=original.description, visibility=original.visibility, 
#                        creator_id=fork_data.creator_id, slug=slugify(new_title)+f"-{fork_data.creator_id}", tags=original.tags.copy() if original.tags else [],
#                        parent_id=original.id)

#     session.add(forked)
#     session.commit()
#     session.refresh(forked)
#     return forked

# @app.post("/itineraries/{it_id}/blocks", response_model=ItineraryBlockRead, status_code=status.HTTP_201_CREATED)
# def post_block(it_id: int, block_in: ItineraryBlockCreate, session: Session = Depends(get_session)):
#     if not session.get(Itinerary, it_id):
#         raise HTTPException(status_code = 404, detail = "Itinerary not found.")
#     return create_block(itinerary_id=it_id, order= block_in.order, type=block_in.type, content=block_in.content)


# # Get Methods
# @app.get("/users", response_model=list[UserRead])
# def list_user(session: Session = Depends(get_session)):
#     return session.exec(select(User)).all()

# @app.get("/itineraries/", response_model = list[ItineraryRead])
# def list_itineraries(session: Session = Depends(get_session), tags: Optional[str] = Query(None, description="Comma-separated tags"),
#                      search: Optional[str] = Query(None, description="Search String"), limit: int = Query(20, ge=1), offset: int = Query(0, ge=0),):
#     query = select(Itinerary).where(Itinerary.visibility == "public")

#     if tags:
#         tag_list = tags.split(",")
#         query = query.where(Itinerary.tags.contains(tag_list))
    
#     if search:
#         search_term = f"%{search.lower()}%"
#         query = query.where(
#             or_(
#                 Itinerary.title.ilike(search_term),
#                 Itinerary.description.ilike(search_term)
#             )
#         )
    
#     query = query.offset(offset).limit(limit)
#     results = session.exec(query).all()
#     return results

# @app.get("/users/{username}", response_model = UserRead)
# def get_user_by_username(username: str, session : Session = Depends(get_session)):
#     user = session.exec(select(User).where(User.username == username)).first()

#     if not user:
#         raise HTTPException(status_code = 404, detail = "User Not Found.")
    
#     return user

# @app.get("/users/{username}/itineraries", response_model = list[ItineraryRead])
# def get_user_itineraries(username: str, session: Session = Depends(get_session)):
#     user = session.exec(select(User).where(User.username == username)).first()
#     if not user:
#         raise HTTPException(status_code = 404, detail = "User Not Found.")
    
#     itineraries = session.exec(select(Itinerary).where(Itinerary.creator_id == user.id)).all()
#     return itineraries

# @app.get("/users/{username}/itineraries/{slug}", response_model=ItineraryRead)
# def get_user_itinerary_by_slug(username: str, slug: str, session: Session = Depends(get_session)):
#     user = session.exec(select(User).where(User.username == username)).first()
#     if not user:
#         raise HTTPException(status_code = 404, detail = "User Not Found.")

#     itinerary = session.exec(select(Itinerary).where(Itinerary.creator_id == user.id, Itinerary.slug == slug)).first()
#     if not itinerary:
#         raise HTTPException(status_code = 404, detail = "Itinerary Not Found.")
    
#     return itinerary

# @app.get("/itineraries/{id}", response_model=ItineraryRead, status_code=status.HTTP_200_OK)
# def read_itinerary(id: int = Path(..., description="The ID of the itinerary to retrieve"), session: Session = Depends(get_session)):
#     stmt = (
#         select(Itinerary)
#         .options(selectinload(Itinerary.blocks))
#         .where(Itinerary.id == id)
#     )

#     itinerary = session.exec(stmt).one_or_none()
#     if not itinerary:
#         raise HTTPException(status_code=404, detail="Itinerary not found")
#     return itinerary

# # Patch Methods
# @app.patch("/itineraries/{id}", response_model=ItineraryRead)
# def update_itinerary(id: int, itin_update: ItineraryUpdate, session: Session = Depends(get_session)):
#     itinerary = session.get(Itinerary, id)
#     if not itinerary:
#         raise HTTPException(status_code = 404, detail="Itinerary Not Found.")
    
#     update_data = itin_update.dict(exclude_unset = True)
#     for key, value in update_data.items():
#         setattr(itinerary, key, value)
#     # Just like:
#     # if "visibility" in update_data:
#     # itinerary.visibility = update_data["visibility"]
    
#     session.add(itinerary)
#     session.commit()
#     session.refresh(itinerary)
#     return itinerary

# # Delete Methods
# @app.delete("/itineraries/{id}", status_code=status.HTTP_204_NO_CONTENT)
# def delete_itinerary(id: int, delete_req: ItineraryDelete = Body(...), session: Session = Depends(get_session)):
#     itinerary = session.get(Itinerary, id)

#     if not itinerary:
#         raise HTTPException(status_code = 404, detail = "Itinerary Not Found.")
    
#     if itinerary.creator_id != delete_req.creator_id:
#         raise HTTPException(status_code = 403, detail = "Not Authorized To Delete This Itinerary.")
    
#     session.delete(itinerary)
#     session.commit()