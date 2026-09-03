function gcx-refresh-token --description 'Mint a new gcx service-account token if none are live with >1 day remaining'
    set -l aws_bin $HOME/.local/share/mise/shims/aws
    set -l aws_profile (test -n "$GRAFANA_AWS_PROFILE"; and echo $GRAFANA_AWS_PROFILE; or echo default)
    set -l aws_region (test -n "$GRAFANA_AWS_REGION"; and echo $GRAFANA_AWS_REGION; or echo us-east-2)
    set -l workspace_id (test -n "$GRAFANA_WORKSPACE_ID"; and echo $GRAFANA_WORKSPACE_ID; or echo g-d364abe43b)
    set -l sa_id (test -n "$GRAFANA_SERVICE_ACCOUNT_ID"; and echo $GRAFANA_SERVICE_ACCOUNT_ID; or echo 22)
    set -l min_seconds 86400  # require at least 1 day remaining
    set -l ttl_seconds 2592000  # 30 days

    # Check existing gcx-* tokens via Grafana API (no AWS call needed for probe)
    set -l tokens_json (gcx api "/api/serviceaccounts/$sa_id/tokens" 2>/dev/null)
    set -l now_epoch (date +%s)
    set -l cutoff (math $now_epoch + $min_seconds)

    if test -n "$tokens_json"
        # AMG doesn't populate secondsUntilExpiration; compute from expiration field instead
        set -l live (echo $tokens_json \
            | jq -r --argjson cutoff $cutoff \
              '.[] | select(.name | startswith("gcx-")) | select(.hasExpired == false) | select((.expiration | fromdateiso8601) > $cutoff) | .name' \
              2>/dev/null)
        if test -n "$live"
            echo "gcx token ok: $live"
            return 0
        end
    end

    # Need a new token — AWS session required from here
    if not $aws_bin sts get-caller-identity --profile $aws_profile --region $aws_region >/dev/null 2>&1
        echo "gcx-refresh-token: no valid AWS session for profile '$aws_profile'" >&2
        echo "  run: aws sso login --profile $aws_profile" >&2
        return 1
    end

    # Reap expired gcx-* tokens (best-effort, don't abort on failure)
    set -l expired_ids (echo $tokens_json \
        | jq -r '.[] | select(.name | startswith("gcx-")) | select(.hasExpired == true) | .id' 2>/dev/null)
    for tid in $expired_ids
        $aws_bin grafana delete-workspace-service-account-token \
            --profile $aws_profile --region $aws_region \
            --workspace-id $workspace_id \
            --service-account-id $sa_id \
            --token-id $tid >/dev/null 2>&1
            or echo "gcx-refresh-token: could not delete expired token $tid (continuing)" >&2
    end

    # Mint a fresh 30-day token
    set -l token_name gcx-(date +%s)
    set -l new_token ($aws_bin grafana create-workspace-service-account-token \
        --profile $aws_profile --region $aws_region \
        --workspace-id $workspace_id \
        --service-account-id $sa_id \
        --name $token_name \
        --seconds-to-live $ttl_seconds \
        --query 'serviceAccountToken.key' \
        --output text 2>&1)

    if test $status -ne 0; or test -z "$new_token"; or test "$new_token" = None
        echo "gcx-refresh-token: failed to mint token" >&2
        return 1
    end

    gcx config set stacks.amg.grafana.token $new_token >/dev/null
    echo "gcx token refreshed: $token_name (ttl 30d)"
end
