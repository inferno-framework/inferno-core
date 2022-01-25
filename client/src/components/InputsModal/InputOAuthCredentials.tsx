import { ReactJSXElement } from '@emotion/react/types/jsx-namespace';
import { Card, CardContent, InputLabel, List, ListItem, TextField } from '@mui/material';
import LockIcon from '@mui/icons-material/Lock';
import { OAuthCredentials, TestInput } from 'models/testSuiteModels';
import React, { FC, Fragment } from 'react';
import useStyles from './styles';

export interface InputOAuthCredentialsProps {
  requirement: TestInput;
  index: number;
  inputsMap: Map<string, unknown>;
  setInputsMap: (map: Map<string, unknown>) => void;
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
  const styles = useStyles();
  const template = {
    access_token: '',
    refresh_token: '',
    expires_in: '',
    client_id: '',
    client_secret: '',
    token_url: '',
  };
  const oAuthCredentials = (
    inputsMap.get(requirement.name)
      ? JSON.parse(inputsMap.get(requirement.name) as string)
      : template
  ) as OAuthCredentials;
  const showRefreshDetails = !!oAuthCredentials.refresh_token;

  const fieldLabelText = `${requirement.title || requirement.name}`;
  const requiredLabel = !requirement.optional && !requirement.locked ? ' (required)' : '';
  const lockedIcon = requirement.locked ? (
    <LockIcon fontSize="small" className={styles.lockedIcon} />
  ) : null;
  const fieldLabel = (
    <Fragment>
      {fieldLabelText}
      {requiredLabel}
      {lockedIcon}
    </Fragment>
  );

  const oAuthFields: InputOAuthField[] = [
    {
      name: 'access_token',
      label: 'Access Token',
      required: !requirement.optional && !requirement.locked,
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
          disabled={field.locked}
          required={field.required}
          id={`requirement${index}_${field.name}`}
          label={fieldLabel}
          helperText={requirement.description}
          value={oAuthCredentials[field.name]}
          className={styles.inputField}
          variant="standard"
          fullWidth
          onChange={(event) => {
            const value = event.target.value;
            inputsMap.set(requirement.name, value);
            oAuthCredentials[field.name] = value;
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
      <Card variant="outlined" className={styles.oauthCard}>
        <CardContent>
          <InputLabel
            required={!requirement.optional && !requirement.locked}
            disabled={requirement.locked}
            className={styles.inputLabel}
            shrink
          >
            {fieldLabel}
          </InputLabel>
          <List>{oAuthFields.map((field) => !field.hide && oAuthField(field))}</List>
        </CardContent>
      </Card>
    </ListItem>
  );
};

export default InputOAuthCredentials;
