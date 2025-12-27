package com.lovetolearnsign.app

import android.app.Application
import com.google.android.material.color.DynamicColors

class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        // Active le Dynamic Color (Android 12+), fallback sur vos thèmes XML < API 31
        DynamicColors.applyToActivitiesIfAvailable(this)
    }
}
