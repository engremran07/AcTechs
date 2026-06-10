package com.actechs.pk

import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val PACKAGES_CHANNEL = "com.actechs.pk/packages"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            PACKAGES_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isInstalled" -> {
                    val pkg = call.argument<String>("package")
                    if (pkg == null) {
                        result.error("INVALID_ARG", "package argument is null", null)
                        return@setMethodCallHandler
                    }
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            packageManager.getPackageInfo(
                                pkg,
                                PackageManager.PackageInfoFlags.of(0),
                            )
                        } else {
                            @Suppress("DEPRECATION")
                            packageManager.getPackageInfo(pkg, 0)
                        }
                        result.success(true)
                    } catch (e: PackageManager.NameNotFoundException) {
                        result.success(false)
                    }
                }

                // ── WHATSAPP EXPLICIT-PACKAGE LAUNCH ────────────────────────
                // Uses Intent.setPackage() — the only mechanism that
                // unconditionally opens the specified app regardless of
                // OEM default-handler overrides (Samsung One UI etc.).
                // intent:// URIs are unreliable because Samsung's modified
                // ActivityManagerService can ignore the package= parameter
                // and resolve to the system-default WhatsApp handler instead.
                "openWhatsApp" -> {
                    val phone   = call.argument<String>("phone")   ?: ""
                    val pkg     = call.argument<String>("package")  ?: ""
                    val message = call.argument<String>("message")  ?: ""

                    if (phone.isEmpty() || pkg.isEmpty()) {
                        result.error("INVALID_ARG", "phone and package are required", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val encodedMsg = if (message.isNotEmpty())
                            "?text=${Uri.encode(message)}" else ""
                        val waUri = Uri.parse("whatsapp://send?phone=$phone$encodedMsg")

                        val intent = Intent(Intent.ACTION_VIEW, waUri).apply {
                            setPackage(pkg)  // Definitive fix: bypasses OEM handler override
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: ActivityNotFoundException) {
                        // Package not installed or cannot handle the URI.
                        result.success(false)
                    } catch (e: Exception) {
                        Log.w("AC_TECHS_WA", "openWhatsApp failed: ${e.message}")
                        result.success(false)
                    }
                }

                "setSecureScreen" -> {
                    val secure = call.argument<Boolean>("secure") ?: false
                    if (secure) {
                        window.setFlags(
                            WindowManager.LayoutParams.FLAG_SECURE,
                            WindowManager.LayoutParams.FLAG_SECURE,
                        )
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        Log.i("AC_TECHS_STARTUP", "MainActivity onCreate: native launch started")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            splashScreen.setOnExitAnimationListener { splashScreenView ->
                splashScreenView.remove()
            }
        }
        super.onCreate(savedInstanceState)
        Log.i("AC_TECHS_STARTUP", "MainActivity onCreate: FlutterActivity created")
    }
}

