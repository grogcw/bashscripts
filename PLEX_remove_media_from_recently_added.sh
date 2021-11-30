# On a linux machine, execute the following to avoid colliding errors :

$ /usr/lib/plexmediaserver/Plex\ Media\ Server --sqlite ./com.plexapp.plugins.library.db

# then use the following SQLite command to match the added date to release date, hence removing the media from recently added :

UPDATE metadata_items SET added_at = datetime(originally_available_at, '+1 days') WHERE id like '<MEDIA_ID>';
