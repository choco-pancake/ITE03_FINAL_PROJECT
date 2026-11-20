<?php

namespace App\Services;

use Google\Client;
use GuzzleHttp\Client as HttpClient;

class GoogleTokenVerifier
{
    /** @return array<string, mixed>|null */
    public function verify(string $idToken, string $clientId): ?array
    {
        $client = new Client(['client_id' => $clientId]);
        $caBundle = config('services.google.ca_bundle');
        $client->setHttpClient(new HttpClient([
            'connect_timeout' => 5,
            'timeout' => 10,
            'verify' => is_string($caBundle) && $caBundle !== '' ? $caBundle : true,
        ]));
        $payload = $client->verifyIdToken($idToken);

        return is_array($payload) ? $payload : null;
    }
}
