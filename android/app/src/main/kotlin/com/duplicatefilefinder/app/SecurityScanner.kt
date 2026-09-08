package com.duplicatefilefinder.app

import android.app.AppOpsManager
import android.app.KeyguardManager
import android.app.admin.DevicePolicyManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.BatteryManager
import android.os.Build
import android.provider.Settings
import java.io.File
import java.security.KeyStore

class SecurityScanner(private val context: Context) {

    fun run(): Map<String, Any> {
        return mapOf(
            "platform" to "android",
            "checks" to listOf(
                checkKnownStalkerware(),
                checkRoot(),
                checkAccessibility(),
                checkDeviceAdmins(),
                checkUsbDebugging(),
                checkAdbWifi(),
                checkDeveloperOptions(),
                checkOverlays(),
                checkNotificationListeners(),
                checkVpn(),
                checkUserCertificates(),
                checkMockLocation(),
                checkScreenLock(),
            ),
        )
    }

    private fun check(
        id: String,
        title: String,
        status: String,
        summary: String,
        detail: String,
        settingsAction: String? = null,
        items: List<String> = emptyList(),
    ): Map<String, Any> {
        val map = mutableMapOf<String, Any>(
            "id" to id,
            "title" to title,
            "status" to status,
            "summary" to summary,
            "detail" to detail,
            "items" to items,
        )
        if (settingsAction != null) {
            map["settingsAction"] = settingsAction
        }
        return map
    }

    private fun checkKnownStalkerware(): Map<String, Any> {
        val hits = installedPackages().mapNotNull { info ->
            val pkg = info.packageName ?: return@mapNotNull null
            if (!looksLikeStalkerware(pkg)) return@mapNotNull null
            appLabel(pkg)
        }.distinct()

        if (hits.isEmpty()) {
            return check(
                id = "stalkerware",
                title = "Known spyware apps",
                status = "pass",
                summary = "No well-known stalkerware packages were found",
                detail = "This check looks for publicly documented spyware / stalkerware package names. New or custom spy apps will not appear here.",
            )
        }

        return check(
            id = "stalkerware",
            title = "Known spyware apps",
            status = "fail",
            summary = "Possible spyware is installed on this phone",
            detail = "Uninstall these apps immediately, then change important passwords from a different device. A factory reset is the safest cleanup if you did not install them yourself.",
            settingsAction = "security",
            items = hits,
        )
    }

    private fun checkRoot(): Map<String, Any> {
        val signals = mutableListOf<String>()
        val paths = listOf(
            "/system/app/Superuser.apk",
            "/system/xbin/su",
            "/system/bin/su",
            "/sbin/su",
            "/data/local/xbin/su",
            "/data/local/bin/su",
            "/data/local/su",
            "/su/bin/su",
            "/system/sd/xbin/su",
            "/system/bin/failsafe/su",
            "/sbin/.magisk",
            "/data/adb/magisk",
            "/data/adb/ksu",
        )
        for (path in paths) {
            if (File(path).exists()) {
                signals.add(path)
            }
        }
        if (Build.TAGS?.contains("test-keys") == true) {
            signals.add("Build tags: test-keys")
        }

        if (signals.isEmpty()) {
            return check(
                id = "root",
                title = "Root / jailbreak tools",
                status = "pass",
                summary = "No common root tools were detected",
                detail = "Rooted phones are easier to bug because apps can hide outside normal Android protections.",
            )
        }

        return check(
            id = "root",
            title = "Root / jailbreak tools",
            status = "warning",
            summary = "This phone looks rooted",
            detail = "Root access is not always spyware, but it lets hidden apps bypass Android privacy controls. If you did not root this phone yourself, treat it as compromised.",
            items = signals.take(6),
        )
    }

    private fun checkAccessibility(): Map<String, Any> {
        val raw = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
        ).orEmpty()

        val packages = raw.split(':')
            .map { it.substringBefore('/').trim() }
            .filter { it.isNotEmpty() }
            .distinct()

        val suspicious = packages.filter { pkg ->
            pkg != context.packageName && !isTrustedAccessibility(pkg)
        }.map(::appLabel).distinct()

        if (packages.isEmpty()) {
            return check(
                id = "accessibility",
                title = "Screen-reading access",
                status = "pass",
                summary = "No accessibility services are enabled",
                detail = "Spyware often turns on Accessibility so it can read your screen, passwords, and chats.",
                settingsAction = "accessibility",
            )
        }

        if (suspicious.isEmpty()) {
            return check(
                id = "accessibility",
                title = "Screen-reading access",
                status = "pass",
                summary = "Only known accessibility tools are enabled",
                detail = "TalkBack and similar system tools are expected. Review this list if you do not use a screen reader.",
                settingsAction = "accessibility",
                items = packages.map(::appLabel).distinct(),
            )
        }

        return check(
            id = "accessibility",
            title = "Screen-reading access",
            status = "warning",
            summary = "Apps can read your screen",
            detail = "These apps have Accessibility access. That is normal for password managers and screen readers, and it is also the most common way spyware watches a phone. Turn off any app you do not recognize.",
            settingsAction = "accessibility",
            items = suspicious,
        )
    }

    private fun checkDeviceAdmins(): Map<String, Any> {
        val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val admins = dpm.activeAdmins.orEmpty()
            .map { it.packageName }
            .distinct()
            .filter { it != context.packageName }

        val thirdParty = admins.filter { !isSystemApp(it) }.map(::appLabel).distinct()

        if (admins.isEmpty()) {
            return check(
                id = "device_admin",
                title = "Device admin apps",
                status = "pass",
                summary = "No device admin apps are active",
                detail = "Device admin permission can lock settings and make spyware hard to uninstall.",
                settingsAction = "security",
            )
        }

        if (thirdParty.isEmpty()) {
            return check(
                id = "device_admin",
                title = "Device admin apps",
                status = "info",
                summary = "Only system admin apps are active",
                detail = "Work profile or manufacturer tools often need this. Confirm you set them up.",
                settingsAction = "security",
                items = admins.map(::appLabel).distinct(),
            )
        }

        return check(
            id = "device_admin",
            title = "Device admin apps",
            status = "fail",
            summary = "Third-party apps can control this device",
            detail = "Deactivate device admin for any app you do not trust, then uninstall it. Spyware uses this to survive deletion.",
            settingsAction = "security",
            items = thirdParty,
        )
    }

    private fun checkUsbDebugging(): Map<String, Any> {
        val adb = Settings.Global.getInt(context.contentResolver, Settings.Global.ADB_ENABLED, 0) == 1
        val usbConnected = isUsbConnected()

        if (!adb) {
            return check(
                id = "usb_debugging",
                title = "USB debugging",
                status = "pass",
                summary = "USB debugging is off",
                detail = "USB debugging lets a computer install apps and copy data when this phone is plugged in.",
                settingsAction = "developer",
            )
        }

        val extra = if (usbConnected) " A USB cable is connected right now." else ""
        return check(
            id = "usb_debugging",
            title = "USB debugging",
            status = "warning",
            summary = "USB debugging is on",
            detail = "Anyone with a computer and cable can more easily install hidden apps or pull data.$extra Turn this off unless you are a developer using this phone.",
            settingsAction = "developer",
        )
    }

    private fun checkAdbWifi(): Map<String, Any> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            return check(
                id = "adb_wifi",
                title = "Wireless debugging",
                status = "info",
                summary = "Not available on this Android version",
                detail = "Wireless debugging exists on Android 11 and newer.",
            )
        }

        val enabled = Settings.Global.getInt(
            context.contentResolver,
            "adb_wifi_enabled",
            0,
        ) == 1

        if (!enabled) {
            return check(
                id = "adb_wifi",
                title = "Wireless debugging",
                status = "pass",
                summary = "Wireless debugging is off",
                detail = "Wireless debugging can let a nearby computer control this phone without a cable.",
                settingsAction = "developer",
            )
        }

        return check(
            id = "adb_wifi",
            title = "Wireless debugging",
            status = "fail",
            summary = "Wireless debugging is on",
            detail = "Turn this off unless you are actively developing. It is a common way to plant a bug without touching the phone.",
            settingsAction = "developer",
        )
    }

    private fun checkDeveloperOptions(): Map<String, Any> {
        val enabled = Settings.Global.getInt(
            context.contentResolver,
            Settings.Global.DEVELOPMENT_SETTINGS_ENABLED,
            0,
        ) == 1

        if (!enabled) {
            return check(
                id = "developer",
                title = "Developer options",
                status = "pass",
                summary = "Developer options are off",
                detail = "Developer options unlock extra controls that make a phone easier to tamper with.",
                settingsAction = "developer",
            )
        }

        return check(
            id = "developer",
            title = "Developer options",
            status = "warning",
            summary = "Developer options are on",
            detail = "This is common for testers. If you never turned it on, someone else may have used this phone.",
            settingsAction = "developer",
        )
    }

    private fun checkOverlays(): Map<String, Any> {
        val overlayApps = installedPackages().mapNotNull { pkg ->
            val name = pkg.packageName ?: return@mapNotNull null
            if (name == context.packageName || isSystemApp(name)) return@mapNotNull null
            if (!canDrawOverlays(pkg.applicationInfo ?: return@mapNotNull null, name)) {
                return@mapNotNull null
            }
            appLabel(name)
        }.distinct()

        if (overlayApps.isEmpty()) {
            return check(
                id = "overlay",
                title = "Draw over other apps",
                status = "pass",
                summary = "No extra overlay apps were found",
                detail = "Overlay permission can fake buttons or hide a recording app on top of the real screen.",
                settingsAction = "overlay",
            )
        }

        return check(
            id = "overlay",
            title = "Draw over other apps",
            status = "warning",
            summary = "Apps can draw over your screen",
            detail = "Chat bubbles and some launchers need this. Remove overlay access from any app you do not recognize.",
            settingsAction = "overlay",
            items = overlayApps.take(20),
        )
    }

    private fun checkNotificationListeners(): Map<String, Any> {
        val raw = Settings.Secure.getString(
            context.contentResolver,
            "enabled_notification_listeners",
        ).orEmpty()

        val packages = raw.split(':')
            .map { it.substringBefore('/').trim() }
            .filter { it.isNotEmpty() }
            .distinct()

        val thirdParty = packages.filter { pkg ->
            pkg != context.packageName && !isSystemApp(pkg)
        }.map(::appLabel).distinct()

        if (packages.isEmpty()) {
            return check(
                id = "notifications",
                title = "Notification access",
                status = "pass",
                summary = "No notification listeners are enabled",
                detail = "Apps with notification access can read message previews, one-time codes, and alerts.",
                settingsAction = "notification",
            )
        }

        if (thirdParty.isEmpty()) {
            return check(
                id = "notifications",
                title = "Notification access",
                status = "pass",
                summary = "Only system apps can read notifications",
                detail = "Wearables and manufacturer tools often need this.",
                settingsAction = "notification",
                items = packages.map(::appLabel).distinct(),
            )
        }

        return check(
            id = "notifications",
            title = "Notification access",
            status = "warning",
            summary = "Apps can read your notifications",
            detail = "Turn off notification access for any app that does not need it. Spyware uses this to copy chats and passwords sent by SMS.",
            settingsAction = "notification",
            items = thirdParty,
        )
    }

    private fun checkVpn(): Map<String, Any> {
        val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
            ?: return check(
                id = "vpn",
                title = "VPN connection",
                status = "info",
                summary = "Could not check VPN status",
                detail = "A VPN can protect privacy, but a hidden VPN can also reroute your traffic.",
                settingsAction = "vpn",
            )

        val network = cm.activeNetwork
        val caps = network?.let { cm.getNetworkCapabilities(it) }
        val vpnOn = caps?.hasTransport(NetworkCapabilities.TRANSPORT_VPN) == true

        if (!vpnOn) {
            return check(
                id = "vpn",
                title = "VPN connection",
                status = "pass",
                summary = "No VPN is active right now",
                detail = "A VPN you did not set up can send browsing and app traffic through someone else's server.",
                settingsAction = "vpn",
            )
        }

        return check(
            id = "vpn",
            title = "VPN connection",
            status = "info",
            summary = "A VPN is active",
            detail = "This is normal if you turned on a VPN yourself. If you did not, open VPN settings and disconnect or remove the unknown profile.",
            settingsAction = "vpn",
        )
    }

    private fun checkUserCertificates(): Map<String, Any> {
        val userCerts = mutableListOf<String>()
        try {
            val keyStore = KeyStore.getInstance("AndroidCAStore")
            keyStore.load(null)
            val aliases = keyStore.aliases()
            while (aliases.hasMoreElements()) {
                val alias = aliases.nextElement()
                if (alias.startsWith("user:")) {
                    userCerts.add(alias.removePrefix("user:"))
                }
            }
        } catch (_: Exception) {
            // Fall through with whatever was collected.
        }

        if (userCerts.isEmpty()) {
            return check(
                id = "certificates",
                title = "Trusted certificates",
                status = "pass",
                summary = "No extra user certificates were found",
                detail = "A user-installed certificate can let someone intercept HTTPS traffic, including logins.",
                settingsAction = "security",
            )
        }

        return check(
            id = "certificates",
            title = "Trusted certificates",
            status = "fail",
            summary = "Extra certificates can intercept traffic",
            detail = "Remove any certificate you did not install for work or school. This is a classic phone-bug technique.",
            settingsAction = "security",
            items = userCerts.take(10),
        )
    }

    private fun checkMockLocation(): Map<String, Any> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            val allowed = Settings.Secure.getInt(
                context.contentResolver,
                Settings.Secure.ALLOW_MOCK_LOCATION,
                0,
            ) == 1
            return if (allowed) {
                check(
                    id = "mock_location",
                    title = "Fake location",
                    status = "warning",
                    summary = "Mock locations are allowed",
                    detail = "Fake GPS can hide where this phone really is.",
                    settingsAction = "developer",
                )
            } else {
                check(
                    id = "mock_location",
                    title = "Fake location",
                    status = "pass",
                    summary = "Mock locations are off",
                    detail = "Fake GPS can hide where this phone really is.",
                    settingsAction = "developer",
                )
            }
        }

        val mockApps = installedPackages().mapNotNull { pkg ->
            val name = pkg.packageName ?: return@mapNotNull null
            if (name == context.packageName || isSystemApp(name)) return@mapNotNull null
            val appInfo = pkg.applicationInfo ?: return@mapNotNull null
            if (!hasMockLocation(appInfo, name)) return@mapNotNull null
            appLabel(name)
        }.distinct()

        if (mockApps.isEmpty()) {
            return check(
                id = "mock_location",
                title = "Fake location",
                status = "pass",
                summary = "No mock-location apps were found",
                detail = "Fake GPS can hide where this phone really is.",
                settingsAction = "developer",
            )
        }

        return check(
            id = "mock_location",
            title = "Fake location",
            status = "warning",
            summary = "Apps can fake this phone's location",
            detail = "Turn off mock location in Developer options unless you use it on purpose.",
            settingsAction = "developer",
            items = mockApps,
        )
    }

    private fun checkScreenLock(): Map<String, Any> {
        val km = context.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        val secure = km.isDeviceSecure
        if (secure) {
            return check(
                id = "screen_lock",
                title = "Screen lock",
                status = "pass",
                summary = "A PIN, pattern, or password is set",
                detail = "A lock screen makes it harder for someone to install a bug while the phone is unattended.",
                settingsAction = "security",
            )
        }

        return check(
            id = "screen_lock",
            title = "Screen lock",
            status = "warning",
            summary = "This phone is not locked",
            detail = "Set a PIN or password. Without one, anyone who picks up the phone can install spyware in minutes.",
            settingsAction = "security",
        )
    }

    private fun isUsbConnected(): Boolean {
        return try {
            val battery = context.registerReceiver(
                null,
                IntentFilter(Intent.ACTION_BATTERY_CHANGED),
            )
            val plugged = battery?.getIntExtra(BatteryManager.EXTRA_PLUGGED, -1) ?: -1
            plugged == BatteryManager.BATTERY_PLUGGED_USB
        } catch (_: Exception) {
            false
        }
    }

    private fun canDrawOverlays(appInfo: ApplicationInfo, packageName: String): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as? AppOpsManager
            ?: return false
        return try {
            val mode = appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_SYSTEM_ALERT_WINDOW,
                appInfo.uid,
                packageName,
            )
            mode == AppOpsManager.MODE_ALLOWED
        } catch (_: Exception) {
            false
        }
    }

    private fun hasMockLocation(appInfo: ApplicationInfo, packageName: String): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as? AppOpsManager
            ?: return false
        return try {
            val mode = appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_MOCK_LOCATION,
                appInfo.uid,
                packageName,
            )
            mode == AppOpsManager.MODE_ALLOWED
        } catch (_: Exception) {
            false
        }
    }

    private fun installedPackages(): List<android.content.pm.PackageInfo> {
        val pm = context.packageManager
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                pm.getInstalledPackages(PackageManager.PackageInfoFlags.of(0))
            } else {
                @Suppress("DEPRECATION")
                pm.getInstalledPackages(0)
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    private fun appLabel(packageName: String): String {
        return try {
            val info = context.packageManager.getApplicationInfo(packageName, 0)
            "${context.packageManager.getApplicationLabel(info)} ($packageName)"
        } catch (_: Exception) {
            packageName
        }
    }

    private fun isSystemApp(packageName: String): Boolean {
        return try {
            val info = context.packageManager.getApplicationInfo(packageName, 0)
            val flags = info.flags
            flags and ApplicationInfo.FLAG_SYSTEM != 0 ||
                flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP != 0
        } catch (_: Exception) {
            false
        }
    }

    private fun isTrustedAccessibility(packageName: String): Boolean {
        if (isSystemApp(packageName)) return true
        val trusted = setOf(
            "com.google.android.marvin.talkback",
            "com.google.android.accessibility.switchaccess",
            "com.google.android.apps.accessibility.voiceaccess",
            "com.google.android.accessibility.soundamplifier",
            "com.google.android.accessibility.accessibilitymenu",
            "com.google.android.apps.accessibility.reveal",
            "com.samsung.android.accessibility.talkback",
            "com.samsung.accessibility",
            "com.android.talkback",
        )
        return trusted.contains(packageName)
    }

    private fun looksLikeStalkerware(packageName: String): Boolean {
        val pkg = packageName.lowercase()
        val brands = listOf(
            "flexispy",
            "mspy",
            "thetruthspy",
            "hoverwatch",
            "xtremespy",
            "cocospy",
            "minispy",
            "spyzie",
            "snoopza",
            "highstermobile",
            "highster.mobile",
            "fonemonitor",
            "easylogger",
            "mobilespy",
            "phonespying",
            "spyhuman",
            "trackview",
            "mobiispy",
            "guestspy",
        )
        if (brands.any { pkg.contains(it) }) return true

        val exact = setOf(
            "com.cerberus",
            "com.cerberus.app",
        )
        return exact.contains(pkg)
    }
}
