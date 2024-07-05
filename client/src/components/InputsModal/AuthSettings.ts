import { TestInput } from '~/models/testSuiteModels';

export type AuthType = 'public' | 'symmetric' | 'asymmetric' | 'backend_services';

export const authSettings = {
  public: [
    'use_discovery',
    'client_id',
    'requested_scopes',
    'pkce_support',
    'pkce_code_challenge_method',
    'auth_request_method',
    'auth_url',
    'token_url',
  ],
  symmetric: [
    'use_discovery',
    'client_id',
    'client_secret',
    'requested_scopes',
    'pkce_support',
    'pkce_code_challenge_method',
    'auth_request_method',
    'auth_url',
    'token_url',
  ],
  asymmetric: [
    'use_discovery',
    'client_id',
    'requested_scopes',
    'pkce_support',
    'pkce_code_challenge_method',
    'auth_request_method',
    'encryption_algorithm',
    'jwks',
    'kid',
    'auth_url',
    'token_url',
  ],
  backend_services: [
    'use_discovery',
    'client_id',
    'requested_scopes',
    'pkce_support',
    'pkce_code_challenge_method',
    'auth_request_method',
    'encryption_algorithm',
    'jwks',
    'kid',
    'token_url',
  ],
};

export const getAuthFields = (
  authType: AuthType,
  requirement: TestInput,
  authValues: Map<string, unknown>
): TestInput[] => {
  const fields = [
    {
      name: 'use_discovery',
      type: 'checkbox',
      title: 'Populate fields from discovery',
      default: 'true',
    },
    {
      name: 'token_url',
      title: 'Token URL',
      description: "URL of the authorization server's token endpoint",
    },
    {
      name: 'auth_url',
      title: 'Authorization URL',
      description: "URL of the server's authorization endpoint",
      hide: requirement.value === 'public',
    },
    {
      name: 'requested_scopes',
      title: 'Scopes',
      description: 'OAuth 2.0 scopes needed to enable all required functionality',
    },
    {
      name: 'client_id',
      title: 'Client ID',
      description: 'Client ID provided during registration of Inferno',
    },
    {
      name: 'client_secret',
      title: 'Client Secret',
      description: 'Client secret provided during registration of Inferno',
    },
    {
      name: 'redirect_url',
      title: 'Redirect URL',
    },
    {
      name: 'pkce_support',
      type: 'radio',
      title: 'Proof Key for Code Exchange (PKCE)',
      options: {
        list_options: [
          {
            label: 'Enabled',
            value: 'enabled',
          },
          {
            label: 'Disabled',
            value: 'disabled',
          },
        ],
      },
    },
    {
      name: 'pkce_code_challenge_method',
      type: 'radio',
      title: 'PKCE Code Challenge Method',
      options: {
        list_options: [
          {
            label: 'S256',
            value: 's256',
          },
          {
            label: 'Plain',
            value: 'plain',
          },
        ],
      },
      hide: authValues ? !authValues.get('pkce_support') : false, // hide if pkce_support is disabled
    },
    {
      name: 'auth_request_method',
      type: 'radio',
      title: 'Authorization Request Method',
      options: {
        list_options: [
          {
            label: 'GET',
            value: 'get',
          },
          {
            label: 'POST',
            value: 'post',
          },
        ],
      },
    },
    {
      name: 'encryption_algorithm',
      type: 'radio',
      title: 'Encryption Algorithm',
      options: {
        list_options: [
          {
            label: 'ES384',
            value: 'es384',
          },
          {
            label: 'RS384',
            value: 'rs384',
          },
        ],
      },
    },
    {
      name: 'kid',
      title: 'Key ID (kid)',
      description:
        'Key ID of the JWKS private key used to sign the client assertion. If blank, the first key for the selected encryption algorithm will be used.',
    },
    {
      name: 'jwks',
      type: 'textarea',
      title: 'JWKS',
      description:
        "The JWKS (including private keys) which will be used to sign the client assertion. If blank, Inferno's default JWKS will be used.",
    },
    {
      name: 'access_token',
      title: 'Access Token',
    },
    {
      name: 'refresh_token',
      title: 'Refresh Token (will automatically refresh if available)',
    },
    {
      name: 'issue_time',
      title: 'Access Token Issue Time',
      description: 'The time that the access token was issued in iso8601 format',
    },
    {
      name: 'expires_in',
      title: 'Token Lifetime',
      description: 'The lifetime of the access token in seconds',
    },
  ] as TestInput[];
  if (authSettings && authType) {
    const typeValue = authSettings[authType];
    fields.forEach((field) => (field.hide = typeValue.includes(field.name)));
  }
  return fields;
};
