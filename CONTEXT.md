# Roblox Shorts Research — Project Context

> Load this file at the start of any session to restore full context without re-explaining everything.

---

## What This Project Is

A private research dashboard for tracking Roblox YouTube Shorts channels and their videos. It lives at:

**GitHub Pages (live site):** https://mgstaff-lab.github.io/roblox-research/  
**GitHub Repo:** https://github.com/MGstaff-lab/roblox-research  
**Local path:** `C:\Users\RZeva\roblox-research`

The frontend (`index.html`) is a single-file dark-theme dashboard with two tabs:
- **Channels** — sortable table of all tracked channels with niche, subscribers, revenue estimates, etc.
- **Videos** — filterable/searchable table of all Shorts with views, dates, niche badges, inline niche editing, batch niche assignment

---

## Critical Git Rule

> **Always push to `main`.** GitHub Pages serves from `main`. The repo also has a `master` branch — don't push there and forget to merge, or the live site won't update.

```bash
git checkout main
git add .
git commit -m "message"
git push origin main
```

If you've accidentally committed to `master`:
```bash
git checkout main
git merge master --no-edit
git push origin main
git checkout master
```

---

## Keys & Endpoints

| Thing | Value |
|---|---|
| Supabase REST URL | `https://ahpzdwemvunyaumrnxal.supabase.co/rest/v1` |
| Supabase Key | `sb_publishable_NPPdURwPz_DEt6JG--haaw_CThnEoQF` |
| YouTube Data API Key | `AIzaSyBX47DSTcr3ZOPtbmYIoG0ECvHw1VHHHis` |

> **Note:** If Supabase appears unreachable (DNS errors, timeouts), check the dashboard first — free-tier projects **auto-pause** after inactivity. Unpause at supabase.com → your project → Resume.

---

## Database Schema (Supabase)

### `channels` table
| Column | Type | Notes |
|---|---|---|
| `id` | uuid (PK) | auto-generated |
| `name` | text | channel display name |
| `url` | text | YouTube URL |
| `niche` | text | nullable — null shows as "Unknown" in UI |
| `subscribers` | int | |
| `date_started` | date | |
| `total_videos` | int | |
| `uploads_per_week` | float | |
| `avg_views_per_video` | int | |
| `est_monthly_revenue` | int | |
| `is_legacy_channel` | bool | legacy = upload frequency understated |

### `videos` table
| Column | Type | Notes |
|---|---|---|
| `id` | uuid (PK) | auto-generated |
| `channel_id` | uuid (FK → channels) | nullable |
| `channel_name` | text | denormalized for display |
| `niche` | text | nullable |
| `title` | text | |
| `video_id` | text | YouTube 11-char ID |
| `url` | text | full YouTube Shorts URL |
| `views` | int8 | |
| `published_date` | date | |

**Current state (as of May 2026):** ~168 channels, ~27,297 videos

---

## data.js — What It Is

`C:\Users\RZeva\roblox-research\data.js` is a **standalone backup/export file** — the frontend does NOT read from it. It contains `const CHANNELS = [...]` and `const VIDEOS = [...]` arrays in JS syntax.

- ~126 channels (84 original + 42 added May 2026)
- ~20,783 video entries
- Used as a source of truth for bulk-syncing to Supabase

**data.js VIDEOS format (camelCase):**
```js
{ title: '...', channelName: '...', channelUrl: '...', views: N,
  publishedDate: 'YYYY-MM-DD', thumbnailUrl: '...', url: 'https://www.youtube.com/shorts/VIDEO_ID', niche: null }
```

**Supabase videos format (snake_case):** `channel_name`, `published_date`, `video_id`, etc.

---

## PowerShell Gotchas (PS 5.1)

> All scripts run in Windows PowerShell 5.1. Several bugs will bite you:

1. **JSON array parsing bug** — `ConvertFrom-Json` / `Invoke-RestMethod` bundles JSON arrays into a single PSCustomObject instead of an array. **Fix:** Use `JavaScriptSerializer`:
   ```powershell
   [void][System.Reflection.Assembly]::LoadWithPartialName('System.Web.Extensions')
   $ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
   $ser.MaxJsonLength = [int]::MaxValue
   $raw = $ser.DeserializeObject($r.Content)   # returns proper array
   ```
   Or use `Invoke-WebRequest -UseBasicParsing` + `@(... | ConvertFrom-Json)`.

2. **Non-ASCII characters** — PS 5.1 throws parse errors on `→`, `—`, etc. in scripts. Keep scripts ASCII-only.

3. **Backtick line continuation + `&` in URLs** — breaks silently. Use string concatenation instead:
   ```powershell
   # BAD:
   $url = $base + '?foo=bar' `
       + '&baz=qux'
   # GOOD:
   $url = $base + '?foo=bar' + '&baz=qux'
   ```

4. **`List<object>.Add()` "fixed size" error** — PS 5.1 hashtables can return fixed arrays. Use `JavaScriptSerializer` for deserialization to avoid this.

---

## Scripts

| Script | Purpose |
|---|---|
| `fetch_new_channels.ps1` | Fetches last 90 days of Shorts for 42 new channels, writes to data.js |
| `fetch_full_history.ps1` | Fetches ALL Shorts (no date cutoff) for 42 channels, skips existing IDs, flushes to data.js in batches |
| `sync_datajs_to_supabase.ps1` | Reads data.js VIDEOS, matches channels by name, bulk-inserts into Supabase (skips existing video_ids) |
| `generate_videos_csv.ps1` | Alternative: generates a CSV from data.js for manual Supabase import |
| `find_duplicate_channels.ps1` | Queries Supabase, groups channels by name, shows each group with video count per entry |
| `dedupe_channels.ps1` | Removes duplicate channel rows — keeps the entry with most videos (or best niche), reassigns videos, deletes losers |

---

## How to Add New Channels

**Option A — Via the UI (small batches):**
1. Open the live site → Channels tab → "+ Add Channel"
2. Paste YouTube URL → it auto-fetches name & subscriber count
3. Set niche → Add

**Option B — Batch via UI:**
- "+ Add Channel" → Batch tab → paste one URL per line

**Option C — For large batches with full video history:**
1. Add channel handles to `fetch_new_channels.ps1` (90-day fetch first)
2. Then run `fetch_full_history.ps1` for the same handles (gets everything)
3. Then run `sync_datajs_to_supabase.ps1` to push to Supabase

---

## How the Frontend Works

- Loads **all data from Supabase** on page load (never reads data.js)
- `loadChannels()` — `db.from('channels').select('*').order('subscribers', desc)`
- `loadVideos()` — paginated REST fetch, 1000 rows at a time, ordered by views desc
- Niche editing: click any niche badge inline, or select multiple rows → batch bar → set niche for all
- Niche filter panel: click/cycle each niche → ✓ include / ✕ exclude / neutral. **"Unknown"** appears when any video has `null` niche.
- Date filter: presets + **Custom range** (pick start date, end date, or both)

---

## What Was Built / Fixed (May 2026 Session)

- Populated Supabase `videos` table from data.js (20,089 inserted, 0 failed)
- Added 42 new channels + fetched their full Shorts history (16,746 additional videos)
- Fixed PS 5.1 JSON parsing bug that caused `channel_id = [array of all UUIDs]`
- Diagnosed Supabase project being paused (looked like DNS failure)
- Found and removed 52 duplicate channel rows (44 groups) via `dedupe_channels.ps1`
- Added "Unknown" niche as a filterable option in the Videos niche panel
- Added custom date range picker (start + end date inputs) to video filters
- Fixed the `master` vs `main` branch issue — site was serving stale code for entire session
