# Post-Installation Setup Guide

This guide walks you through configuring your media server stack after running the initial setup. All services should be running via Docker Compose before starting this guide.

## Table of Contents
1. [Access URLs](#access-urls)
2. [Deluge Setup](#1-deluge-setup)
3. [Prowlarr Setup](#2-prowlarr-setup)
4. [Sonarr Setup](#3-sonarr-setup)
5. [Radarr Setup](#4-radarr-setup)
6. [Jellyfin Setup](#5-jellyfin-setup)
7. [Testing the Setup](#6-testing-the-setup)

---

## Access URLs

After starting the Docker stack, access your services at:

- **Prowlarr**: http://YOUR_IP:9696 (Indexer manager)
- **Sonarr**: http://YOUR_IP:8989 (TV show automation)
- **Radarr**: http://YOUR_IP:7878 (Movie automation)
- **Deluge**: http://YOUR_IP:8112 (Torrent client)
- **Jellyfin**: http://YOUR_IP:8096 (Media server)
- **Pi-hole**: http://YOUR_IP/admin (DNS/Ad-blocker)
- **Portainer**: http://YOUR_IP:9000 (Docker management)

Replace `YOUR_IP` with your Raspberry Pi's IP address.

---

## 1. Deluge Setup

### Initial Configuration

1. Navigate to **http://YOUR_IP:8112**
2. Default password: `deluge`
3. **Change the password immediately**:
   - Go to **Preferences** → **Interface**
   - Set a new password
   - Click **OK**

### Configure Downloads

1. Go to **Preferences** → **Downloads**
2. Set **Download to**: `/downloads` (already mapped to `/mnt/storage/downloads/torrents`)
3. Enable **Move completed to**: `/downloads/complete` (optional)
4. Click **Apply**

### Enable Label Plugin (Required for Sonarr/Radarr categories)

1. Go to **Preferences** → **Plugins**
2. Enable **Label** plugin
3. Click **OK**
4. Restart Deluge if prompted

---

## 2. Prowlarr Setup

Prowlarr manages all indexers (torrent sites) and automatically syncs them to Sonarr and Radarr.

### Initial Setup

1. Navigate to **http://YOUR_IP:9696**
2. Complete the initial setup wizard
3. Set authentication if desired (Settings → General → Authentication)

### Connect Sonarr

1. Go to **Settings** → **Apps** → **Add Application** → **Sonarr**
2. Configure:
   - **Prowlarr Server**: `http://YOUR_IP:9696`
   - **Sonarr Server**: `http://YOUR_IP:8989`
   - **API Key**: Get from Sonarr (Settings → General → Security → API Key)
   - **Sync Level**: `Full Sync` or `Add and Remove Only`
3. Click **Test** to verify connection
4. Click **Save**

### Connect Radarr

1. Go to **Settings** → **Apps** → **Add Application** → **Radarr**
2. Configure:
   - **Prowlarr Server**: `http://YOUR_IP:9696`
   - **Radarr Server**: `http://YOUR_IP:7878`
   - **API Key**: Get from Radarr (Settings → General → Security → API Key)
   - **Sync Level**: `Full Sync` or `Add and Remove Only`
3. Click **Test** to verify connection
4. Click **Save**

### Add Indexers

1. Go to **Indexers** → **Add Indexer**
2. Search for and add popular free indexers:
   - **1337x** - Movies & TV (no account needed)
   - **The Pirate Bay** - Movies & TV (no account needed)
   - **EZTV** - TV shows (no account needed)
   - **YTS** - Movies (no account needed)
   - **TorrentGalaxy** - Movies & TV (no account needed)

3. For each indexer:
   - Click on the indexer name
   - Click **Test** to verify it works
   - Click **Save**

4. **Important**: Once indexers are added, they will automatically sync to Sonarr and Radarr within a few minutes!

---

## 3. Sonarr Setup

### Initial Setup

1. Navigate to **http://YOUR_IP:8989**
2. Complete the setup wizard
3. Set authentication if desired (Settings → General → Authentication)

### Add Root Folder

1. Go to **Settings** → **Media Management**
2. Click **Add Root Folder**
3. Enter: `/media/tv`
4. Click **OK**

### Configure Download Client (Deluge)

1. Go to **Settings** → **Download Clients**
2. Click **+** to add a new download client
3. Select **Deluge**
4. Configure:
   - **Name**: `Deluge`
   - **Host**: `YOUR_IP` (or `192.168.X.X`)
   - **Port**: `8112`
   - **Password**: Your Deluge password
   - **Category**: `tv` (optional, helps organize downloads)
5. Click **Test** to verify connection
6. Click **Save**

### Verify Indexers

1. Go to **Settings** → **Indexers**
2. You should see indexers automatically synced from Prowlarr
3. If not, wait a few minutes or trigger a sync in Prowlarr

### Recommended Settings

1. **Settings** → **Media Management**:
   - Enable **Rename Episodes**
   - **Standard Episode Format**: `{Series Title} - S{season:00}E{episode:00} - {Episode Title} {Quality Full}`
   - Enable **Unmonitor Deleted Episodes**

2. **Settings** → **Profiles**:
   - Edit the quality profile to match your preferences (1080p recommended)

---

## 4. Radarr Setup

### Initial Setup

1. Navigate to **http://YOUR_IP:7878**
2. Complete the setup wizard
3. Set authentication if desired (Settings → General → Authentication)

### Add Root Folder

1. Go to **Settings** → **Media Management**
2. Click **Add Root Folder**
3. Enter: `/media/movies`
4. Click **OK**

### Configure Download Client (Deluge)

1. Go to **Settings** → **Download Clients**
2. Click **+** to add a new download client
3. Select **Deluge**
4. Configure:
   - **Name**: `Deluge`
   - **Host**: `YOUR_IP` (or `192.168.X.X`)
   - **Port**: `8112`
   - **Password**: Your Deluge password
   - **Category**: `movies` (optional, helps organize downloads)
5. Click **Test** to verify connection
6. Click **Save**

### Verify Indexers

1. Go to **Settings** → **Indexers**
2. You should see indexers automatically synced from Prowlarr
3. If not, wait a few minutes or trigger a sync in Prowlarr

### Recommended Settings

1. **Settings** → **Media Management**:
   - Enable **Rename Movies**
   - **Standard Movie Format**: `{Movie Title} ({Release Year}) {Quality Full}`
   - Enable **Unmonitor Deleted Movies**

2. **Settings** → **Profiles**:
   - Edit the quality profile to match your preferences (1080p recommended)

---

## 5. Jellyfin Setup

### Initial Setup

1. Navigate to **http://YOUR_IP:8096**
2. Complete the initial setup wizard:
   - Set your language
   - Create an admin account
   - **Important**: Remember this username and password!

### Add Media Libraries

#### Add TV Shows Library

1. From the dashboard, click **Add Media Library**
2. Select **Content type**: `Shows`
3. Click **+** next to **Folders** and add: `/media/tv`
4. Configure library settings:
   - **Preferred metadata language**: English (or your preference)
   - **Country**: Your country
   - Enable **Automatically refresh metadata from the internet**
5. Click **OK**

#### Add Movies Library

1. Click **Add Media Library** again
2. Select **Content type**: `Movies`
3. Click **+** next to **Folders** and add: `/media/movies`
4. Configure library settings:
   - **Preferred metadata language**: English (or your preference)
   - **Country**: Your country
   - Enable **Automatically refresh metadata from the internet**
5. Click **OK**

### Scan Libraries

1. Go to **Dashboard** → **Libraries**
2. Click the **Scan All Libraries** button
3. Jellyfin will scan and organize your media with metadata, artwork, and descriptions

---

## 6. Testing the Setup

### Test TV Show Download

1. Go to **Sonarr** (http://YOUR_IP:8989)
2. Click **Add New** (Series)
3. Search for a popular show (e.g., "South Park")
4. Click on the show → Select **Root Folder**: `/media/tv`
5. Choose quality profile and click **Add**
6. Go to the show's page → Click **Search** (magnifying glass icon)
7. Select an episode → Click **Manual Search** or **Automatic Search**
8. Select a release and click **Grab**

**Monitor Progress:**
- Check **Sonarr** → **Activity** → **Queue** to see download progress
- Check **Deluge** to see the torrent downloading
- Once complete, Sonarr will move it to `/media/tv/Show Name/Season XX/`
- **Jellyfin** will automatically detect and add the new episode

### Test Movie Download

1. Go to **Radarr** (http://YOUR_IP:7878)
2. Click **Add New** (Movie)
3. Search for a movie
4. Select **Root Folder**: `/media/movies`
5. Choose quality profile and click **Add and Search**
6. Select a release from the results

**Monitor Progress:**
- Check **Radarr** → **Activity** → **Queue**
- Check **Deluge** to see the torrent downloading
- Once complete, Radarr will move it to `/media/movies/Movie Name (Year)/`
- **Jellyfin** will automatically detect and add the new movie

---

## Important: Proper Download Workflow

### ⚠️ Common Mistake: Downloading Directly Through Deluge

**Problem:** If you download content directly through Deluge (without adding it to Radarr/Sonarr first), it will stay in the downloads folder and won't appear in Jellyfin. This is because Radarr/Sonarr don't know they should import it.

**Solution:** Always use Radarr/Sonarr to manage your downloads, not Deluge directly.

### ✅ Correct Workflow for Movies (Radarr)

1. **Open Radarr** (http://YOUR_IP:7878)
2. Click **Add New** (the + icon)
3. Search for your movie
4. Click on the movie from search results
5. Configure:
   - **Root Folder**: `/media/movies`
   - **Quality Profile**: Your preference (e.g., HD-1080p)
   - **Monitor**: Yes
6. Click **Add and Search**

**What happens:**
- Radarr searches all your indexers (via Prowlarr)
- Sends the best release to Deluge automatically
- Monitors the download progress
- **Automatically imports** the file to `/media/movies/Movie Name (Year)/`
- Jellyfin picks it up automatically

### ✅ Correct Workflow for TV Shows (Sonarr)

1. **Open Sonarr** (http://YOUR_IP:8989)
2. Click **Add New** (the + icon)
3. Search for your TV show
4. Click on the show from search results
5. Configure:
   - **Root Folder**: `/media/tv`
   - **Quality Profile**: Your preference
   - **Monitor**: Choose what to monitor (All Episodes, Future Episodes, etc.)
   - **Season Folder**: Yes (recommended)
6. Click **Add**

**What happens:**
- Sonarr monitors for new episodes
- Automatically searches and downloads new episodes as they air
- **Automatically imports** episodes to `/media/tv/Show Name/Season XX/`
- Jellyfin picks them up automatically

### 🔧 What To Do If You Already Downloaded Through Deluge

If you've already downloaded something directly through Deluge:

1. **Add the movie/show to Radarr/Sonarr first** (follow steps above)
2. Go to Radarr/Sonarr → **Wanted** → **Manual Import**
3. Select `/downloads/torrents/movies` or `/downloads/torrents/tv`
4. The app will scan and show available files
5. Click **Import** on the files you want
6. Wait a few minutes, then refresh Jellyfin

**Or use the web interface:**
- **Radarr**: Movie page → **Manual Import** → Select the file
- **Sonarr**: Series page → **Manual Import** → Select episodes

### 📝 Quick Reference

| ❌ Wrong Way | ✅ Right Way |
|-------------|-------------|
| Open Deluge → Add torrent directly | Open Radarr/Sonarr → Add content → Let it handle the download |
| Download completes → File sits in `/downloads/` | Download completes → Automatically imported to `/media/` |
| Jellyfin never sees it | Jellyfin automatically scans and adds it |
| Manual work required | Fully automated |

**Remember:** Radarr and Sonarr are your media managers. Deluge is just the download tool they use. Always start with Radarr/Sonarr!

---

## Troubleshooting

### Prowlarr indexers not syncing to Sonarr/Radarr
- Check that apps are enabled in Prowlarr: **Settings** → **Apps**
- Verify API keys are correct
- Trigger manual sync: Click **Sync App Indexers** in Prowlarr

### Sonarr/Radarr can't connect to Deluge
- Verify Deluge is running: `docker ps`
- Check Deluge password is correct
- Ensure Deluge is accessible via the VPN (gluetun) network
- Use the host IP address, not `localhost`

### Downloads not importing to media library
- Check folder permissions: `/mnt/storage/medialibrary` and `/mnt/storage/downloads` should be accessible
- Verify **Completed Download Handling** is enabled in Sonarr/Radarr (Settings → Download Clients)
- Check Sonarr/Radarr logs for errors

### Jellyfin not showing new media
- Trigger manual scan: **Dashboard** → **Libraries** → **Scan All Libraries**
- Check file permissions on media files
- Verify library folders are correct: `/media/tv` and `/media/movies`

### VPN Issues (Deluge not downloading)
- Check gluetun container is healthy: `docker ps`
- Verify VPN credentials in docker-compose.yaml
- Check gluetun logs: `docker logs gluetun`
- Test connection: `docker exec gluetun curl ifconfig.me` (should show VPN IP, not your real IP)

---

## Next Steps

### Automatic Monitoring

**For TV Shows (Sonarr):**
- Add shows and set them to **Monitored**
- Sonarr will automatically download new episodes as they air
- Configure **Calendar** to see upcoming releases

**For Movies (Radarr):**
- Add movies to your **Wanted** list
- Radarr will automatically search for and download them
- Use **Discover** to find new movies

### Quality Profiles

Customize quality profiles in Sonarr/Radarr:
- **Settings** → **Profiles** → **Quality Profiles**
- Set preferred qualities (e.g., prefer 1080p over 720p)
- Configure size limits and preferred formats

### Notifications

Set up notifications for completed downloads:
- **Sonarr/Radarr** → **Settings** → **Connect**
- Add notification services (Discord, Pushover, Email, etc.)

---

## Summary

Your media automation stack is now configured:

1. **Prowlarr** manages indexers and syncs them to Sonarr/Radarr
2. **Sonarr/Radarr** automatically search for and grab TV/Movies
3. **Deluge** downloads torrents through the VPN
4. **Sonarr/Radarr** import completed downloads to the media library
5. **Jellyfin** provides a beautiful interface to watch your media

Enjoy your automated media server! 🎬📺
