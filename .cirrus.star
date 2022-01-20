load("cirrus", "env")

def main():
    additional_env = {}

    if env.get('CIRRUS_BRANCH') == 'main':
        additional_env['BRANCH_TYPE'] = 'main'
        additional_env['GCP_PROJECT'] = '${GCP_PROJECT_MAIN}'
    else:
        additional_env['BRANCH_TYPE'] = 'dev'
        additional_env['GCP_PROJECT'] = '${GCP_PROJECT_DEV}'

    additional_env['GCP_REGION'] = 'us'
    additional_env['GCP_REPO'] = '${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT}/ci'

    return [
      ('env', additional_env),
    ]
