<?php
/**
 * Login Blade template
 */
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>GroupMeMaybe – Login</title>
    <style>
        body {font-family: Arial, sans-serif; background:#f5f5f5; display:flex; align-items:center; justify-content:center; height:100vh;}
        .login-box {background:#fff; padding:2rem; border-radius:8px; box-shadow:0 2px 8px rgba(0,0,0,0.1); width:300px;}
        input {width:100%; padding:0.5rem; margin:0.5rem 0;}
        button {width:100%; padding:0.5rem; background:#0069d9; color:#fff; border:none; border-radius:4px;}
    </style>
</head>
<body>
<div class="login-box">
    <h2>Login</h2>
    @if ($errors->any())
        <div style="color:red;">{{ $errors->first('email') }}</div>
    @endif
    <form method="POST" action="{{ url('/login') }}">
        @csrf
        <input type="email" name="email" placeholder="Email" required />
        <input type="password" name="password" placeholder="Password" required />
        <button type="submit">Log In</button>
    </form>
</div>
</body>
</html>
