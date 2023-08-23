import React, { FC } from 'react';
import { ReactJSXElement } from '@emotion/react/types/jsx-namespace';
import {
  Card,
  CardContent,
  FormHelperText,
  InputLabel,
  List,
  ListItem,
  TextField,
} from '@mui/material';
import { OAuthCredentials, TestInput } from '~/models/testSuiteModels';
import FieldLabel from './FieldLabel';
import useStyles from './styles';

export interface InputOAuthCredentialsProps {
  requirement: TestInput;
  index: number;
  inputsMap: Map<string, unknown>;
  setInputsMap: (map: Map<string, unknown>, edited?: boolean) => void;
}

export interface InputOAuthField {
  name: string;
  label?: string | ReactJSXElement;
  required?: boolean; // default behavior should be false
  hide?: boolean; // default behavior should be false
  locked?: boolean; // default behavior should be false
}

const InputOAuthCredentials: FC<InputOAuthCredentialsProps> = ({
  requirement,
  index,
  inputsMap,
  setInputsMap,
}) => {
  const { classes } = useStyles();
  const [hasBeenModified, setHasBeenModified] = React.useState({});

  // Convert OAuth string to Object
  // OAuth should be an Object while in this component but should be converted to a string
  // before being updated in the inputs map
  const oAuthCredentials = (
    inputsMap.get(requirement.name)
      ? JSON.parse(inputsMap.get(requirement.name) as string)
      : {
          access_token: '',
          refresh_token: '',
          expires_in: '',
          client_id: '',
          client_secret: '',
          token_url: '',
        }
  ) as OAuthCredentials;

  const showRefreshDetails = !!oAuthCredentials.refresh_token;

  const oAuthFields: InputOAuthField[] = [
    {
      name: 'access_token',
      label: 'Access Token',
      required: !requirement.optional,
    },
    {
      name: 'refresh_token',
      label: 'Refresh Token (will automatically refresh if available)',
      required: false,
    },
    {
      name: 'token_url',
      label: 'Token Endpoint',
      hide: !showRefreshDetails,
      required: true,
    },
    {
      name: 'client_id',
      label: 'Client ID',
      hide: !showRefreshDetails,
      required: true,
    },
    {
      name: 'client_secret',
      label: 'Client Secret',
      hide: !showRefreshDetails,
      required: false,
    },
    {
      name: 'expires_in',
      label: 'Expires in (seconds)',
      hide: !showRefreshDetails,
      required: false,
    },
  ];

  const oAuthField = (field: InputOAuthField) => {
    const fieldLabel = field.required
      ? `${(field.label || field.name) as string} (required)`
      : field.label || field.name;
    return (
      <ListItem disabled={field.locked} key={field.name}>
        <TextField
          disabled={requirement.locked}
          required={field.required}
          error={
            hasBeenModified[field.name as keyof typeof hasBeenModified] &&
            field.required &&
            !oAuthCredentials[field.name as keyof OAuthCredentials]
          }
          id={`requirement${index}_${field.name}`}
          label={fieldLabel}
          helperText={requirement.description}
          value={oAuthCredentials[field.name as keyof OAuthCredentials]}
          className={classes.inputField}
          variant="standard"
          fullWidth
          onBlur={(e) => {
            if (e.currentTarget === e.target) {
              setHasBeenModified({ ...hasBeenModified, [field.name]: true });
            }
          }}
          onChange={(event) => {
            const value = event.target.value;
            oAuthCredentials[field.name as keyof OAuthCredentials] = value;
            inputsMap.set(requirement.name, JSON.stringify(oAuthCredentials));
            setInputsMap(new Map(inputsMap));
          }}
          InputLabelProps={{ shrink: true }}
        />
      </ListItem>
    );
  };

  return (
    <ListItem>
      <Card variant="outlined" className={classes.oauthCard}>
        <CardContent>
          <InputLabel
            required={!requirement.optional}
            disabled={requirement.locked}
            className={classes.inputLabel}
            shrink
          >
            <FieldLabel requirement={requirement} />
          </InputLabel>
          {requirement.description && (
            <FormHelperText sx={{ mx: 0 }}>{requirement.description}</FormHelperText>
          )}
          <List>{oAuthFields.map((field) => !field.hide && oAuthField(field))}</List>
        </CardContent>
      </Card>
    </ListItem>
  );
};

export default InputOAuthCredentials;
