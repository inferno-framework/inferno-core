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
    'encryption_algorithm',
    'jwks',
    'kid',
    'token_url',
  ],
};

export const getAuthFields = (
  authType: AuthType,
  authValues: Map<string, unknown>,
  components: TestInput[],
  lockedInput: boolean,
): TestInput[] => {
  const fields = [
    {
      name: 'use_discovery',
      type: 'checkbox',
      title: 'Populate fields from discovery',
      optional: true,
      locked: lockedInput,
      default: 'true',
    },
    {
      name: 'auth_url',
      title: 'Authorization URL',
      description: "URL of the server's authorization endpoint",
      optional: true,
      locked: lockedInput,
      hide: authValues?.get('use_discovery') === 'true',
    },
    {
      name: 'token_url',
      title: 'Token URL',
      description: "URL of the authorization server's token endpoint",
      optional: true,
      locked: lockedInput,
      hide: authValues?.get('use_discovery') === 'true',
    },
    {
      name: 'requested_scopes',
      type: 'textarea',
      title: 'Scopes',
      description: 'OAuth 2.0 scopes needed to enable all required functionality',
      locked: lockedInput,
    },
    {
      name: 'client_id',
      title: 'Client ID',
      description: 'Client ID provided during registration of Inferno',
      locked: lockedInput,
    },
    {
      name: 'client_secret',
      title: 'Client Secret',
      description: 'Client secret provided during registration of Inferno',
      locked: lockedInput,
    },
    {
      name: 'pkce_support',
      type: 'radio',
      title: 'Proof Key for Code Exchange (PKCE)',
      locked: lockedInput,
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
      optional: true,
      locked: lockedInput,
      options: {
        list_options: [
          {
            label: 'S256',
            value: 'S256',
          },
          {
            label: 'Plain',
            value: 'plain',
          },
        ],
      },
      hide: authValues ? authValues.get('pkce_support') === 'disabled' : false,
    },
    {
      name: 'auth_request_method',
      type: 'radio',
      title: 'Authorization Request Method',
      locked: lockedInput,
      options: {
        list_options: [
          {
            label: 'GET',
            value: 'GET',
          },
          {
            label: 'POST',
            value: 'POST',
          },
        ],
      },
    },
    {
      name: 'encryption_algorithm',
      type: 'radio',
      title: 'Encryption Algorithm',
      locked: lockedInput,
      options: {
        list_options: [
          {
            label: 'ES384',
            value: 'ES384',
          },
          {
            label: 'RS384',
            value: 'RS384',
          },
        ],
      },
    },
    {
      name: 'kid',
      title: 'Key ID (kid)',
      description:
        'Key ID of the JWKS private key used to sign the client assertion. If blank, the first key for the selected encryption algorithm will be used.',
      optional: true,
      locked: lockedInput,
    },
    {
      name: 'jwks',
      type: 'textarea',
      title: 'JWKS',
      description:
        "The JWKS (including private keys) which will be used to sign the client assertion. If blank, Inferno's default JWKS will be used.",
      optional: true,
      locked: lockedInput,
    },
  ] as TestInput[];

  // If the input contains custom fields, replace default fields
  const fieldsToUpdate = components.map((component) => component.name);
  fields.forEach((field, i) => {
    if (fieldsToUpdate.includes(field.name)) {
      const customComponent = components.find((component) => component.name === field.name);
      fields[i] = { ...field, ...customComponent };
    }
  });

  // Remove extra properties based on auth type or hide if no settings
  const typeValues = authSettings[authType];
  if (authSettings && authType) {
    return fields.filter((field) => typeValues.includes(field.name));
  }
  fields.forEach((field) => (field.hide = field.hide || !typeValues.includes(field.name)));
  return fields;
};

export const accessSettings = {
  public: ['access_token', 'refresh_token', 'client_id', 'token_url', 'issue_time', 'expires_in'],
  symmetric: [
    'access_token',
    'refresh_token',
    'client_id',
    'client_secret',
    'token_url',
    'issue_time',
    'expires_in',
  ],
  asymmetric: [
    'access_token',
    'refresh_token',
    'client_id',
    'token_url',
    'encryption_algorithm',
    'jwks',
    'kid',
    'issue_time',
    'expires_in',
  ],
  backend_services: [
    'access_token',
    'client_id',
    'token_url',
    'encryption_algorithm',
    'jwks',
    'kid',
    'issue_time',
    'expires_in',
  ],
};

export const getAccessFields = (
  authType: AuthType,
  accessValues: Map<string, unknown>,
  components: TestInput[],
  lockedInput: boolean,
): TestInput[] => {
  const tokenDoesNotExist =
    authType === 'backend_services'
      ? !accessValues.get('access_token')
      : !accessValues.get('refresh_token');

  const fields = [
    {
      name: 'access_token',
      title: 'Access Token',
      locked: lockedInput,
    },
    {
      name: 'refresh_token',
      title: 'Refresh Token (will automatically refresh if available)',
      optional: true,
      locked: lockedInput,
    },
    {
      name: 'client_id',
      title: 'Client ID',
      description: 'Client ID provided during registration of Inferno',
      optional: true,
      locked: lockedInput,
      hide: tokenDoesNotExist,
    },
    {
      name: 'client_secret',
      title: 'Client Secret',
      description: 'Client secret provided during registration of Inferno',
      optional: true,
      locked: lockedInput,
      hide: !accessValues.get('refresh_token'),
    },
    {
      name: 'token_url',
      title: 'Token URL',
      description: "URL of the authorization server's token endpoint",
      optional: true,
      locked: lockedInput,
      hide: tokenDoesNotExist,
    },
    {
      name: 'encryption_algorithm',
      type: 'radio',
      title: 'Encryption Algorithm',
      optional: true,
      locked: lockedInput,
      hide: tokenDoesNotExist,
    },
    {
      name: 'kid',
      title: 'Key ID (kid)',
      description:
        'Key ID of the JWKS private key used to sign the client assertion. If blank, the first key for the selected encryption algorithm will be used.',
      optional: true,
      locked: lockedInput,
      options: {
        list_options: [
          {
            label: 'ES384',
            value: 'ES384',
          },
          {
            label: 'RS384',
            value: 'RS384',
          },
        ],
      },
      hide: tokenDoesNotExist,
    },
    {
      name: 'jwks',
      type: 'textarea',
      title: 'JWKS',
      description:
        "The JWKS (including private keys) which will be used to sign the client assertion. If blank, Inferno's default JWKS will be used.",
      optional: true,
      locked: lockedInput,
      hide: tokenDoesNotExist,
    },
    {
      name: 'issue_time',
      title: 'Access Token Issue Time',
      description: 'The time that the access token was issued in iso8601 format',
      optional: true,
      locked: lockedInput,
      hide: tokenDoesNotExist,
    },
    {
      name: 'expires_in',
      title: 'Token Lifetime',
      description: 'The lifetime of the access token in seconds',
      optional: true,
      locked: lockedInput,
      hide: tokenDoesNotExist,
    },
  ] as TestInput[];

  // If the input contains custom fields, replace default fields
  const fieldsToUpdate = components.map((component) => component.name);
  fields.forEach((field, i) => {
    if (fieldsToUpdate.includes(field.name)) {
      const customComponent = components.find((component) => component.name === field.name);
      fields[i] = { ...field, ...customComponent };
    }
  });

  // Remove extra properties based on auth type or hide if no settings
  const typeValues = accessSettings[authType];
  if (accessSettings && authType) {
    return fields.filter((field) => typeValues.includes(field.name));
  }
  fields.forEach((field) => (field.hide = field.hide || !typeValues.includes(field.name)));
  return fields;
};
