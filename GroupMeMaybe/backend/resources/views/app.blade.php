<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>GroupMeMaybe Dashboard</title>
    <base href="/">
    <link rel="stylesheet" href="{{ asset('flutter/assets/css/app.css') }}">
</head>
<body>
    <div id="app">
        @if (File::exists(public_path('flutter/index.html')) )
            {!! File::get(public_path('flutter/index.html')) !!}
        @else
            <p>Flutter app not found. Please build and copy assets.</p>
        @endif
    </div>
    <script src="{{ asset('flutter/flutter.js') }}"></script>
    <script src="{{ asset('flutter/main.dart.js') }}"></script>
</body>
</html>