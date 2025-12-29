package com.love2learnsign.app

import io.flutter.embedding.android.FlutterActivity
import android.content.Context
import android.telephony.TelephonyManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import java.util.TimeZone

class MainActivity: FlutterActivity() {
  private val CHANNEL = "love_to_learn_sign/countryCode"

  companion object {
    const val NOTIF_CHANNEL = "love_to_learn_sign/notification"
    const val REQUEST_NOTIF_CODE = 1001
  }

  private var pendingNotifResult: MethodChannel.Result? = null

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(
      flutterEngine.dartExecutor.binaryMessenger,
      CHANNEL
    ).setMethodCallHandler { call, result ->
      if (call.method == "getSimCountryIso") {
        val tm = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
        val iso = tm.simCountryIso?.uppercase()
        if (iso != null && iso.isNotEmpty()) {
          result.success(iso)
        } else {
          result.error("UNAVAILABLE", "SIM country ISO not available", null)
        }
      } else {
        result.notImplemented()
      }
    }

    MethodChannel(
      flutterEngine.dartExecutor.binaryMessenger,
      NOTIF_CHANNEL
    ).setMethodCallHandler { call, result ->
      when (call.method) {
        "checkPermission" -> {
          val granted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
          } else {
            true
          }
          result.success(granted)
        }
        "requestPermission" -> {
          if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pendingNotifResult = result
            ActivityCompat.requestPermissions(
              this,
              arrayOf(Manifest.permission.POST_NOTIFICATIONS),
              REQUEST_NOTIF_CODE
            )
          } else {
            result.success(true)
          }
        }
        else -> result.notImplemented()
      }
    }

    // Timezone channel: returns device timezone ID (e.g., "Europe/Paris")
    MethodChannel(
      flutterEngine.dartExecutor.binaryMessenger,
      "love_to_learn_sign/timezone"
    ).setMethodCallHandler { call, result ->
      if (call.method == "getTimeZoneName") {
        try {
          val id = TimeZone.getDefault().id
          result.success(id)
        } catch (e: Exception) {
          result.error("UNAVAILABLE", "Timezone not available", null)
        }
      } else {
        result.notImplemented()
      }
    }
  }

  override fun onRequestPermissionsResult(
    requestCode: Int,
    permissions: Array<out String>,
    grantResults: IntArray
  ) {
    super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    if (requestCode == REQUEST_NOTIF_CODE) {
      val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
      pendingNotifResult?.success(granted)
      pendingNotifResult = null
    }
  }
}


