from typing import List
from sqlmodel import Session, select
from sqlmodel import Session, select
from slugify import slugify
from .models import Itinerary, ItineraryBlock
from fastapi import HTTPException, status
from .database import engine

def create_block(itinerary_id: int, order: int, type: str, content: str, session: Session) -> ItineraryBlock:
    block = ItineraryBlock(itinerary_id = itinerary_id, order = order, type = type, content = content)

    with Session(engine) as session:
        session.add(block)
        session.commit()
        session.refresh(block)
        return block

def get_blocks(itinerary_id: int) -> List[ItineraryBlock]:
    with Session(engine) as session:
        stmt = (select(ItineraryBlock).where(ItineraryBlock.itinerary_id == itinerary_id).order_by(ItineraryBlock.order))
        return session.exec(stmt).all()
    
def generate_unique_slug(title: str, creator_id: int, session: Session) -> str:
    base_slug = slugify(title)
    slug = base_slug
    counter = 1
    # keep appending -1, -2, etc until we find a free slug for this user
    while session.exec(
        select(Itinerary)
        .where(
            Itinerary.slug == slug,
            Itinerary.creator_id == creator_id
        )
    ).first():
        slug = f"{base_slug}-{counter}"
        counter += 1
    return slug

def fork_itinerary(original_id: int, new_creator_id: int, session: Session) -> Itinerary:
    # load the original
    original = session.get(Itinerary, original_id)
    if not original:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,
                            detail="Original Itinerary not found")
    # build a new title, slug, tags, parent_id exactly as you did before
    new_title = f"{original.title} (forked)"
    suffix = 1
    while session.exec(
        select(Itinerary)
        .where(
            Itinerary.title == new_title,
            Itinerary.creator_id == new_creator_id
        )
    ).first():
        suffix += 1
        new_title = f"{original.title} (forked {suffix})"
    new_slug = slugify(new_title) + f"-{new_creator_id}"

    forked = Itinerary(
        title=new_title,
        description=original.description,
        visibility=original.visibility,
        creator_id=new_creator_id,
        slug=new_slug,
        tags=list(original.tags) if original.tags else [],
        parent_id=original.id
    )
    session.add(forked)
    session.commit()
    session.refresh(forked)
    return forked