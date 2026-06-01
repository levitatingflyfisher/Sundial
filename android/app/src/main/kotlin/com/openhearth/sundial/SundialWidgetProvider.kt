package com.openhearth.sundial

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.app.PendingIntent
import android.content.Intent
import es.antonborri.home_widget.HomeWidgetPlugin

class SundialWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = HomeWidgetPlugin.getData(context)
        val todayHours = prefs.getString("today_hours", "0m") ?: "0m"

        // launch_source=widget tells MainActivity to flip the app into Flow
        // mode via the media_session MethodChannel. SINGLE_TOP|CLEAR_TOP lets
        // an already-running MainActivity receive the new intent through
        // onNewIntent instead of starting a fresh instance.
        val launchIntent = Intent(context, MainActivity::class.java).apply {
            putExtra("launch_source", "widget")
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_NEW_TASK
        }
        val pendingIntent = PendingIntent.getActivity(
            context, 0, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.sundial_widget)
            views.setTextViewText(R.id.widget_today_hours, todayHours)
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
