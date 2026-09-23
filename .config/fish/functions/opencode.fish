function opencode --description 'Run opencode with the claude AWS profile (Bedrock)'
    # opencode uses AWS Bedrock with the same credentials as Claude Code.
    # The 'claude' profile is not the shell default, so scope it to this
    # command only. Run `aws sso login --profile claude` if the token expired.
    AWS_PROFILE=claude AWS_REGION=us-east-1 AWS_SDK_LOAD_CONFIG=1 command opencode $argv
end
