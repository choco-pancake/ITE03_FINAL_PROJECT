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
