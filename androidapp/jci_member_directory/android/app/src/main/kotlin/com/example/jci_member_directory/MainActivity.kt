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

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.jci_member_directory/media"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scanFile" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        val file = File(path)
                        if (file.exists()) {
                            // First update the file timestamps
                            val currentTime = System.currentTimeMillis()
                            file.setLastModified(currentTime)
                            
                            // Then update MediaStore
                            val values = ContentValues().apply {
                                put(MediaStore.Images.Media.DISPLAY_NAME, file.name)
                                put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
                                put(MediaStore.Images.Media.DATA, file.absolutePath)
                                put(MediaStore.Images.Media.DATE_ADDED, currentTime / 1000)
                                put(MediaStore.Images.Media.DATE_MODIFIED, currentTime / 1000)
                            }
                            
                            // Insert into MediaStore
                            val uri = context.contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
                            
                            // Force media scanner to scan the file
                            MediaScannerConnection.scanFile(
                                context,
                                arrayOf(path),
                                arrayOf("image/jpeg"),
                                null
                            )
                            
                            // Wait a bit to ensure scanning is complete
                            Thread.sleep(1000)
                            
                            result.success(true)
                        } else {
                            result.error("FILE_NOT_FOUND", "File does not exist", null)
                        }
                    } else {
                        result.error("INVALID_PATH", "Path is null", null)
                    }
                }
                "setFileCreationTime" -> {
                    val path = call.argument<String>("path")
                    val timestamp = call.argument<Long>("timestamp")
                    if (path != null && timestamp != null) {
                        try {
                            val file = File(path)
                            if (file.exists()) {
                                // Set file system timestamps
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                    val fileTime = FileTime.fromMillis(timestamp)
                                    Files.setAttribute(file.toPath(), "creationTime", fileTime)
                                    Files.setAttribute(file.toPath(), "lastModifiedTime", fileTime)
                                }
                                
                                // Update MediaStore entry
                                val values = ContentValues().apply {
                                    put(MediaStore.Images.Media.DATE_ADDED, timestamp / 1000)
                                    put(MediaStore.Images.Media.DATE_MODIFIED, timestamp / 1000)
                                }
                                val uri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
                                val selection = "${MediaStore.Images.Media.DATA} = ?"
                                val selectionArgs = arrayOf(file.absolutePath)
                                context.contentResolver.update(uri, values, selection, selectionArgs)
                                
                                // Force media scanner to scan the file again
                                MediaScannerConnection.scanFile(
                                    context,
                                    arrayOf(path),
                                    arrayOf("image/jpeg"),
                                    null
                                )
                                
                                // Wait a bit to ensure scanning is complete
                                Thread.sleep(1000)
                                
                                result.success(true)
                            } else {
                                result.error("FILE_NOT_FOUND", "File does not exist", null)
                            }
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENTS", "Path or timestamp is null", null)
                    }
                }
                "openGallery" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        val file = File(path)
                        if (file.exists()) {
                            // First ensure the file is properly scanned
                            MediaScannerConnection.scanFile(
                                context,
                                arrayOf(path),
                                arrayOf("image/jpeg"),
                                null
                            )
                            
                            // Wait a bit to ensure scanning is complete
                            Thread.sleep(1000)
                            
                            // Try to open Google Photos first
                            try {
                                val intent = Intent(Intent.ACTION_VIEW).apply {
                                    setDataAndType(Uri.fromFile(file), "image/*")
                                    setPackage("com.google.android.apps.photos")
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                context.startActivity(intent)
                                result.success(true)
                            } catch (e: Exception) {
                                // If Google Photos fails, try system gallery
                                val intent = Intent(Intent.ACTION_VIEW).apply {
                                    setDataAndType(Uri.fromFile(file), "image/*")
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                context.startActivity(intent)
                                result.success(true)
                            }
                        } else {
                            result.error("FILE_NOT_FOUND", "File does not exist", null)
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
