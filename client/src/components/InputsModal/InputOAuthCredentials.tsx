import { ReactJSXElement } from '@emotion/react/types/jsx-namespace';
import { Card, CardContent, InputLabel, List, ListItem, TextField } from '@mui/material';
import LockIcon from '@mui/icons-material/Lock';
import { TestInput } from 'models/testSuiteModels';
import React, { FC, Fragment } from 'react';
import useStyles from './styles';

export interface InputOAuthCredentialsProps {
  requirement: TestInput;
  index: number;
  inputsMap: Map<string, string>;
  setInputsMap: (map: Map<string, string>) => void;
}

// Necessary to prevent "implicit any" errors when indexing objects of type InputOAuthCredentials
export interface InputOAuthCredentialsType {
  [key: string]: string;
}

export interface InputOAuthCredentials extends InputOAuthCredentialsType {
  access_token: string;
  refresh_token: string;
  expires_in: string;
  client_id: string;
  client_secret: string;
  token_url: string;
}

export interface InputOAuthField {
  name: string;
  label?: string | ReactJSXElement;
}

const InputOAuthCredentials: FC<InputOAuthCredentialsProps> = ({
  requirement,
  index,
  inputsMap,
  setInputsMap,
}) => {
  const styles = useStyles();
  const fieldLabelText = `${requirement.title || requirement.name} Bearer Token`;
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
  ) as InputOAuthCredentials;
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
      { name: 'token_url', label: 'Token Endpoint' },
      { name: 'expires_in', label: 'Expires in (seconds)' },
      { name: 'client_id', label: 'Client ID' },
      { name: 'client_secret', label: 'Client Secret' },
    ];
    return refreshFields.map((field) => oAuthField(field));
  };

  console.log(showRefreshDetails);
  return (
    <ListItem>
      <Card
        variant="outlined"
        sx={{ width: '100%', margin: '8px 0', borderColor: 'rgba(0,0,0,0.3)' }}
      >
        <CardContent>
          <InputLabel
            required={!requirement.optional && !requirement.locked}
            className={styles.inputLabel}
            shrink
          >
            {fieldLabel}
          </InputLabel>
          <List>
            {oAuthField({ name: 'access_token', label: 'Bearer Token' })}
            {oAuthField({
              name: 'refresh_token',
              label: 'Refresh Token (token will automatically refresh if available)',
            })}
            {showRefreshDetails && refreshDetails()}
          </List>
        </CardContent>
      </Card>
    </ListItem>
  );
};

export default InputOAuthCredentials;
