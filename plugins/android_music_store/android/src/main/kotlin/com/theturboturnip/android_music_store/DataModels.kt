import kotlinx.serialization.Serializable

@Serializable
data class AlbumSummary(
    val id: Long,
    val title: String,
    val numberOfSongs: Long,
    val mainArtist: String,
    val mainArtistId: Long,
)

@Serializable
data class Song(
    val id: Long,
    val title: String,
    val discNumber: Long,
    val trackNumber: Long,
    val durationMs: Long,
    val mainArtist: String,
    val mainArtistId: Long,
)