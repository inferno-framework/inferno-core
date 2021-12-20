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
      'access_token': '',
      'refresh_token': '',
      'expires_in': '',
      'client_id': '',
      'client_secret': '',
      'token_url': ''
    });
  const oauthCredentials = JSON.parse(inputsMap.get(requirement.name) || template);
  const showRefreshDetails = oauthCredentials['refresh_token'].length;
  const fieldLabel = (
    <Fragment>
      {fieldLabelText}
      {requiredLabel}
      {lockedIcon}
    </Fragment>
  );

  const refreshDetails = (
    <>
      <ListItem disabled={requirement.locked}>
        <TextField
          disabled={requirement.locked}
          id={`requirement${index}_token_url`}
          className={styles.inputField}
          fullWidth
          label='Token Endpoint'
          helperText={requirement.description}
          value={oauthCredentials['token_url']}
          onChange={(event) => {
            const value = event.target.value;
            inputsMap.set(requirement.name, value);
            oauthCredentials['token_url'] = value;
            inputsMap.set(requirement.name, JSON.stringify(oauthCredentials));
            setInputsMap(new Map(inputsMap));
          } }
          InputLabelProps={{ shrink: true }} />
          </ListItem>
      <ListItem disabled={requirement.locked}>
        <TextField
          disabled={requirement.locked}
          id={`requirement${index}_expires_in`}
          className={styles.inputField}
          fullWidth
          label='Expires in (seconds)'
          helperText={requirement.description}
          value={oauthCredentials['expires_in']}
          onChange={(event) => {
            const value = event.target.value;
            oauthCredentials['expires_in'] = value;
            inputsMap.set(requirement.name, JSON.stringify(oauthCredentials));
            setInputsMap(new Map(inputsMap));
          } }
          InputLabelProps={{ shrink: true }} />
          </ListItem>
      <ListItem disabled={requirement.locked}>
        <TextField
          disabled={requirement.locked}
          id={`requirement${index}_client_id`}
          className={styles.inputField}
          fullWidth
          label='Client ID'
          helperText={requirement.description}
          value={oauthCredentials['client_id']}
          onChange={(event) => {
            const value = event.target.value;
            oauthCredentials['client_id'] = value;
            inputsMap.set(requirement.name, JSON.stringify(oauthCredentials));
            setInputsMap(new Map(inputsMap));
          } }
          InputLabelProps={{ shrink: true }} />
          </ListItem>
      <ListItem disabled={requirement.locked}>
        <TextField
          disabled={requirement.locked}
          id={`requirement${index}_client_secret`}
          className={styles.inputField}
          fullWidth
          label='Client Secret'
          helperText={requirement.description}
          value={oauthCredentials['client_secret']}
          onChange={(event) => {
            const value = event.target.value;
            oauthCredentials['client_secret'] = value;
            inputsMap.set(requirement.name, JSON.stringify(oauthCredentials));
            setInputsMap(new Map(inputsMap));
          } }
          InputLabelProps={{ shrink: true }} />
          </ListItem>
          </>
  )

  return (
    <><ListItem disabled={requirement.locked}>
      <TextField
        disabled={requirement.locked}
        id={`requirement${index}_input`}
        className={styles.inputField}
        fullWidth
        label={fieldLabel}
        helperText={requirement.description}
        value={oauthCredentials['access_token']}
        onChange={(event) => {
          const value = event.target.value;
          oauthCredentials['access_token'] = value;
          inputsMap.set(requirement.name, JSON.stringify(oauthCredentials));
          setInputsMap(new Map(inputsMap));
        } }
        InputLabelProps={{ shrink: true }} />
    </ListItem><ListItem disabled={requirement.locked}>
        <TextField
          disabled={requirement.locked}
          id={`requirement${index}_refresh`}
          className={styles.inputField}
          fullWidth
          label='Refresh Token (token will automatically refresh if available)'
          helperText={requirement.description}
          value={oauthCredentials['refresh_token']}
          onChange={(event) => {
            const value = event.target.value;
            oauthCredentials['refresh_token'] = value;
            inputsMap.set(requirement.name, JSON.stringify(oauthCredentials));
            setInputsMap(new Map(inputsMap));
          } }
          InputLabelProps={{ shrink: true }} />
      </ListItem>
      {showRefreshDetails ? refreshDetails : ''}
      </>
  );
};

export default InputOAuthCredentials;
