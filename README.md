# Calendai
## Info
This is an AI-integrated calendar that allows you to create events from different sources, such as text/image/audio.

It also has support for organizable recurring events, 
letting you do useful things like create weekly events out of a picture of your class schedule
that are only active during the semester.

Supports Windows and Android.

## WIP
Note that this is still in development; many things don't work yet.

## Running locally
### Supabase + Google OAuth
This app uses Supabase + Google OAuth for authentication and database. [Follow the steps here](https://supabase.com/docs/guides/auth/social-login/auth-google?queryGroups=framework&framework=nextjs)
to get these set up.

### Env variables
The backend uses `/backend/.env` for env variables. An example is given as `example.env`, which you can fill out and rename to start using.
The variables used are:
- `DATABASE_URL` - The Postgres database URL
- `JWT_SECRET`- The JWT secret used for encoding/decoding Supabase JWTs (found in Supabase's Settings > API)

### Backend
You need Rust + sqlx-cli installed:
```
cd backend
sqlx run migrate
cargo run --release
```

### Frontend
You need Flutter installed:
```
flutter run
```

