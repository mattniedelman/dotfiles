function omp --description 'Run omp with Bedrock via refreshing SSO credential process'
    # Uses the 'omp' AWS profile, which has only credential_process set.
    # aws-sso-credential-process silently refreshes the SSO access token via
    # the stored refresh token when it expires — no browser prompt, works for
    # long sessions. OMP re-invokes the process each time its in-process cache
    # expires (~1h), so the session never breaks.
    AWS_PROFILE=omp AWS_SDK_LOAD_CONFIG=1 command omp $argv
end
