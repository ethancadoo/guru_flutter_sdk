package io.cadoo.guru_sdk


import ai.getguru.androidsdk.*
import android.app.Activity
import android.content.Context
import android.graphics.*
import android.os.Build
import androidx.annotation.NonNull
import androidx.annotation.RequiresApi
import com.google.gson.GsonBuilder
import com.google.gson.TypeAdapter
import com.google.gson.stream.JsonReader
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.*

/** GuruSdkPlugin */
class GuruSdkPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, CoroutineScope {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel

    private lateinit var context: Context
    private lateinit var activity: Activity
    private var guruVideo: GuruVideo? = null

    companion object {
        val gson = GsonBuilder()
            .registerTypeAdapter(FrameInference::class.java, FrameInferenceAdapter())
            .create()!!
    }


    private lateinit var loadGuruJob: Job

    override val coroutineContext
        get() = Dispatchers.IO + loadGuruJob


    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "guru_sdk")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        loadGuruJob = Job()
    }

    @RequiresApi(Build.VERSION_CODES.KITKAT)
    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            "createGuruVideoJob" -> {
                val args = call.arguments as ArrayList<String>
                launch(loadGuruJob) {
                    guruVideo = GuruVideoImpl.create(
                        args[0],
                        args[1],
                        args[2],
                        context
                    )
                    result.success(null)
                }
            }
            "newFrame" -> {
                val args = call.arguments as ArrayList<Any>
                val bitmap = imageToBitmap(
                    args[0] as ArrayList<ByteArray>,
                    args[1] as Int,
                    args[2] as Int,
                    args[3] as Int,
                    args[4] as Int,
                    args[5] as Int
                )
                launch(coroutineContext) {
                    val inference = guruVideo!!.newFrame(bitmap)
                    result.success(inferenceToJSON(inference))
                }
            }
            "cancelVideoJob" -> {
                loadGuruJob.cancel()
                result.success(null)
            }
            "downloadModel" -> {
                val store = ModelStore(call.arguments as String, context)
                store.startedDownloadCallback = {
                    activity.runOnUiThread {
                        channel.invokeMethod("downloadStarted", null)
                    }
                }
                store.finishedDownloadCallback = {
                    activity.runOnUiThread {
                        channel.invokeMethod("downloadFinished", null)
                    }
                }
                launch(coroutineContext) {
                    store.fetchModel()
                }
                result.success(null)
            }
            "doesModelNeedToBeDownloaded" -> {
                val store = ModelStore(call.arguments as String, context)
                launch(coroutineContext) {
                    val res = store.doesModelNeedDownloading()
                    result.success(res)
                }


            }
            else -> {
                result.notImplemented()
            }
        }
    }


    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }


    override fun onDetachedFromActivity() {
        TODO("Not yet implemented")
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        TODO("Not yet implemented")
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        TODO("Not yet implemented")
    }

    @RequiresApi(Build.VERSION_CODES.KITKAT)
    private fun imageToBitmap(
        yuvBytes: ArrayList<ByteArray>,
        yRowStride: Int,
        uvRowStride: Int,
        uvPixelStride: Int,
        height: Int,
        width: Int
    ): Bitmap {


        val rgbBytes = IntArray(width * height)
        ImageUtils.convertYUV420ToARGB8888(
            yuvBytes[0],
            yuvBytes[1],
            yuvBytes[2],
            width,
            height,
            yRowStride,
            uvRowStride,
            uvPixelStride,
            rgbBytes
        )

        val rgbFrameBitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        rgbFrameBitmap?.setPixels(rgbBytes, 0, width, 0, 0, width, height)

        return rgbFrameBitmap
    }

    private fun inferenceToJSON(inference: FrameInference): String? {

        return gson.toJson(inference)
    }

}

class FrameInferenceAdapter : TypeAdapter<FrameInference>() {

    override fun write(out: com.google.gson.stream.JsonWriter, value: FrameInference) {
        out.beginObject()
        out.name("keypoints")
        value.keypoints.let { kpMap ->
            kpMap.values.toList().let { keypointList ->
                out.beginArray()
                keypointList.forEach { k ->
                    out.beginObject()
                    out.name("x").value(k.x)
                    out.name("y").value(k.y)
                    out.name("score").value(k.score)
                    out.endObject()

                }
                out.endArray()
            }
        }

        out.name("frameIndex").value(value.frameIndex)
        out.name("secondsSinceStart").value(value.secondsSinceStart)
        out.name("analysis")
        out.beginObject()
        out.name("movement").value(value.analysis.movement)
        out.name("reps").beginArray()
        value.analysis.reps.forEach { rep ->
            rep.let {
                out.beginObject()
                out.name("startTimestamp").value(it.startTimestamp)
                out.name("midTimestamp").value(it.midTimestamp)
                out.name("endTimestamp").value(it.endTimestamp)
                out.name("analyses").value(GuruSdkPlugin.gson.toJson(it.analyses))
                out.endObject()
            }
        }
        out.endArray()
        out.endObject()
        out.name("smoothKeypoints")
        value.smoothKeypoints.let { kpMap ->
            kpMap.values.toList().let { keypointList ->
                out.beginArray()
                keypointList.forEach { k ->
                    out.beginObject()
                    out.name("x").value(k.x)
                    out.name("y").value(k.y)
                    out.name("score").value(k.score)
                    out.endObject()
                }
                out.endArray()
            }
        }
        out.name("previousFrame")
        value.previousFrame?.let { prevFrame ->
            out.beginObject()
            out.name("keypoints")
            prevFrame.keypoints.let { kpMap ->
                kpMap.values.toList().let { keypointList ->
                    out.beginArray()
                    keypointList.forEach { k ->
                        out.beginObject()
                        out.name("x").value(k.x)
                        out.name("y").value(k.y)
                        out.name("score").value(k.score)
                        out.endObject()
                    }
                    out.endArray()
                }
            }

            out.name("frameIndex").value(prevFrame.frameIndex)
            out.name("secondsSinceStart").value(prevFrame.secondsSinceStart)
            out.name("analysis")
            out.beginObject()
            out.name("movement").value(prevFrame.analysis.movement)
            out.name("reps").beginArray()
            value.analysis.reps.forEach { rep ->
                rep.let {
                    out.beginObject()
                    out.name("startTimestamp").value(it.startTimestamp)
                    out.name("midTimestamp").value(it.midTimestamp)
                    out.name("endTimestamp").value(it.endTimestamp)
                    out.name("analyses").value(GuruSdkPlugin.gson.toJson(it.analyses))
                    out.endObject()
                }
            }
            out.endArray()
            out.endObject()
            out.name("smoothKeypoints")
            prevFrame.keypoints.let { kpMap ->
                kpMap.values.toList().let { keypointList ->
                    out.beginArray()
                    keypointList.forEach { k ->
                        out.beginObject()
                        out.name("x").value(k.x)
                        out.name("y").value(k.y)
                        out.name("score").value(k.score)
                        out.endObject()
                    }
                    out.endArray()
                }
            }
            out.name("previousFrame").nullValue()

            out.endObject()
        } ?: out.nullValue()
        out.endObject()
    }

    override fun read(`in`: JsonReader?): FrameInference {
        TODO("Not yet implemented")
    }
}
