import React, { FC } from 'react';
import { ReactJSXElement } from '@emotion/react/types/jsx-namespace';
import {
  Card,
  CardContent,
  // FormControl,
  // FormLabel,
  // Input,
  InputLabel,
  ListItem,
  Typography,
} from '@mui/material';
import { /* Auth, */ InputValues, TestInput } from '~/models/testSuiteModels';
import FieldLabel from './FieldLabel';
import InputFields from './InputFields';
// import RequiredInputWarning from './RequiredInputWarning';
import useStyles from './styles';

export interface InputAuthProps {
  requirement: TestInput;
  index: number;
  inputsMap: Map<string, unknown>;
  setInputsMap: (map: Map<string, unknown>, edited?: boolean) => void;
}

export interface InputAuthField extends TestInput {
  label?: string | ReactJSXElement;
  required?: boolean; // default behavior should be false
  hide?: boolean; // default behavior should be false
  locked?: boolean; // default behavior should be false
}

const InputAuth: FC<InputAuthProps> = ({ requirement, /* index, */ inputsMap, setInputsMap }) => {
  const { classes } = useStyles();
  // const [authValues, setAuthValues] = React.useState({});
  // const [hasBeenModified, setHasBeenModified] = React.useState({});

  // Convert auth string to Object
  // Auth should be an Object while in this component but should be converted to a string
  // before being updated in the inputs map
  // const authBody = {
  //   auth_type: '',
  //   use_discovery: true,
  //   token_url: '',
  //   auth_url: '',
  //   requested_scopes: '',
  //   client_id: '',
  //   client_secret: '',
  //   redirect_url: '',
  //   pkce_support: 'enabled',
  //   pkce_code_challenge_method: 's256',
  //   auth_request_method: 'get',
  //   encryption_algorithm: 'es384',
  //   kid: '',
  //   jwks: '',
  //   access_token: '',
  //   refresh_token: '',
  //   issue_time: '',
  //   expires_in: '',
  //   ...JSON.parse((inputsMap.get(requirement.name) as string) || '{}'),
  // } as Auth;

  // const showRefreshDetails = !!authBody.refresh_token;

  console.log(JSON.parse(requirement.value as string));

  const values = JSON.parse(requirement.value as string) as InputValues;

  //   name: string;
  //   title?: string;
  //   value?: unknown;
  //   type?: 'auth_info' | 'oauth_credentials' | 'checkbox' | 'radio' | 'text' | 'textarea';
  //   description?: string;
  //   default?: string | string[];
  //   optional?: boolean;
  //   locked?: boolean;
  //   options?: {
  //     components?: TestInput[];
  //     list_options?: InputOption[];
  //     mode?: string;
  //   };

  const authFields: TestInput[] = [
    {
      name: 'auth_type',
      type: 'select',
      title: 'Auth Type',
      options: {
        list_options: [
          {
            label: 'Public',
            value: 'public',
          },
          {
            label: 'Confidential Symmetric',
            value: 'symmetric',
          },
          {
            label: 'Confidential Asymmetric',
            value: 'asymmetric',
          },
          {
            label: 'Backend Services',
            value: 'backend_services',
          },
        ],
      },
      // default: 'public',
    },
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
      // hide: 'if pkce_support is disabled',
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
      // required: !requirement.optional,
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
  ];
  // .map((field) => ({ ...field, value: values[field.name] }));

  // const getIsMissingInput = (field: InputAuthField) => {
  //   return (
  //     hasBeenModified[field.name as keyof typeof hasBeenModified] &&
  //     field.required &&
  //     !authBody[field.name as keyof Auth]
  //   );
  // };

  // const authField = (field: InputAuthField) => {
  //   const fieldName = field.required
  //     ? `${(field.label || field.name) as string} (required)`
  //     : field.label || field.name;

  //   const fieldLabel = (
  //     <>
  //       {getIsMissingInput(field) && <RequiredInputWarning />}
  //       {fieldName}
  //     </>
  //   );

  //   return (
  //     <ListItem disabled={field.locked} key={field.name}>
  //       <FormControl
  //         component="fieldset"
  //         id={`requirement${index}_input`}
  //         disabled={requirement.locked}
  //         required={!requirement.optional}
  //         error={getIsMissingInput(field)}
  //         fullWidth
  //         className={classes.inputField}
  //       >
  //         <FormLabel htmlFor={`requirement${index}_${field.name}`} className={classes.inputLabel}>
  //           {fieldLabel}
  //         </FormLabel>
  //         {field.description && (
  //           <Typography variant="subtitle1" className={classes.inputDescription}>
  //             {field.description}
  //           </Typography>
  //         )}
  //         <Input
  //           disabled={requirement.locked}
  //           required={field.required}
  //           error={getIsMissingInput(field)}
  //           id={`requirement${index}_${field.name}`}
  //           value={authBody[field.name as keyof Auth]}
  //           className={classes.inputField}
  //           color="secondary"
  //           fullWidth
  //           onBlur={(e) => {
  //             if (e.currentTarget === e.target) {
  //               setHasBeenModified({ ...hasBeenModified, [field.name]: true });
  //             }
  //           }}
  //           onChange={(event) => {
  //             const value = event.target.value;
  //             authBody[field.name as keyof Auth] = value;
  //             inputsMap.set(requirement.name, JSON.stringify(authBody));
  //             setInputsMap(new Map(inputsMap));
  //           }}
  //         />
  //       </FormControl>
  //     </ListItem>
  //   );
  // };

  return (
    <ListItem>
      <Card variant="outlined" className={classes.authCard}>
        <CardContent>
          <InputLabel
            required={!requirement.optional}
            disabled={requirement.locked}
            className={classes.inputLabel}
          >
            <FieldLabel requirement={requirement} />
          </InputLabel>
          {requirement.description && (
            <Typography variant="subtitle1" className={classes.inputDescription}>
              {requirement.description}
            </Typography>
          )}
          {/* {authFields.map((field) => !field.hide && authField(field))} */}
          <InputFields inputs={authFields} inputsMap={inputsMap} setInputsMap={setInputsMap} />
        </CardContent>
      </Card>
    </ListItem>
  );
};

export default InputAuth;
