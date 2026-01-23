package com.med_tracker

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class MedicationWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val medName = widgetData.getString("medication_name", "İlaç Yok")
                val medTime = widgetData.getString("medication_time", "--:--")
                
                setTextViewText(R.id.widget_med_name, medName)
                setTextViewText(R.id.widget_med_time, medTime)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
