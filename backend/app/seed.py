# backend/app/seed.py
import asyncio
from sqlmodel import Session, select
from app.database import engine
from app import crud, schemas
from datetime import date

async def seed_data():
    """
    Seeds the database with users (including passwords) and rich itineraries.
    This script is idempotent and works with the original crud.py.
    """
    print("🌱 Starting database seeding with clean data...")

    # In backend/app/seed.py

    users_to_create = [
        {
            "username": "julieee_mun", "email": "julie@tabi.app", "display_name": "Julie Mun",
            "bio": "Music lover 🎵 | Coastal drives 🌊 | California dreaming",
            "avatar_name": "Julie.jpg",
            "header_url": "http://localhost:8000/static/Julie.jpg"
        },
        {
            "username": "sarah_kuo", "email": "sarah@tabi.app", "display_name": "Sarah Kuo",
            "bio": "Tokyo wanderer 🗾 | Onsen enthusiast ♨️ | Street food hunter",
            "avatar_name": "Sarah.jpg",
            "header_url": "http://localhost:8000/static/Sarah.jpg"
        },
        {
            "username": "savannah_demers", "email": "savannah@tabi.app", "display_name": "Savannah Demers",
            "bio": "Film photographer 📸 | Road trip planner 🚗 | Sunset chaser",
            "avatar_name": "assets/savannah_demers_icons.jpg",
            "header_url": "assets/savannah_demers_cover.jpg"
        },
        {
            "username": "pikachu", "email": "pikachu@tabi.app", "display_name": "Pikachu",
            "bio": "⚡ Adventure seeker | Photo spots finder | Spreading joy worldwide",
            "avatar_name": "assets/pikachu_profile.jpg",
            "header_url": "assets/pikachu_champ.jpg"
        },
        {
            "username": "demo", "email": "demo@tabi.app", "display_name": "Demo User",
            "bio": "Just here to explore!"
        }
    ]
    
    itineraries_to_create = [
        {
            "creator_username": "julieee_mun",
            "title": "Big Sur & Coastal Charm: A 3-Day Road Trip",
            "description": "A long weekend escape down California's iconic Highway 1. We chased sunsets, found hidden coffee shops, and let the ocean breeze guide us. Here's how to do it right.",
            "tags": ["California", "Road Trip", "Hiking", "Photography", "Coast"],
            "visibility": "public",
            "days": [
                {
                    "date": "2025-08-16", "title": "Day 1: Carmel's Fairytale Vistas",
                    "blocks": [
                        {"type": "text", "content": "Started the day early to beat the traffic out of the city. First stop: Carmel-by-the-Sea. It feels like stepping into a storybook. Grabbed an amazing latte at Carmel Valley Coffee Roasting Co."},
                        {"type": "image", "content": "https://images.unsplash.com/photo-1593962266236-8aca3b19b646?q=80&w=2940&auto=format&fit=crop"},
                        {"type": "text", "content": "Spent the afternoon walking along the stunning Carmel Beach. The white sand is incredible, and it's super dog-friendly!"},
                        {"type": "map", "content": "36.5552,-121.9233"}
                    ]
                },
                {
                    "date": "2025-08-17", "title": "Day 2: The Heart of Big Sur",
                    "blocks": [
                        {"type": "image", "content": "https://images.unsplash.com/photo-1521352321946-4a10d21a2ed4?q=80&w=2874&auto=format&fit=crop"},
                        {"type": "text", "content": "The main event! Driving Highway 1 through Big Sur is breathtaking. We stopped at every viewpoint, but the iconic Bixby Creek Bridge was a highlight. Pro tip: go early to avoid the crowds."},
                        {"type": "text", "content": "Lunch was at Nepenthe, which has an absolutely insane cliffside view. A bit pricey, but worth it for the experience. Hiked down to McWay Falls in the afternoon to see the waterfall cascading onto the beach."},
                        {"type": "map", "content": "36.2372,-121.7829"}
                    ]
                }
            ]
        },
        {
            "creator_username": "sarah_kuo",
            "title": "48 Hours in Tokyo: Shrines, Shibuya, and Skylines",
            "description": "My whirlwind weekend in one of the world's most exciting cities. From ancient temples to neon-drenched streets, here's my guide to seeing the best of Tokyo in just two days.",
            "tags": ["Tokyo", "Japan", "City Guide", "Food", "Culture"],
            "visibility": "public",
            "days": [
                {
                    "date": "2025-09-20", "title": "Day 1: Tradition & Modernity",
                    "blocks": [
                        {"type": "text", "content": "Morning started with a peaceful walk through Meiji Jingu shrine. It's amazing how quiet and serene it is right next to the bustling city. From there, we dove into the vibrant chaos of Harajuku's Takeshita Street."},
                        {"type": "image", "content": "https://images.unsplash.com/photo-1542051841857-5f90071e7989?q=80&w=2940&auto=format&fit=crop"},
                        {"type": "text", "content": "In the afternoon, we headed to Shibuya to witness the famous scramble crossing. We grabbed a coffee at Starbucks overlooking the intersection to get the best view. It's mesmerizing!"},
                        {"type": "map", "content": "35.6591,139.7006"}
                    ]
                },
                {
                    "date": "2025-09-21", "title": "Day 2: Markets and High Views",
                    "blocks": [
                        {"type": "text", "content": "Woke up at the crack of dawn to visit the Tsukiji Outer Market for the freshest sushi breakfast imaginable. It's a sensory overload in the best way possible."},
                        {"type": "map", "content": "35.6655,139.7709"},
                        {"type": "text", "content": "Ended the trip by going up the Tokyo Skytree for a panoramic view of the entire city. Seeing Mount Fuji in the distance as the sun set was the perfect way to say goodbye."},
                        {"type": "image", "content": "https://images.unsplash.com/photo-1536098561742-ca998e48cbcc?q=80&w=2835&auto=format&fit=crop"}
                    ]
                }
            ]
        }
    ]

    with Session(engine) as session:
        print(f"👥 Creating {len(users_to_create)} users with default password 'password'...")
        for user_data in users_to_create:
            if not crud.get_user_by_username(session, username=user_data["username"]):
                db_user = crud.create_user_with_password(
                    session=session,
                    username=user_data["username"],
                    email=user_data["email"],
                    password="password"
                )
                
                db_user.display_name = user_data.get("display_name")
                db_user.bio = user_data.get("bio")
                db_user.avatar_name = user_data.get("avatar_name")
                db_user.header_url = user_data.get("header_url")
                session.add(db_user)
                session.commit()
        print("✅ Users created.")

        print(f"\n🗺️  Creating {len(itineraries_to_create)} itineraries...")
        for itin_data in itineraries_to_create:
            creator = crud.get_user_by_username(session, username=itin_data["creator_username"])
            if not creator: continue

            if not session.exec(select(crud.Itinerary).where(crud.Itinerary.title == itin_data["title"], crud.Itinerary.creator_id == creator.id)).first():
                itinerary_in_data = itin_data.copy()
                itinerary_in_data['creator_id'] = creator.id
                days_data = itinerary_in_data.pop('days', [])
                del itinerary_in_data['creator_username']
                
                itinerary_in = schemas.ItineraryCreate(**itinerary_in_data)
                db_itinerary = crud.create_itinerary(session=session, data=itinerary_in)

                auto_day_one = session.exec(select(crud.DayGroup).where(crud.DayGroup.itinerary_id == db_itinerary.id)).first()
                if auto_day_one:
                    crud.delete_day_group(session, day_id=auto_day_one.id)

                for day_order, day_data in enumerate(days_data, 1):
                    day_group_in = schemas.DayGroupCreate(
                        date=date.fromisoformat(day_data["date"]),
                        title=day_data["title"],
                        order=day_order
                    )
                    db_day_group = crud.create_day_group(session, db_itinerary.id, day_group_in)

                    for block_order, block_data in enumerate(day_data["blocks"], 1):
                        crud.create_block(session, db_day_group.id, block_order, block_data["type"], block_data["content"])
        
        print("✅ Itineraries created.")
        print("\n🎉 Database seeding complete!")

if __name__ == "__main__":
    asyncio.run(seed_data())
# # database_cleanup.py
# """
# PostgreSQL + SQLModel Database Cleanup Script for Tabi
# ========================================================
# This script connects to your PostgreSQL database and cleans up test data
# """

# import os
# import json
# from datetime import datetime
# from dotenv import load_dotenv
# from sqlmodel import Session, create_engine, text

# # Load environment variables
# load_dotenv()

# # Since you're running in Docker, use the Docker network name 'db'
# DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://tabi:tabipass@db:5432/tabi")

# def create_backup(engine):
#     """
#     Export current data as JSON backup before making changes
#     """
#     print("📦 Creating JSON backup...")
    
#     with Session(engine) as session:
#         # Backup users
#         users = session.exec(text("SELECT * FROM users")).fetchall()
#         users_data = [dict(row._mapping) for row in users]
        
#         # Backup itineraries  
#         itineraries = session.exec(text("SELECT * FROM itineraries")).fetchall()
#         itineraries_data = [dict(row._mapping) for row in itineraries]
        
#         # Backup day_groups (if this table exists)
#         try:
#             day_groups = session.exec(text("SELECT * FROM day_groups")).fetchall()
#             day_groups_data = [dict(row._mapping) for row in day_groups]
#         except:
#             day_groups_data = []
        
#         # Backup blocks (if this table exists)
#         try:
#             blocks = session.exec(text("SELECT * FROM blocks")).fetchall()
#             blocks_data = [dict(row._mapping) for row in blocks]
#         except:
#             blocks_data = []
    
#     # Save backup
#     timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
#     backup_data = {
#         "backup_timestamp": timestamp,
#         "users": users_data,
#         "itineraries": itineraries_data,
#         "day_groups": day_groups_data,
#         "blocks": blocks_data
#     }
    
#     os.makedirs('backups', exist_ok=True)
#     backup_file = f'backups/tabi_backup_{timestamp}.json'
    
#     with open(backup_file, 'w') as f:
#         json.dump(backup_data, f, indent=2, default=str)
    
#     print(f"✅ Backup saved to {backup_file}")
#     return backup_file

# def clean_users(session):
#     """
#     Clean up test users and standardize profiles
#     """
#     print("\n👥 Cleaning user profiles...")
    
#     # Delete test users (but keep pikachu!)
#     test_usernames = ['demo', 'stabley_woo', 'rumi', 'sydney_sweeney']
    
#     for username in test_usernames:
#         result = session.exec(text(
#             "DELETE FROM users WHERE username = :username"
#         ).params(username=username))
    
#     print(f"🗑️  Deleted test users: {', '.join(test_usernames)}")
    
#     # Update julie's username from julieee_mun to julie_mun
#     session.exec(text(
#         "UPDATE users SET username = :new WHERE username = :old"
#     ).params(new='julie_mun', old='julieee_mun'))
    
#     # Standardize user profiles
#     user_updates = [
#         {
#             "id": 1,
#             "username": "sarah_kuo",
#             "email": "sarah@tabi.app",
#             "display_name": "Sarah Kuo",
#             "bio": "Tokyo wanderer 🗾 | Onsen enthusiast ♨️ | Street food hunter",
#             "avatar_name": "sarah_avatar.jpg",
#             "header_url": "http://localhost:8000/static/sarah_header.jpg"
#         },
#         {
#             "id": 2,
#             "username": "julie_mun",
#             "email": "julie@tabi.app",
#             "display_name": "Julie Mun",
#             "bio": "Music lover 🎵 | Coastal drives 🌊 | California dreaming",
#             "avatar_name": "julie_avatar.jpg",
#             "header_url": "http://localhost:8000/static/julie_header.jpg"
#         },
#         {
#             "id": 6,  # Keeping Pikachu instead of Sydney!
#             "username": "pikachu",
#             "email": "pikachu@tabi.app",
#             "display_name": "Pikachu",
#             "bio": "⚡ Adventure seeker | Photo spots finder | Spreading joy worldwide",
#             "avatar_name": "pikachu_avatar.jpg",
#             "header_url": "http://localhost:8000/static/pikachu_header.jpg"
#         },
#         {
#             "id": 4,
#             "username": "savannah_demers",
#             "email": "savannah@tabi.app",
#             "display_name": "Savannah Demers",
#             "bio": "Film photographer 📸 | Road trip planner 🚗 | Sunset chaser",
#             "avatar_name": "savannah_avatar.jpg",
#             "header_url": "http://localhost:8000/static/savannah_header.jpg"
#         }
#     ]
    
#     for user in user_updates:
#         session.exec(text("""
#             UPDATE users 
#             SET email = :email,
#                 display_name = :display_name,
#                 bio = :bio,
#                 avatar_name = :avatar_name,
#                 header_url = :header_url
#             WHERE id = :id
#         """).params(**user))
    
#     session.commit()
#     print(f"✅ Updated {len(user_updates)} user profiles")

# def clean_itineraries(session):
#     """
#     Remove test itineraries and update remaining ones
#     """
#     print("\n🗺️  Cleaning itineraries...")
    
#     # First check if these tables exist
#     try:
#         # Delete related blocks first
#         session.exec(text("""
#             DELETE FROM blocks 
#             WHERE day_group_id IN (
#                 SELECT id FROM day_groups 
#                 WHERE itinerary_id IN (
#                     SELECT id FROM itineraries 
#                     WHERE title LIKE '%forked%' 
#                        OR title LIKE '%CLI Smoke%' 
#                        OR title LIKE '%Taylor Swift%'
#                        OR title LIKE '%hottttt%'
#                        OR creator_id IN (3, 5, 7, 8)
#                 )
#             )
#         """))
        
#         # Delete day groups
#         session.exec(text("""
#             DELETE FROM day_groups 
#             WHERE itinerary_id IN (
#                 SELECT id FROM itineraries 
#                 WHERE title LIKE '%forked%' 
#                    OR title LIKE '%CLI Smoke%' 
#                    OR title LIKE '%Taylor Swift%'
#                    OR title LIKE '%hottttt%'
#                    OR creator_id IN (3, 5, 7, 8)
#             )
#         """))
#     except:
#         print("   Note: day_groups/blocks tables not found, skipping...")
    
#     # Delete itineraries
#     session.exec(text("""
#         DELETE FROM itineraries 
#         WHERE title LIKE '%forked%' 
#            OR title LIKE '%CLI Smoke%' 
#            OR title LIKE '%Taylor Swift%'
#            OR title LIKE '%hottttt%'
#            OR creator_id IN (3, 5, 7, 8)
#     """))
    
#     print("🗑️  Deleted test itineraries")
    
#     # Update existing itineraries with better metadata
#     updates = [
#         {
#             "id": 4,
#             "title": "Big Sur Coastal Adventure",
#             "description": "3 days exploring California's most stunning coastline - from Carmel's charm to Big Sur's dramatic cliffs",
#             "tags": ["California", "Coast", "Photography", "Hiking", "Road Trip"]
#         },
#         {
#             "id": 5,
#             "title": "NYC Hidden Gems Weekend",
#             "description": "Skip the tourist traps - discover where locals eat, drink, and explore in Manhattan and Brooklyn",
#             "tags": ["New York", "Local Tips", "Food", "Culture", "Weekend"]
#         },
#         {
#             "id": 10,  # Pikachu's trip
#             "title": "Electric NYC Adventure ⚡",
#             "description": "Pikachu's high-energy tour of New York - from sunrise yoga in Central Park to late night ramen in East Village",
#             "tags": ["New York", "Adventure", "Fun", "Energy", "Electric"]
#         }
#     ]
    
#     for update in updates:
#         # Check if itinerary exists before updating
#         result = session.exec(text(
#             "SELECT id FROM itineraries WHERE id = :id"
#         ).params(id=update['id'])).first()
        
#         if result:
#             session.exec(text("""
#                 UPDATE itineraries 
#                 SET title = :title,
#                     description = :description,
#                     tags = :tags
#                 WHERE id = :id
#             """).params(
#                 id=update['id'],
#                 title=update['title'],
#                 description=update['description'],
#                 tags=json.dumps(update['tags'])  # PostgreSQL JSON field
#             ))
    
#     session.commit()
#     print(f"✅ Enhanced itineraries")

# def add_rich_content(session):
#     """
#     Add detailed content to existing itineraries
#     """
#     print("\n✨ Adding rich content to itineraries...")
    
#     try:
#         # Update existing content for Big Sur trip (ID: 4, Julie's)
#         # Check if blocks table exists first
#         session.exec(text("SELECT 1 FROM blocks LIMIT 1")).first()
        
#         # Update an existing block with richer content
#         session.exec(text("""
#             UPDATE blocks 
#             SET content = :content
#             WHERE id = 4 AND type = 'text'
#         """).params(
#             content="6:30 AM departure from San Francisco. Grabbed coffee and croissants from Arsicault Bakery (arguably the best in the city - get there before 7 or they sell out!). Pro tip: Download offline maps for Highway 1, cell service is spotty between Pacifica and Half Moon Bay."
#         ))
        
#         # Get day_group_id for adding new content
#         result = session.exec(text(
#             "SELECT id FROM day_groups WHERE itinerary_id = 4 ORDER BY \"order\" LIMIT 1"
#         )).first()
        
#         if result:
#             day_group_id = result[0]
            
#             # Check max order
#             max_order_result = session.exec(text(
#                 "SELECT COALESCE(MAX(\"order\"), 0) FROM blocks WHERE day_group_id = :dgid"
#             ).params(dgid=day_group_id)).first()
            
#             next_order = (max_order_result[0] if max_order_result else 0) + 1
            
#             # Add a new detailed block
#             session.exec(text("""
#                 INSERT INTO blocks (day_group_id, "order", type, content)
#                 VALUES (:day_group_id, :order, :type, :content)
#             """).params(
#                 day_group_id=day_group_id,
#                 order=next_order,
#                 type="text",
#                 content="Hidden gem: Stop at Swanton Berry Farm (just past Año Nuevo). It's a u-pick organic strawberry farm with the honor system farm stand. Their strawberry shortcake is legendary and costs half what you'd pay in the city."
#             ))
            
#             print("   Added rich content blocks")
    
#     except Exception as e:
#         print(f"   Note: Could not add detailed content (blocks table may not exist): {e}")
    
#     session.commit()

# def verify_cleanup(engine):
#     """
#     Verify the cleanup results
#     """
#     print("\n📊 Verifying cleanup results...")
    
#     with Session(engine) as session:
#         # Count users
#         user_count = session.exec(
#             text("SELECT COUNT(*) FROM users")
#         ).first()[0]
        
#         # Count itineraries
#         itin_count = session.exec(
#             text("SELECT COUNT(*) FROM itineraries")
#         ).first()[0]
        
#         # Show current users
#         users = session.exec(
#             text("SELECT username, display_name, bio FROM users ORDER BY id")
#         ).fetchall()
        
#         print(f"\n✅ Final Database Stats:")
#         print(f"   Active users: {user_count}")
#         print(f"   Active itineraries: {itin_count}")
#         print(f"\n👥 Current Users:")
#         for user in users:
#             bio_preview = user[2][:50] + "..." if user[2] and len(user[2]) > 50 else user[2]
#             print(f"   - {user[0]} ({user[1]}): {bio_preview}")

# def main():
#     """
#     Main execution flow
#     """
#     print("\n🚀 Starting Tabi PostgreSQL Database Cleanup")
#     print("=" * 60)
    
#     try:
#         # Create engine
#         engine = create_engine(DATABASE_URL, echo=False)
        
#         # Test connection
#         with Session(engine) as session:
#             session.exec(text("SELECT 1")).first()
#             print("✅ Database connection successful")
        
#         # Create backup first
#         backup_file = create_backup(engine)
        
#         # Ask for confirmation
#         print("\n⚠️  This will modify your database!")
#         print("   - Keep users: sarah_kuo, julie_mun, pikachu, savannah_demers")
#         print("   - Delete users: demo, stabley_woo, rumi, sydney_sweeney")
#         print("   - Remove test itineraries")
#         print("   - Update Julie's bio to 'Music lover'")
        
#         response = input("\nContinue? (yes/no): ")
#         if response.lower() != 'yes':
#             print("❌ Cleanup cancelled")
#             return
        
#         # Run cleanup in a transaction
#         with Session(engine) as session:
#             clean_users(session)
#             clean_itineraries(session)
#             add_rich_content(session)
        
#         # Verify results
#         verify_cleanup(engine)
        
#         print(f"\n🎉 Database cleanup completed successfully!")
#         print(f"💾 Backup available at: {backup_file}")
        
#     except Exception as e:
#         print(f"\n❌ Error: {e}")
#         print("💡 Your backup is safe. Database was not modified or was rolled back.")
#         raise

# if __name__ == "__main__":
#     main()