import { ReactJSXElement } from '@emotion/react/types/jsx-namespace';
import { Card, CardContent, InputLabel, List, ListItem, TextField } from '@mui/material';
import LockIcon from '@mui/icons-material/Lock';
import { OAuthCredentials, TestInput } from 'models/testSuiteModels';
import React, { FC, Fragment } from 'react';
import useStyles from './styles';

export interface InputOAuthCredentialsProps {
  requirement: TestInput;
  index: number;
  inputsMap: Map<string, string>;
  setInputsMap: (map: Map<string, string>) => void;
}

export interface InputOAuthField {
  name: string;
  label?: string | ReactJSXElement;
  required?: boolean;
}

const InputOAuthCredentials: FC<InputOAuthCredentialsProps> = ({
  requirement,
  index,
  inputsMap,
  setInputsMap,
}) => {
  const styles = useStyles();
  const fieldLabelText = `${requirement.title || requirement.name}`;
  const lockedIcon = requirement.locked ? (
    <LockIcon fontSize="small" className={styles.lockedIcon} />
  ) : null;
  const requiredLabel = !requirement.optional && !requirement.locked ? ' (required)' : '';
  const template = JSON.stringify({
    access_token: '',
    refresh_token: '',
    expires_in: '',
    client_id: '',
    client_secret: '',
    token_url: '',
  });
  const oAuthCredentials = JSON.parse(
    inputsMap.get(requirement.name) || template
  ) as OAuthCredentials;
  const showRefreshDetails = oAuthCredentials.refresh_token.length > 0;
  const fieldLabel = (
    <Fragment>
      {fieldLabelText}
      {requiredLabel}
      {lockedIcon}
    </Fragment>
  );

  const oAuthField = (field: InputOAuthField) => (
    <ListItem disabled={requirement.locked} key={field.name}>
      <TextField
        disabled={requirement.locked}
        required={field.required}
        id={`requirement${index}_${field.name}`}
        label={field.label || field.name}
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

  const refreshDetails = () => {
    const refreshFields: InputOAuthField[] = [
      { name: 'token_url', label: 'Token Endpoint (required)', required: showRefreshDetails },
      {
        name: 'expires_in',
        label: 'Expires in (seconds) (required)',
        required: showRefreshDetails,
      },
      { name: 'client_id', label: 'Client ID (required)', required: showRefreshDetails },
      { name: 'client_secret', label: 'Client Secret (required)', required: showRefreshDetails },
    ];
    return refreshFields.map((field) => oAuthField(field));
  };

  return (
    <ListItem>
      <Card variant="outlined" className={styles.oauthCard}>
        <CardContent>
          <InputLabel
            required={!requirement.optional && !requirement.locked}
            className={styles.inputLabel}
            shrink
          >
            {fieldLabel}
          </InputLabel>
          <List>
            {oAuthField({ name: 'access_token', label: 'Bearer Token (required)', required: true })}
            {oAuthField({
              name: 'refresh_token',
              label: 'Refresh Token (will automatically refresh if available)',
              required: false,
            })}
            {showRefreshDetails && refreshDetails()}
          </List>
        </CardContent>
      </Card>
    </ListItem>
  );
};

export default InputOAuthCredentials;
