package com.theturboturnip.android_music_store

import AlbumSummary
import Song
import android.content.Context
import android.os.Build
import android.provider.MediaStore
import android.util.Log

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.serialization.json.Json

/** AndroidMusicStorePlugin */
class AndroidMusicStorePlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private var context : Context? = null

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    context = flutterPluginBinding.applicationContext
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "android_music_store")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    if (call.method == "listAllAlbums") {
      val albumList = mutableListOf<AlbumSummary>()

      val collection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
        MediaStore.Audio.Albums.getContentUri(
          MediaStore.VOLUME_EXTERNAL
        )
      } else {
        MediaStore.Audio.Albums.EXTERNAL_CONTENT_URI
      }

      val projection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
          arrayOf(
            MediaStore.Audio.Albums._ID,
            MediaStore.Audio.Albums.ALBUM,
            MediaStore.Audio.Albums.NUMBER_OF_SONGS,
            MediaStore.Audio.Albums.ARTIST,
            MediaStore.Audio.Albums.ARTIST_ID,
          )
      } else {
        arrayOf(
          MediaStore.Audio.Albums._ID,
          MediaStore.Audio.Albums.ALBUM,
          MediaStore.Audio.Albums.NUMBER_OF_SONGS,
          MediaStore.Audio.Albums.ARTIST,
        )
      }

        val query = context?.contentResolver?.query(
        collection,
        projection,
        null,
        null,
        null,
      )
      query?.use { cursor ->
        // Cache column indices.
        val idColumn = cursor.getColumnIndexOrThrow(
          MediaStore.Audio.Albums._ID
        )
        val albumColumn = cursor.getColumnIndexOrThrow(
          MediaStore.Audio.Albums.ALBUM
        )
        val numberOfSongsColumn = cursor.getColumnIndexOrThrow(
          MediaStore.Audio.Albums.NUMBER_OF_SONGS
        )
        val artistColumn = cursor.getColumnIndexOrThrow(
          MediaStore.Audio.Albums.ARTIST
        )
        val artistIdColumn = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) cursor.getColumnIndexOrThrow(
          MediaStore.Audio.Albums.ARTIST_ID
        ) else null;

        while (cursor.moveToNext()) {
          // Get values of columns for a given video.
          val id = cursor.getLong(idColumn)
          val album = cursor.getString(albumColumn)
          val numberOfSongs = cursor.getLong(numberOfSongsColumn)
          val artist = cursor.getString(artistColumn)
          val artistId = if (artistIdColumn == null) -1 else cursor.getLong(artistIdColumn)

          // Stores column values and the contentUri in a local object
          // that represents the media file.
          albumList += AlbumSummary(
            id, album, numberOfSongs, artist, artistId
          )
        }
      }

      Log.i("MUSIC STORE PLUGIN", "albums: "+ albumList.size);

      if (query == null) {
        result.error("null_context", "Android Media Store plugin had a lifecycle problem.", null)
      } else {
        result.success(albumList.map { Json.encodeToString(AlbumSummary.serializer(), it) })
      }
    } else if (call.method == "listSongsInAlbum") {
      val songList = mutableListOf<Song>()

      val albumId = call.arguments<List<String?>>()?.get(0)

      val collection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
        MediaStore.Audio.Media.getContentUri(
          MediaStore.VOLUME_EXTERNAL
        )
      } else {
        MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
      }

      val projection = arrayOf(
        MediaStore.Audio.Media._ID,
        MediaStore.Audio.Media.TITLE,
        MediaStore.Audio.Media.DISC_NUMBER,
        MediaStore.Audio.Media.CD_TRACK_NUMBER,
        MediaStore.Audio.Media.DURATION,
        MediaStore.Audio.Media.ARTIST,
        MediaStore.Audio.Media.ARTIST_ID,
        MediaStore.Audio.Media.TRACK,
      )

      val query = context?.contentResolver?.query(
        collection,
        projection,
        "${MediaStore.Audio.Media.ALBUM_ID} = ?",
        arrayOf(albumId ?: ""),
        MediaStore.Audio.Media.TRACK,
      )
      query?.use { cursor ->
        // Cache column indices.
        val idColumn = cursor.getColumnIndexOrThrow(
          MediaStore.Audio.Media._ID
        )
        val titleColumn = cursor.getColumnIndexOrThrow(
          MediaStore.Audio.Media.TITLE
        )
        val discColumn = cursor.getColumnIndexOrThrow(
          MediaStore.Audio.Media.DISC_NUMBER
        )
        val cdTrackColumn = cursor.getColumnIndexOrThrow(
          MediaStore.Audio.Media.CD_TRACK_NUMBER
        )
        val durationColumn = cursor.getColumnIndexOrThrow(
          MediaStore.Audio.Media.DURATION
        )
        val artistColumn = cursor.getColumnIndexOrThrow(
          MediaStore.Audio.Media.ARTIST
        )
        val artistIdColumn = cursor.getColumnIndexOrThrow(
          MediaStore.Audio.Media.ARTIST_ID
        )


        while (cursor.moveToNext()) {
          // Get values of columns for a given video.
          val id = cursor.getLong(idColumn)
          val title = cursor.getString(titleColumn)
          val discNumber = cursor.getLong(discColumn)
          val cdTrack = cursor.getLong(cdTrackColumn)
          val durationMs = cursor.getLong(durationColumn)
          val artist = cursor.getString(artistColumn)
          val artistId = cursor.getLong(artistIdColumn)

          // Stores column values and the contentUri in a local object
          // that represents the media file.
          songList += Song(
            id, title, discNumber, cdTrack, durationMs, artist, artistId
          )
        }
      }

      if (query == null) {
        result.error("null_context", "Android Media Store plugin had a lifecycle problem.", null)
      } else {
        result.success(songList.map { Json.encodeToString(Song.serializer(), it) })
      }
    } else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    context = null
  }
}
