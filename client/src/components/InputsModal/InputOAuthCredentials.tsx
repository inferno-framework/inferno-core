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
import Markdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import { OAuthCredentials, TestInput } from '~/models/testSuiteModels';
import FieldLabel from '~/components/InputsModal/FieldLabel';
import RequiredInputWarning from '~/components/InputsModal/RequiredInputWarning';
import { useTestSessionStore } from '~/store/testSession';
import lightTheme from '~/styles/theme';
import useStyles from './styles';

export interface InputOAuthCredentialsProps {
  input: TestInput;
  index: number;
  inputsMap: Map<string, unknown>;
  setInputsMap: (map: Map<string, unknown>, edited?: boolean) => void;
}

const InputOAuthCredentials: FC<InputOAuthCredentialsProps> = ({
  input,
  index,
  inputsMap,
  setInputsMap,
}) => {
  const { classes } = useStyles();
  const viewOnly = useTestSessionStore((state) => state.viewOnly);
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
    ...JSON.parse((inputsMap.get(input.name) as string) || '{}'),
  } as OAuthCredentials;

  const showRefreshDetails = !!oAuthCredentials.refresh_token;

  const oAuthFields: TestInput[] = [
    {
      name: 'access_token',
      title: 'Access Token',
      optional: input.optional,
    },
    {
      name: 'refresh_token',
      title: 'Refresh Token (will automatically refresh if available)',
      optional: true,
    },
    {
      name: 'token_url',
      title: 'Token Endpoint',
      hidden: !showRefreshDetails,
    },
    {
      name: 'client_id',
      title: 'Client ID',
      hidden: !showRefreshDetails,
    },
    {
      name: 'client_secret',
      title: 'Client Secret',
      hidden: !showRefreshDetails,
      optional: true,
    },
    {
      name: 'expires_in',
      title: 'Expires in (seconds)',
      hidden: !showRefreshDetails,
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

  // Convert internal OAuth credentials object to inputsMap string
  const updateInputsMap = (field: TestInput, value: string) => {
    oAuthCredentials[field.name as keyof OAuthCredentials] = value;
    // Delete fields with empty values
    const parsedOAuthCredentials: Record<string, unknown> = {};
    Object.entries(oAuthCredentials).forEach(([inputName, inputValue]) => {
      if (inputValue) {
        parsedOAuthCredentials[inputName] = inputValue;
      }
    });
    inputsMap.set(input.name, JSON.stringify(parsedOAuthCredentials));
    setInputsMap(new Map(inputsMap));
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
      <ListItem key={field.name} component="li" className={classes.inputField}>
        <FormControl
          component="fieldset"
          id={`input${index}_input`}
          tabIndex={0}
          disabled={input.locked || viewOnly}
          aria-disabled={input.locked || viewOnly}
          required={!input.optional}
          error={getIsMissingInput(field)}
          fullWidth
          className={classes.inputField}
        >
          <FormLabel htmlFor={`input${index}_${field.name}`} className={classes.inputLabel}>
            {fieldLabel}
          </FormLabel>
          {field.description && (
            <Markdown className={classes.inputDescription} remarkPlugins={[remarkGfm]}>
              {input.description}
            </Markdown>
          )}
          <Input
            tabIndex={0}
            disabled={input.locked || viewOnly}
            aria-disabled={input.locked || viewOnly}
            required={!field.optional}
            error={getIsMissingInput(field)}
            id={`input${index}_${field.name}`}
            value={oAuthCredentials[field.name as keyof OAuthCredentials]}
            className={classes.inputField}
            color="secondary"
            fullWidth
            onBlur={(e) => {
              if (e.currentTarget === e.target) {
                setHasBeenModified({ ...hasBeenModified, [field.name]: true });
              }
            }}
            onChange={(event) => updateInputsMap(field, event.target.value)}
          />
        </FormControl>
      </ListItem>
    );
  };

  return (
    <ListItem>
      <Card
        variant="outlined"
        className={classes.authCard}
        sx={input.locked || viewOnly ? {} : { borderColor: lightTheme.palette.common.gray }}
      >
        <CardContent>
          <InputLabel
            required={!input.optional}
            tabIndex={0}
            disabled={input.locked || viewOnly}
            aria-disabled={input.locked || viewOnly}
            className={classes.inputLabel}
          >
            <FieldLabel input={input} />
          </InputLabel>
          {input.description && (
            <Typography variant="subtitle1" component="p" className={classes.inputDescription}>
              {input.description}
            </Typography>
          )}
          <List>{oAuthFields.map((field) => !field.hidden && oAuthField(field))}</List>
        </CardContent>
      </Card>
    </ListItem>
  );
};

export default InputOAuthCredentials;
