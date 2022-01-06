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
  required: boolean;
  label?: string | ReactJSXElement;
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
      { name: 'token_url', required: showRefreshDetails, label: 'Token Endpoint (required)' },
      {
        name: 'expires_in',
        required: showRefreshDetails,
        label: 'Expires in (seconds) (required)',
      },
      { name: 'client_id', required: showRefreshDetails, label: 'Client ID (required)' },
      { name: 'client_secret', required: showRefreshDetails, label: 'Client Secret (required)' },
    ];
    return refreshFields.map((field) => oAuthField(field));
  };

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
            {oAuthField({ name: 'access_token', required: true, label: 'Bearer Token (required)' })}
            {oAuthField({
              name: 'refresh_token',
              required: false,
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
