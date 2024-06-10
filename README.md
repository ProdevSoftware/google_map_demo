# Google Map App in Flutter

Google Maps app is a simple flutter app that helps you locate your nearest location and get there. This README provides a comprehensive guide on setting up, configuring, and running the application.

## Features

- Here it will show your current location
- A polyline will appear from your current location to the location you selected
- if you click on map, it will show you the path from your current location to the selected location 
- Here you are also given the option of location search so that you can find your target location


## Getting Started

## 1. Dependencies

- Add below dependencies in pubspec.yaml
 ```
  cupertino_icons: ^1.0.6
  google_maps_flutter: ^2.6.1
  geocoding: ^3.0.0
  flutter_polyline_points: ^1.0.0
  google_maps_place_picker_mb: ^3.0.2
  lottie: ^3.0.0
  flutter_svg: ^2.0.9
  uuid: ^3.0.7
  google_places_flutter: ^2.0.8
```
## 2. Add this permission in AndroidManifest.xml file
```
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="com.google.android.providers.gsf.permission.READ_GSERVICES" />  
```
- Add your Google Map api key
```
  <meta-data android:name="com.google.android.geo.API_KEY"
   android:value= " YOUR_API_KEY " />
```
## Video

https://github.com/ProdevSoftware/google_map_demo/assets/97152083/fd45b7f6-303d-45f6-99a9-d70495155b18

