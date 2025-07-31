import os
from dotenv import load_dotenv
from sqlmodel import SQLModel, create_engine, Session
from sqlalchemy.pool import StaticPool

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL","postgresql://tabi:tabipass@db:5432/tabi")
# DATABASE_URL = os.getenv("DATABASE_URL")
# engine = create_engine(DATABASE_URL, echo=True)

"""Create the engine. If using SQLite in-memory, ensure the same connection is shared."""
if DATABASE_URL.startswith("sqlite"):
    engine = create_engine(DATABASE_URL,echo=True,connect_args={"check_same_thread": False},poolclass=StaticPool)
else:
    engine = create_engine(DATABASE_URL, echo=True)

def get_session():
    with Session(engine) as session:
        yield session

def init_db():
    SQLModel.metadata.create_all(engine)
