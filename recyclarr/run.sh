name: Recyclarr
version: "9.4.0"
slug: recyclarr
description: TRaSH-Guide Sync für Sonarr und Radarr
arch:
  - amd64
  - aarch64
options:
  sonarr_url: ""
  sonarr_apikey: ""
  sonarr_profile_1080p: true
  sonarr_profile_2160p: false
  radarr_url: ""
  radarr_apikey: ""
  radarr_profile_1080p: true
  radarr_profile_4k: false
  enable_hdr: false
  enable_dv: false
  enable_atmos: false
  enable_truehd: false
  enable_surround: false
  prefer_hq_groups: false
schema:
  sonarr_url: str
  sonarr_apikey: str
  sonarr_profile_1080p: bool
  sonarr_profile_2160p: bool
  radarr_url: str
  radarr_apikey: str
  radarr_profile_1080p: bool
  radarr_profile_4k: bool
  enable_hdr: bool
  enable_dv: bool
  enable_atmos: bool
  enable_truehd: bool
  enable_surround: bool
  prefer_hq_groups: bool
