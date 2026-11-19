<?php

namespace App\Services;

use Google\Client;

class GoogleTokenVerifier
{
    /** @return array<string, mixed>|null */
    public function verify(string $idToken, string $clientId): ?array
    {
        $client = new Client(['client_id' => $clientId]);
        $payload = $client->verifyIdToken($idToken);

        return is_array($payload) ? $payload : null;
    }
}
