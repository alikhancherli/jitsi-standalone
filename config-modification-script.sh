#!/bin/bash

# Modify the jitsitest2.simorgh34000.com.cfg.lua to match stage-jitsi.simorgh34000.com.cfg.lua

echo "📝 Modifying Prosody config ..."

echo "Enter the app_id for jwt (or issuer) : "
read APPID

echo "Enter the app_secret for jwt (or secret key) : "
read APPSECRET

echo "Enter the api_prefix for jwt (it's for room events end-points. see more : https://github.com/jitsi-contrib/prosody-plugins/tree/main/event_sync) : "
read APIPREFIX

sudo tee /etc/prosody/conf.d/jitsitest2.simorgh34000.com.cfg.lua > /dev/null <<EOF
-- We need this for prosody 13.0
component_admins_as_room_owners = true

plugin_paths = { "/usr/share/jitsi-meet/prosody-plugins/" }

-- domain mapper options, must at least have domain base set to use the mapper
muc_mapper_domain_base = "${DOMAIN}";

external_service_secret = "IvwSV8Fwm382gJp9";
external_services = {
     { type = "stun", host = "${DOMAIN}", port = 3478 },
     { type = "turn", host = "${DOMAIN}", port = 3478, transport = "udp", secret = true, ttl = 86400, algorithm = "turn" },
     { type = "turns", host = "${DOMAIN}", port = 5349, transport = "tcp", secret = true, ttl = 86400, algorithm = "turn" }
};

cross_domain_bosh = false;
consider_bosh_secure = true;
-- https_ports = { }; -- Remove this line to prevent listening on port 5284

-- by default prosody 0.12 sends cors headers, if you want to disable it uncomment the following (the config is available on 0.12.1)
--http_cors_override = {
--    bosh = {
--        enabled = false;
--    };
--    websocket = {
--        enabled = false;
--    };
--}

-- https://ssl-config.mozilla.org/#server=haproxy&version=2.1&config=intermediate&openssl=1.1.0g&guideline=5.4
ssl = {
    protocol = "tlsv1_2+";
    ciphers = "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384"
}

unlimited_jids = {
    "focus@auth.${DOMAIN}",
    "jvb@auth.${DOMAIN}"
}

VirtualHost "${DOMAIN}"
    authentication = "token" -- do not delete me
    app_id = "${APPID}"

    app_secret = "${APPSECRET}"

    allow_empty_token = false

    enable_domain_verification = false
    --authentication = "jitsi-anonymous" -- do not delete me
    -- Properties below are modified by jitsi-meet-tokens package config
    -- and authentication above is switched to "token"
    --app_id="example_app_id"
    --app_secret="example_app_secret"
    -- Assign this host a certificate for TLS, otherwise it would use the one
    -- set in the global section (if any).
    -- Note that old-style SSL on port 5223 only supports one certificate, and will always
    -- use the global one.
    ssl = {
        key = "/etc/ssl/${DOMAIN}.key";
        certificate = "/etc/ssl/${DOMAIN}.crt";
    }
    av_moderation_component = "avmoderation.${DOMAIN}"
    speakerstats_component = "speakerstats.${DOMAIN}"
    end_conference_component = "endconference.${DOMAIN}"
    -- we need bosh
    modules_enabled = {
        "bosh";
        "ping"; -- Enable mod_ping
        "speakerstats";
        "external_services";
        "conference_duration";
        "end_conference";
        "muc_lobby_rooms";
        "muc_breakout_rooms";
        "av_moderation";
        "room_metadata";
        "persistent_lobby";

    }
    c2s_require_encryption = false
    lobby_muc = "lobby.${DOMAIN}"
    breakout_rooms_muc = "breakout.${DOMAIN}"
    room_metadata_component = "metadata.${DOMAIN}"
    main_muc = "conference.${DOMAIN}"
    -- muc_lobby_whitelist = { "recorder.${DOMAIN}" } -- Here we can whitelist jibri to enter lobby enabled rooms

Component "conference.${DOMAIN}" "muc"
    restrict_room_creation = true
    storage = "memory"
    modules_enabled = {
        "muc_hide_all";
        "muc_meeting_id";
        "muc_domain_mapper";
        "polls";
        "token_moderation";
        "token_affiliation";
        "token_security_ondemand";
        "token_lobby_bypass";
        "lobby_autostart";
        "event_sync_component";
        "token_verification";
        "muc_rate_limit";
        "muc_password_whitelist";
    }
    admins = { "focus@auth.${DOMAIN}" }
    muc_password_whitelist = {
        "focus@auth.${DOMAIN}"
    }
    muc_room_locking = false
    muc_room_default_public_jids = true


Component "esync.${DOMAIN}" "event_sync_component"
    muc_component = "conference.${DOMAIN}"
    api_prefix = "${APIPREFIX}"
    api_retry_count = 5
    api_retry_delay = 5
--    breakout_component = "breakout.${DOMAIN}"

Component "breakout.${DOMAIN}" "muc"
    restrict_room_creation = true
    storage = "memory"
    modules_enabled = {
        "muc_hide_all";
        "muc_meeting_id";
        "muc_domain_mapper";
        "muc_rate_limit";
        "polls";
    }
    admins = { "focus@auth.${DOMAIN}" }
    muc_room_locking = false
    muc_room_default_public_jids = true

-- internal muc component
Component "internal.auth.${DOMAIN}" "muc"
    storage = "memory"
    modules_enabled = {
        "muc_hide_all";
        "ping";
    }
    admins = { "focus@auth.${DOMAIN}", "jvb@auth.${DOMAIN}" }
    muc_room_locking = false
    muc_room_default_public_jids = true

VirtualHost "auth.${DOMAIN}"
    ssl = {
        key = "/etc/prosody/certs/auth.${DOMAIN}.key";
        certificate = "/etc/prosody/certs/auth.${DOMAIN}.crt";
    }
    modules_enabled = {
        "limits_exception";
        "smacks";
    }
    authentication = "internal_hashed"
    smacks_hibernation_time = 15;

-- Proxy to jicofo's user JID, so that it doesn't have to register as a component.
Component "focus.${DOMAIN}" "client_proxy"
    target_address = "focus@auth.${DOMAIN}"

Component "speakerstats.${DOMAIN}" "speakerstats_component"
    muc_component = "conference.${DOMAIN}"

Component "endconference.${DOMAIN}" "end_conference"
    muc_component = "conference.${DOMAIN}"

Component "avmoderation.${DOMAIN}" "av_moderation_component"
    muc_component = "conference.${DOMAIN}"

Component "lobby.${DOMAIN}" "muc"
    storage = "memory"
    restrict_room_creation = true
    muc_room_locking = false
    muc_room_default_public_jids = true
    modules_enabled = {
        "muc_hide_all";
        "muc_rate_limit";
        "polls";
    }

Component "metadata.${DOMAIN}" "room_metadata_component"
    muc_component = "conference.${DOMAIN}"
    breakout_rooms_component = "breakout.${DOMAIN}"
EOF
