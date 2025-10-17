# Calendai
## Info
Calendai is an AI-integrated calendar that allows you to create events from different sources, such as text/image/audio.

It also has support for organizable recurring events, 
letting you create things like weekly events out of a picture of your class schedule that are only active during the semester.

Supports Windows and Android.

## Running locally
### Supabase + authentication
This app uses Supabase for its Postgres database and OAuth layer. We currently allow 2 forms of OAuth, Google and Azure. 

Firstly, you must set up a new Supabase project. 
Then, [Follow the steps here](https://supabase.com/docs/guides/auth/social-login/auth-google?queryGroups=framework&framework=nextjs) to get Google OAuth set up.

Next, [follow the steps here](https://supabase.com/docs/guides/auth/social-login/auth-azure) to set up Azure OAuth.
Additionally, in the Azure portal, go to **Manage** -> **API Permissions** -> **Add a permission** -> **Delegated permissions**, 
and add `email` and `Calendar.ReadWrite.Shared` permissions. 

Then, navigate to your Supabase project's **Authentication settings** -> **URL Configuration**, and change *Site URL* to `calendai://callback`.

### Env variables
The backend uses `/backend/.env` for env variables. An example is given as `example.env`, which you can fill out and rename to start using.
The variables used are:
- `DATABASE_URL` - The Postgres database URL
- `JWT_SECRET`- The JWT secret used for encoding/decoding Supabase JWTs (found in **Supabase's settings** > **API**)

The frontend uses `/frontend/.env` for env variables. Likewise, an example is given as `example.env`.
The variables used are:
- `env_type` - The environment type, used for manually installing Windows deep linking manually during development. Set to DEV if you're developing
- `supabase_url` - The Supabase' project's URL; looks like `https:\\xxxxxxxx.supabase.co`
- `supabase_anon_key` - The Supabase anonymous key, for interacting with Supabase; found in the project dashboard
- `api_base_url` - The backend URL. Defaults to `http://localhost:80` for development, but is different for deployment

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

For development, it's recommended to use VSCode with the Flutter extension, as it provides conveniences like debug breakpoints, stack traces, start/pause/step menus etc.
[You can check it out here](https://docs.flutter.dev/tools/vs-code).

