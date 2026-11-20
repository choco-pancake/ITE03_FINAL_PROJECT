# GroupMeMaybe frontend

Flutter web client for the GroupMeMaybe Laravel API.

## Run locally

1. Start the Laravel backend from `../backend`:

   ```powershell
   php artisan serve --host=127.0.0.1 --port=8000
   ```

2. Confirm the API responds at <http://127.0.0.1:8000/api/profiles>.

3. Restore packages and start the frontend:

   ```powershell
   flutter pub get
   flutter run -d chrome
   ```

## Google sign-in setup

Create a Google OAuth **Web application** client in Google Cloud. Add
`http://localhost:63834` to its Authorized JavaScript origins and configure
the consent screen for the accounts you want to test. Use the same client ID
on the Laravel server and in the Flutter web build:

1. Set `GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com` in
   `../backend/.env`, then run `php artisan config:clear` and `php artisan migrate`
   from the backend directory.
2. Start the frontend on the registered origin:

   ```powershell
   flutter run -d chrome --web-hostname localhost --web-port 63834 --dart-define=GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com
   ```

The Google button reports a configuration message until the client ID is set.
Either Google button opens Google's account picker. A new Google account is
created as a student; an existing account keeps its current role.

## Local shader rendering

The web bootstrap uses CPU-only CanvasKit on `localhost` and `127.0.0.1` to
avoid Chrome WebGL shader compilation failures during local testing. The run
commands above still work, including the Google sign-in origin on port 63834.
Other hosts use Flutter's normal renderer configuration.

## Browser crash recovery

If Chrome displays "Something went wrong while displaying this webpage":

1. Stop the current Flutter run with `q` in its terminal.
2. Start a standalone development server:

   ```powershell
   flutter run -d web-server --web-hostname 127.0.0.1 --web-port 63834
   ```

3. Open <http://127.0.0.1:63834> in a normal Chrome or Edge window.

If the standalone server works, the failure is isolated to Flutter's temporary
Chrome profile. If Chrome still crashes, try Edge with `flutter run -d edge` or
use Chrome's `--disable-gpu` flag temporarily while updating the browser or GPU
driver.

## Checks

```powershell
flutter analyze
flutter test
flutter build web
```
