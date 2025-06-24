from fastapi import FastAPI, Depends, HTTPException, Path
from sqlmodel import Session, select
from slugify import slugify
from .models import User, Itinerary
from .schemas import UserCreate, ItineraryCreate, UserRead, ItineraryRead, ItineraryUpdate
from .database import init_db, get_session
import uuid

app = FastAPI()

@app.on_event("startup")
def on_startup():
    init_db()

def generate_unique_slug(title: str, user_id : int, session: Session) -> str:
    base_slug = slugify(title)
    slug = base_slug
    i = 1
    while session.exec(select(Itinerary).where(Itinerary.slug == slug, Itinerary.creator_id == user_id)).first():
        slug = f"{base_slug}-{i}"
        i += 1
    return slug


# Post Methods
@app.post("/users/", response_model=UserRead)
def create_user(user: UserCreate, session: Session = Depends(get_session)):
    db_user = User(username=user.username)
    session.add(db_user)
    session.commit()
    session.refresh(db_user)
    return db_user

@app.post("/itineraries/", response_model = ItineraryRead)
def create_itinerary(itin: ItineraryCreate, session: Session = Depends(get_session)):
    slug = generate_unique_slug(itin.title, itin.creator_id ,session)
    itinerary = Itinerary(**itin.dict(), slug=slug)
    session.add(itinerary)
    try:
        session.commit()
    except IntegrityError:
        session.rollback()
        raise HTTPException(status_code=400, detail="Itinerary with this title already exists for this user.")
    session.refresh(itinerary)
    return itinerary

# Get Methods
@app.get("/users", response_model=list[UserRead])
def list_user(session: Session = Depends(get_session)):
    return session.exec(select(User)).all()

@app.get("/itineraries/", response_model = list[ItineraryRead])
def list_itineraries(session: Session = Depends(get_session)):
    return session.exec(select(Itinerary)).all()

@app.get("/users/{username}", response_model = UserRead)
def get_user_by_username(username: str, session : Session = Depends(get_session)):
    user = session.exec(select(User).where(User.username == username)).first()

    if not user:
        raise HTTPException(status_code = 404, detail = "User Not Found.")
    
    return user

@app.get("/users/{username}/itineraries", response_model = list[ItineraryRead])
def get_user_itineraries(username: str, session: Session = Depends(get_session)):
    user = session.exec(select(User).where(User.username == username)).first()
    if not user:
        raise HTTPException(status_code = 404, detail = "User Not Found.")
    
    itineraries = session.exec(select(Itinerary).where(Itinerary.creator_id == user.id)).all()
    return itineraries

@app.get("/users/{username}/itineraries/{slug}", response_model=ItineraryRead)
def get_user_itinerary_by_slug(username: str, slug: str, session: Session = Depends(get_session)):
    user = session.exec(select(User).where(User.username == username)).first()
    if not user:
        raise HTTPException(status_code = 404, detail = "User Not Found.")

    itinerary = session.exec(select(Itinerary).where(Itinerary.creator_id == user.id, Itinerary.slug == slug)).first()
    if not itinerary:
        raise HTTPException(status_code = 404, detail = "Itinerary Not Found.")
    
    return itinerary

# Patch Methods
@app.patch("/itineraries/{id}", response_model=ItineraryRead)
def update_itinerary(id: int, itin_update: ItineraryUpdate, session: Session = Depends(get_session)):
    itinerary = session.get(Itinerary, id)
    if not itinerary:
        raise HTTPException(status_code = 404, detail="Itinerary Not Found.")
    
    update_data = itin_update.dict(exclude_unset = True)
    for key, value in update_data.items():
        setattr(itinerary, key, value)
    # Just like:
    # if "visibility" in update_data:
    # itinerary.visibility = update_data["visibility"]
    
    session.add(itinerary)
    session.commit()
    session.refresh(itinerary)
    return itinerary