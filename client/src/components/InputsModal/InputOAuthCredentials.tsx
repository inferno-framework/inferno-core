import React, { FC } from 'react';
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

  const oAuthFields: TestInput[] = [
    {
      name: 'access_token',
      title: 'Access Token',
      optional: requirement.optional,
    },
    {
      name: 'refresh_token',
      title: 'Refresh Token (will automatically refresh if available)',
      optional: true,
    },
    {
      name: 'token_url',
      title: 'Token Endpoint',
      hide: !showRefreshDetails,
    },
    {
      name: 'client_id',
      title: 'Client ID',
      hide: !showRefreshDetails,
    },
    {
      name: 'client_secret',
      title: 'Client Secret',
      hide: !showRefreshDetails,
      optional: true,
    },
    {
      name: 'expires_in',
      title: 'Expires in (seconds)',
      hide: !showRefreshDetails,
      optional: true,
    },
  ];

  const getIsMissingInput = (field: TestInput) => {
    return (
      hasBeenModified[field.name as keyof typeof hasBeenModified] &&
      !field.optional &&
      !oAuthCredentials[field.name as keyof OAuthCredentials]
    );
  };

  const oAuthField = (field: TestInput) => {
    const fieldName = field.optional
      ? field.title || field.name
      : `${(field.title || field.name) as string} (required)`;

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
            required={!field.optional}
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
          <List>{oAuthFields.map((field) => !field.hide && oAuthField(field))}</List>
        </CardContent>
      </Card>
    </ListItem>
  );
};

export default InputOAuthCredentials;
