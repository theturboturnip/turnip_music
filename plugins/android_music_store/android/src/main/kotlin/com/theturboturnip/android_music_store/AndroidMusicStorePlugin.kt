package com.theturboturnip.android_music_store

import AlbumSummary
import Song
import android.content.ContentUris
import android.content.Context
import android.graphics.Bitmap
import android.provider.MediaStore
import android.util.Log
import android.util.Size
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.coroutineScope
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.embedding.engine.plugins.lifecycle.FlutterLifecycleAdapter
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import java.io.ByteArrayOutputStream
import java.io.FileNotFoundException


/** AndroidMusicStorePlugin */
class AndroidMusicStorePlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private var applicationContext : Context? = null
  private var lifecycle : Lifecycle? = null

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    applicationContext = flutterPluginBinding.applicationContext
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "android_music_store")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    if (call.method == "listAllAlbums") {
      val albumList = mutableListOf<AlbumSummary>()

      val collection = MediaStore.Audio.Albums.getContentUri(
        MediaStore.VOLUME_EXTERNAL
      )

      val projection = arrayOf(
        MediaStore.Audio.Albums._ID,
        MediaStore.Audio.Albums.ALBUM,
        MediaStore.Audio.Albums.NUMBER_OF_SONGS,
        MediaStore.Audio.Albums.ARTIST,
        MediaStore.Audio.Albums.ARTIST_ID,
      )


      val query = applicationContext?.contentResolver?.query(
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
        val artistIdColumn = cursor.getColumnIndexOrThrow(
          MediaStore.Audio.Albums.ARTIST_ID
        )

        while (cursor.moveToNext()) {
          // Get values of columns for a given video.
          val id = cursor.getLong(idColumn)
          val album = cursor.getString(albumColumn)
          val numberOfSongs = cursor.getLong(numberOfSongsColumn)
          val artist = cursor.getString(artistColumn)
          val artistId = cursor.getLong(artistIdColumn)

          // Stores column values and the contentUri in a local object
          // that represents the media file.
          albumList += AlbumSummary(
            id, album, numberOfSongs, artist, artistId
          )
        }
      }

      Log.i("MUSIC STORE PLUGIN", "albums: "+ albumList.size)

      if (query == null) {
        result.error("null_context", "Android Media Store plugin had a lifecycle problem.", null)
      } else {
        result.success(albumList.map { Json.encodeToString(AlbumSummary.serializer(), it) })
      }
    } else if (call.method == "listSongsInAlbum") {
      val songList = mutableListOf<Song>()

      val albumId = call.arguments<List<String?>>()?.get(0)

      val collection = MediaStore.Audio.Media.getContentUri(
        MediaStore.VOLUME_EXTERNAL
      )

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

      val query = applicationContext?.contentResolver?.query(
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
    } else if (call.method == "requestArtsForAlbums") {
      val args = call.arguments<List<String>>()

      val albumIds: Sequence<Long>?
      val thumbSize: Int?
      try {
        thumbSize = args?.get(0)?.toInt()
        albumIds = args?.listIterator(1)?.asSequence()?.map { it.toLong() }
      } catch (ex: NumberFormatException) {
        result.error("nan_album_id", "resolveAlbumArtThumb got non-number arguments: $args", null)
        return
      }

      if (albumIds == null || thumbSize == null) {
        result.error("null_album_id", "resolveAlbumArtThumb got null arguments: $albumIds $thumbSize", null)
      } else {
        lifecycle?.coroutineScope?.launch(Dispatchers.IO) {
          albumIds.forEach {
            val contentUri = ContentUris.withAppendedId(
              MediaStore.Audio.Albums.EXTERNAL_CONTENT_URI,
              it
            )

            val bitmap = try {
              applicationContext?.contentResolver?.loadThumbnail(contentUri, Size(thumbSize, thumbSize), null)
            } catch (ex: FileNotFoundException) {
              null
            }

            val outputArgs: List<Any?>
            if (bitmap == null) {
              outputArgs = listOf<Any?>(it.toString(), null)
            } else {
              val stream = ByteArrayOutputStream()
              bitmap.compress(Bitmap.CompressFormat.JPEG, 95, stream)
              val byteArray = stream.toByteArray()
              val width = bitmap.width
              val height = bitmap.height
              bitmap.recycle()
              outputArgs = listOf<Any?>(it.toString(), byteArray, width, height)
            }
            withContext(Dispatchers.Main) {
              channel.invokeMethod("receiveAlbumArt", outputArgs)
            }
          }
        }
        result.success(null)
      }
    } else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    applicationContext = null
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    lifecycle = FlutterLifecycleAdapter.getActivityLifecycle(binding)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    lifecycle = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    lifecycle = FlutterLifecycleAdapter.getActivityLifecycle(binding)
  }

  override fun onDetachedFromActivity() {
    lifecycle = null
  }
}
