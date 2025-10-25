package com.the360ghar.ghar360

import android.content.res.Configuration
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onResume() {
        super.onResume()

        // Enable edge-to-edge display for Android 15+ (SDK 35) and backward compatibility
        WindowCompat.setDecorFitsSystemWindows(window, false)

        // Determine current UI mode (light/dark) to respect theme settings
        val nightModeFlags = resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
        val isNightMode = nightModeFlags == Configuration.UI_MODE_NIGHT_YES

        // Configure window insets for edge-to-edge display
        WindowInsetsControllerCompat(window, window.decorView).let { controller ->
            // Show status bar and navigation bar
            controller.show(
                WindowInsetsCompat.Type.statusBars() or WindowInsetsCompat.Type.navigationBars()
            )
            // Respect dark mode: use light icons (false) on dark backgrounds
            controller.isAppearanceLightStatusBars = !isNightMode
            controller.isAppearanceLightNavigationBars = !isNightMode
        }
    }
}
