The import flow:

1. Select backend you're importing from (Android? Spotify? Local files?)
2. Select a unit of tracks (Album? Artist? Playlist? Single Song?)
   > ideally this process is consistent between plugins
3. Select one or more of those units to import
   > ideally this process is consistent between plugins
4. For each unit, select *how* to import it. You may want to import a backend-album as a logical-playlist. You may just want to import all the songs from a given artist without any other tag/playlist grouping. MAYBE you can try to import a backend-playlist as a logical-album

Now we hit a lot of complexity.
IF you're importing a single backend-album as a logical-album, we have to link the album to a logical album, link the artists to logical artists, and then link the songs to logical songs.
IF you're importing a backend-album as a logical-playlist or a logical-tag, you just need to link artists and link songs - there isn't a logical album to connect the logical songs to.
<!-- IF you're importing multiple albums, we assume those albums have to be merged separately for now. [DISC 1] and [DISC 2] merging would require looping another backend in  -->
IF you're importing multiple backend-albums, they may be merged into a single logical-album. If importing [DISC1] and [DISC2], you could rename them to the same name and thus merge them at the import phase. This can require manually renumbering the songs, which is important to remember.
IF you're importing a backend-playlist as a logical-playlist, you need to create the individual albums for each track and you may end up merging them later.

4. For each backend-logical-song in those units, "fake import" them one by one
   and find duplicates both in the new import set and in the database itself?
   
   Two kinds of duplicate: strict duplicates are where literally the same backend ID has been imported and linked to a song already, thus the import merges the SongMetadata into the same logical song. I can think of no reason to allow the user to stop this. The other kind is a soft duplicate where the exact backend ID hasn't been imported before, but there's a strong match between the metadata from this backend and metadata from another backend.

   Soft duplicates can be album dependent - or informed by sharing an album.
    <!-- a. Merge the logical songs we want to import between those units
    a. Gather the List<(SongPlayback, SongMetadata)> for each logical song
       > assume exactly one SongMetadata exists for every unique SongPlayback, but multiple SongPlaybacks can share SongMetadata with the same values
    b. 
    b. For each logical song, look up each SongPlayback in the database to see if we already have the song imported. -->



TRUE METHOD

List of Actions.
Each Action creates a logical-thing (playlist, album, tag, artist, song).
The List cannot be reordered and new Actions cannot be added, but Actions can be mutated.
^ this is so we can reference actions with stable IDs to reference the created logical-thing? but we may need to relax that

Actions can be mutated to return a different instance of the same type of logical-thing.
Actions that create a logical-song may link it to other logical things (playlist, album, tag, artist).

```rust

enum ImportActionRef<T> {
    ActionIdx(usize),
    DbId(i64),
}

enum Action {
    CreateNewPlaylist {
        name: String,
        // This action can't link to a pre-existing playlist because it would cause inconsistencies in ordering
    },
    ImportArtist(ImportArtistAction),
    ImportAlbum(ImportAlbumAction),
    // Either create a new tag or link to an existing one, purely based on the name.
    // Doesn't link any backend info to the tag itself
    ImportTag(String),
    ImportSong(ImportSongAction),
}

enum ImportArtistAction {
    CreateNewArtist {
        backendData: BackendArtist,
        name: String, // maybe == backendName, maybe not
    },
    LinkToExistingArtist {
        backendData: BackendArtist,
        existingLogicalArtistId: ImportActionRef<Artist>, // may merge with another artist in this import set!
    },
}

enum ImportAlbumAction {
    CreateNewAlbum {
        backendData: BackendAlbum,
        name: String, // maybe == backendName, maybe not
        linkedArtists: List<ImportActionRef<Artist>>,
    },
    LinkToExistingAlbum {
        backendData: BackendAlbum,
        // If it turns out the artists are already attached,
        // don't re-add them.
        newLinkedArtists: List<ImportActionRef<Artist>>,
        existingLogicalAlbumId: ImportActionRef<Album>,
    }
}

enum ImportSongAction {
    BackendIdAlreadyLinked {
        // TODO include artists here?
        newLinkedAlbum: Option<(ImportActionRef<Album>, int disc, int track)>,
        appendToPlaylist: Option<(ImportActionRef<Playlist>, int position)>,
        existingLogicalSongId: ImportActionRef<Song>,
    },
    SuggestedLinkToExistingSong {
        backendData: BackendSong,
        // If it turns out the artists are already attached,
        // don't re-add them.
        newLinkedArtists: List<ImportActionRef<Artist>>,
        // If it turns out the logical song is already attached to the album, update the order. We should be doing database ops under the hood to ensure we initially present the user with a (disc, track) that's correct
        newLinkedAlbum: Option<(ImportActionRef<Album>, int disc, int track)>,
        appendToPlaylist: Option<(ImportActionRef<Playlist>)>,
        existingLogicalSongId: ImportActionRef<Song>,
    },
    CreateNewSong {
        backendData: BackendSong,
        name: String, // maybe == backendData.name, maybe not

        newLinkedArtists: List<ImportActionRef<Artist>>,
        newLinkedAlbum: Option<(ImportActionRef<Album>, int disc, int track)>,
        appendToPlaylist: Option<ImportActionRef<Playlist>>,
    },
}
```