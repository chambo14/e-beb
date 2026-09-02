package com.example.e_beb_app

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity (et non FlutterActivity) : requis par local_auth
// pour afficher la boîte de dialogue biométrique du système (déverrouillage
// par empreinte digitale sur l'écran de verrouillage).
class MainActivity : FlutterFragmentActivity()
