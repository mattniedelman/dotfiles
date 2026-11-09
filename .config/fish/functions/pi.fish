function pi --description 'Run Pi with Bedrock via refreshing SSO credential process'
    # Scope the refreshing AWS SSO profile to Pi without changing the shell default.
    AWS_PROFILE=claude AWS_SDK_LOAD_CONFIG=1 command pi $argv
end
