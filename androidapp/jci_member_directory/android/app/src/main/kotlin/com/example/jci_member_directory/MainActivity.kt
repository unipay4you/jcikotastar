package com.example.jci_member_directory

import android.content.Intent
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import android.provider.MediaStore
import android.content.ContentValues
import java.io.FileInputStream
import java.io.FileOutputStream
import java.nio.channels.FileChannel
import java.nio.file.Files
import java.nio.file.attribute.BasicFileAttributes
import java.nio.file.attribute.FileTime
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine
import android.content.ContentResolver
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.jci_member_directory/media"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveImage" -> {
                    val path = call.argument<String>("path")
                    val bytes = call.argument<ByteArray>("bytes")
                    if (path != null && bytes != null) {
                        try {
                            val contentValues = ContentValues().apply {
                                put(MediaStore.Images.Media.DISPLAY_NAME, File(path).name)
                                put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                    put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/JCIKotaStar")
                                    put(MediaStore.Images.Media.IS_PENDING, 1)
                                }
                            }

                            val contentResolver = context.contentResolver
                            val uri = contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, contentValues)
                            
                            if (uri != null) {
                                contentResolver.openOutputStream(uri)?.use { outputStream ->
                                    outputStream.write(bytes)
                                }

                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                    contentValues.clear()
                                    contentValues.put(MediaStore.Images.Media.IS_PENDING, 0)
                                    contentResolver.update(uri, contentValues, null, null)
                                }

                                // Notify media scanner
                                MediaScannerConnection.scanFile(
                                    context,
                                    arrayOf(uri.toString()),
                                    arrayOf("image/jpeg"),
                                    null
                                )

                                result.success(uri.toString())
                            } else {
                                result.error("SAVE_ERROR", "Failed to create new MediaStore record", null)
                            }
                        } catch (e: Exception) {
                            result.error("SAVE_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENTS", "Path or bytes is null", null)
                    }
                }
                "scanFile" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        try {
                            val file = File(path)
                            if (file.exists()) {
                                MediaScannerConnection.scanFile(
                                    context,
                                    arrayOf(path),
                                    arrayOf("image/jpeg"),
                                    null
                                )
                                result.success(true)
                            } else {
                                result.error("FILE_NOT_FOUND", "File does not exist", null)
                            }
                        } catch (e: Exception) {
                            result.error("SCAN_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_PATH", "Path is null", null)
                    }
                }
                "openGallery" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        try {
                            val uri = Uri.parse(path)
                            val intent = Intent(Intent.ACTION_VIEW).apply {
                                setDataAndType(uri, "image/*")
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            context.startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("GALLERY_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_PATH", "Path is null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
