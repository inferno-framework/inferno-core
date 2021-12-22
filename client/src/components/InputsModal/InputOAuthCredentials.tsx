import { ReactJSXElement } from '@emotion/react/types/jsx-namespace';
import { ListItem, TextField } from '@material-ui/core';
import LockIcon from '@material-ui/icons/Lock';
import { TestInput } from 'models/testSuiteModels';
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
}

export interface InputOAuthCredentials {
  access_token: string;
  refresh_token: string;
  expires_in: string;
  client_id: string;
  client_secret: string;
  token_url: string;
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
  const showRefreshDetails = oAuthCredentials['refresh_token'].length > 0;
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
        className={styles.inputField}
        fullWidth
        label={field.label || field.name}
        helperText={requirement.description}
        value={oAuthCredentials[field.name]}
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
    <>
      {oAuthField({ name: 'access_token', label: fieldLabel })}
      {oAuthField({
        name: 'refresh_token',
        label: 'Refresh Token (token will automatically refresh if available)',
      })}
      {showRefreshDetails && refreshDetails()}
    </>
  );
};

export default InputOAuthCredentials;
