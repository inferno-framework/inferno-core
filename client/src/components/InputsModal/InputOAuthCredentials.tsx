import React, { FC } from 'react';
import { ReactJSXElement } from '@emotion/react/types/jsx-namespace';
import {
  Card,
  CardContent,
  FormControl,
  FormLabel,
  Input,
  InputLabel,
  List,
  ListItem,
  Typography,
} from '@mui/material';
import { OAuthCredentials, TestInput } from '~/models/testSuiteModels';
import FieldLabel from './FieldLabel';
import useStyles from './styles';
import RequiredInputWarning from './RequiredInputWarning';

export interface InputOAuthCredentialsProps {
  requirement: TestInput;
  index: number;
  inputsMap: Map<string, unknown>;
  setInputsMap: (map: Map<string, unknown>, edited?: boolean) => void;
}

export interface InputOAuthField {
  name: string;
  label?: string | ReactJSXElement;
  description?: string; // currently empty
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
  const oAuthCredentials = {
    access_token: '',
    refresh_token: '',
    expires_in: '',
    client_id: '',
    client_secret: '',
    token_url: '',
    ...JSON.parse((inputsMap.get(requirement.name) as string) || '{}'),
  } as OAuthCredentials;

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

  const getIsMissingInput = (field: InputOAuthField) => {
    return (
      hasBeenModified[field.name as keyof typeof hasBeenModified] &&
      field.required &&
      !oAuthCredentials[field.name as keyof OAuthCredentials]
    );
  };

  const oAuthField = (field: InputOAuthField) => {
    const fieldName = field.required
      ? `${(field.label || field.name) as string} (required)`
      : field.label || field.name;

    const fieldLabel = (
      <>
        {getIsMissingInput(field) && <RequiredInputWarning />}
        {fieldName}
      </>
    );

    return (
      <ListItem disabled={field.locked} key={field.name}>
        <FormControl
          component="fieldset"
          id={`requirement${index}_input`}
          disabled={requirement.locked}
          required={!requirement.optional}
          error={getIsMissingInput(field)}
          fullWidth
          className={classes.inputField}
        >
          <FormLabel htmlFor={`requirement${index}_${field.name}`} className={classes.inputLabel}>
            {fieldLabel}
          </FormLabel>
          {field.description && (
            <Typography variant="subtitle1" className={classes.inputDescription}>
              {field.description}
            </Typography>
          )}
          <Input
            disabled={requirement.locked}
            required={field.required}
            error={getIsMissingInput(field)}
            id={`requirement${index}_${field.name}`}
            value={oAuthCredentials[field.name as keyof OAuthCredentials]}
            className={classes.inputField}
            color="secondary"
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
          />
        </FormControl>
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
          >
            <FieldLabel requirement={requirement} />
          </InputLabel>
          {requirement.description && (
            <Typography variant="subtitle1" className={classes.inputDescription}>
              {requirement.description}
            </Typography>
          )}
          <List>{oAuthFields.map((field) => !field.hide && oAuthField(field))}</List>
        </CardContent>
      </Card>
    </ListItem>
  );
};

export default InputOAuthCredentials;
