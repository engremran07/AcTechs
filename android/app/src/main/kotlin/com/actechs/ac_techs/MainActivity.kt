package com.actechs.ac_techs

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
	override fun onCreate(savedInstanceState: Bundle?) {
		Log.i("AC_TECHS_STARTUP", "MainActivity onCreate: native launch started")
		super.onCreate(savedInstanceState)
		Log.i("AC_TECHS_STARTUP", "MainActivity onCreate: FlutterActivity created")
	}
}
