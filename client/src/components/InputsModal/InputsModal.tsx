import React, { FC, useEffect } from 'react';
import {
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
  List,
  TextField,
  ToggleButtonGroup,
  ToggleButton,
  Typography,
  Paper,
  Box,
  IconButton,
} from '@mui/material';
import { Close } from '@mui/icons-material';
import ReactMarkdown from 'react-markdown';
import YAML from 'js-yaml';
import { useSnackbar } from 'notistack';
import { OAuthCredentials, RunnableType, TestInput } from '~/models/testSuiteModels';
import InputOAuthCredentials from './InputOAuthCredentials';
import InputCheckboxGroup from './InputCheckboxGroup';
import InputRadioGroup from './InputRadioGroup';
import InputTextArea from './InputTextArea';
import InputTextField from './InputTextField';
import CustomTooltip from '../_common/CustomTooltip';
import useStyles from './styles';

export interface InputsModalProps {
  runnableType: RunnableType;
  runnableId: string;
  title: string;
  inputInstructions?: string;
  inputs: TestInput[];
  hideModal: () => void;
  createTestRun: (runnableType: RunnableType, runnableId: string, inputs: TestInput[]) => void;
  sessionData: Map<string, unknown>;
}

function runnableTypeReadable(runnableType: RunnableType) {
  switch (runnableType) {
    case RunnableType.TestSuite:
      return 'test suite';
    case RunnableType.TestGroup:
      return 'test group';
    case RunnableType.Test:
      return 'test';
  }
}

const InputsModal: FC<InputsModalProps> = ({
  runnableType,
  runnableId,
  title,
  inputInstructions,
  inputs,
  hideModal,
  createTestRun,
  sessionData,
}) => {
  const { classes } = useStyles();
  const { enqueueSnackbar } = useSnackbar();
  const [open, setOpen] = React.useState<boolean>(true);
  const [inputsEdited, setInputsEdited] = React.useState<boolean>(false);
  const [inputsMap, setInputsMap] = React.useState<Map<string, unknown>>(new Map());
  const [inputType, setInputType] = React.useState<string>('Field');
  const [baseInput, setBaseInput] = React.useState<string>('');
  const [invalidInput, setInvalidInput] = React.useState<boolean>(false);

  const missingRequiredInput = inputs.some((input: TestInput) => {
    // radio inputs will always be required and have a default value
    if (input.type === 'radio') return false;

    // if required, checkbox inputs must have at least one checked value
    if (input.type === 'checkbox') {
      try {
        const checkboxValues = JSON.parse(inputsMap.get(input.name) as string) as string[];
        return (
          !input.optional && (Array.isArray(checkboxValues) ? checkboxValues.length === 0 : true)
        );
      } catch (e: unknown) {
        const errorMessage = e instanceof Error ? e.message : String(e);
        enqueueSnackbar(`Checkbox input incorrectly formatted: ${errorMessage}`, {
          variant: 'error',
        });
        return true;
      }
    }

    // if input has OAuth, check if required values are filled
    let oAuthMissingRequiredInput = false;
    if (input.type === 'oauth_credentials') {
      try {
        const oAuthJSON = JSON.parse(
          (inputsMap.get(input.name) as string) || '{ "access_token": null }'
        ) as OAuthCredentials;
        const accessTokenIsEmpty = oAuthJSON.access_token === '';
        const refreshIsEmpty =
          oAuthJSON.refresh_token !== '' &&
          (oAuthJSON.token_url === '' || oAuthJSON.client_id === '');
        oAuthMissingRequiredInput = (accessTokenIsEmpty && !input.optional) || refreshIsEmpty;
      } catch (e: unknown) {
        const errorMessage = e instanceof Error ? e.message : String(e);
        enqueueSnackbar(`OAuth credentials incorrectly formatted: ${errorMessage}`, {
          variant: 'error',
        });
        return true;
      }
    }

    return (!input.optional && !inputsMap.get(input.name)) || oAuthMissingRequiredInput;
  });

  const instructions =
    inputInstructions ||
    `Please fill out required fields in order to run the ${runnableTypeReadable(runnableType)}.`;

  const inputFields = inputs.map((requirement: TestInput, index: number) => {
    switch (requirement.type) {
      case 'oauth_credentials':
        return (
          <InputOAuthCredentials
            requirement={requirement}
            index={index}
            inputsMap={inputsMap}
            setInputsMap={(newInputsMap) => handleSetInputsMap(newInputsMap)}
            key={`input-${index}`}
          />
        );
      case 'checkbox':
        return (
          <InputCheckboxGroup
            requirement={requirement}
            index={index}
            inputsMap={inputsMap}
            setInputsMap={(newInputsMap, editStatus) =>
              handleSetInputsMap(newInputsMap, editStatus)
            }
            key={`input-${index}`}
          />
        );
      case 'radio':
        return (
          <InputRadioGroup
            requirement={requirement}
            index={index}
            inputsMap={inputsMap}
            setInputsMap={(newInputsMap) => handleSetInputsMap(newInputsMap)}
            key={`input-${index}`}
          />
        );
      case 'textarea':
        return (
          <InputTextArea
            requirement={requirement}
            index={index}
            inputsMap={inputsMap}
            setInputsMap={(newInputsMap) => handleSetInputsMap(newInputsMap)}
            key={`input-${index}`}
          />
        );
      default:
        return (
          <InputTextField
            requirement={requirement}
            index={index}
            inputsMap={inputsMap}
            setInputsMap={(newInputsMap) => handleSetInputsMap(newInputsMap)}
            key={`input-${index}`}
          />
        );
    }
  });

  useEffect(() => {
    inputsMap.clear();
    inputs.forEach((requirement: TestInput) => {
      inputsMap.set(
        requirement.name,
        sessionData.get(requirement.name) || (requirement.default as string) || ''
      );
    });
    setInputsMap(new Map(inputsMap));
  }, [inputs, sessionData]);

  useEffect(() => {
    setInvalidInput(false);
    setBaseInput(serializeMap(inputsMap));
  }, [inputType, open]);

  const handleInputTypeChange = (e: React.MouseEvent, value: string) => {
    if (value !== null) setInputType(value);
  };

  const handleSetInputsMap = (inputsMap: Map<string, unknown>, edited?: boolean) => {
    setInputsMap(inputsMap);
    setInputsEdited(inputsEdited || edited !== false); // explicit check for false values
  };

  const handleSubmitKeydown = (e: React.KeyboardEvent<HTMLDivElement>) => {
    if (
      open &&
      e.key === 'Enter' &&
      (e.metaKey || e.ctrlKey) &&
      !missingRequiredInput &&
      !invalidInput
    ) {
      submitClicked();
    }
  };

  const submitClicked = () => {
    const inputs_with_values: TestInput[] = [];
    inputsMap.forEach((input_value, input_name) => {
      inputs_with_values.push({ name: input_name, value: input_value, type: 'text' });
    });
    createTestRun(runnableType, runnableId, inputs_with_values);
    closeModal();
  };

  const serializeMap = (map: Map<string, unknown>): string => {
    const flatObj = inputs.map((requirement: TestInput) => {
      // Parse out \n chars from descriptions
      const parsedDescription = requirement.description?.replaceAll('\n', ' ').trim();
      if (requirement.type === 'oauth_credentials') {
        return {
          ...requirement,
          description: parsedDescription,
          value: JSON.parse(
            (map.get(requirement.name) as string) || '{ "access_token": "" }'
          ) as OAuthCredentials,
        };
      } else if (requirement.type === 'radio') {
        const firstVal =
          requirement.options?.list_options && requirement.options?.list_options?.length > 0
            ? requirement.options?.list_options[0]?.value
            : '';
        return {
          ...requirement,
          description: parsedDescription,
          value: map.get(requirement.name) || requirement.default || firstVal,
        };
      } else {
        return {
          ...requirement,
          description: parsedDescription,
          value: map.get(requirement.name) || '',
        };
      }
    });
    return inputType === 'JSON'
      ? JSON.stringify(flatObj, null, 2)
      : YAML.dump(flatObj, { lineWidth: -1 });
  };

  const parseSerialChanges = (changes: string): TestInput[] | undefined => {
    let parsed: TestInput[];
    try {
      if (inputType === 'JSON') {
        parsed = JSON.parse(changes) as TestInput[];
      } else {
        parsed = YAML.load(changes) as TestInput[];
      }
      // Convert OAuth input values to strings
      parsed.forEach((input) => {
        if (input.type === 'oauth_credentials') {
          input.value = JSON.stringify(input.value);
        }
      });
      setInvalidInput(false);
      return parsed;
    } catch (e) {
      setInvalidInput(true);
      return undefined;
    }
  };

  const handleSerialChanges = (serialChanges: string) => {
    const parsedChanges = parseSerialChanges(serialChanges);
    if (parsedChanges !== undefined && parsedChanges.keys !== undefined) {
      parsedChanges.forEach((change: TestInput) => {
        if (!change.locked && change.value !== undefined)
          inputsMap.set(change.name, change.value || '');
      });
    }
    handleSetInputsMap(new Map(inputsMap), true);
  };

  const closeModal = (edited = false) => {
    // For external clicks, check if inputs have been edited first
    if (!edited) {
      setOpen(false);
      hideModal();
    }
  };

  return (
    <Dialog
      open={open}
      fullWidth
      maxWidth="sm"
      onKeyDown={handleSubmitKeydown}
      onClose={() => closeModal(inputsEdited)}
    >
      <DialogTitle component="div">
        <Box display="flex" justifyContent="space-between">
          <Typography component="h1" variant="h6">
            {title}
          </Typography>
          <CustomTooltip title="Cancel - Inputs will be lost">
            <IconButton
              onClick={() => closeModal()}
              aria-label="cancel"
              sx={{
                position: 'absolute',
                right: 8,
                top: 8,
              }}
            >
              <Close />
            </IconButton>
          </CustomTooltip>
        </Box>
      </DialogTitle>
      <DialogContent>
        <main>
          <DialogContentText component="div" style={{ wordBreak: 'break-word' }}>
            <ReactMarkdown>
              {instructions +
                (inputType === 'Field'
                  ? ''
                  : ' In this view, only changes to the value attribute of an element will be saved. Further, only elements with names that match an input defined for the current suite, group, or test will be saved. The intended use of this view is to provide a template for users to copy/paste in order to avoid filling out individual fields every time.')}
            </ReactMarkdown>
          </DialogContentText>
          {inputType === 'Field' ? (
            <List>{inputFields}</List>
          ) : (
            <TextField
              id={`${inputType}-serial-input`}
              minRows={4}
              key={baseInput}
              error={invalidInput}
              defaultValue={baseInput}
              label={invalidInput ? `ERROR: INVALID ${inputType}` : inputType}
              InputProps={{
                classes: {
                  input: classes.serialInput,
                },
              }}
              color="secondary"
              fullWidth
              multiline
              data-testid="serial-input"
              onChange={(e) => handleSerialChanges(e.target.value)}
            />
          )}
        </main>
      </DialogContent>
      <DialogActions className={classes.dialogActions}>
        <Paper elevation={0} className={classes.toggleButtonGroupContainer}>
          <ToggleButtonGroup
            exclusive
            role="group"
            color="secondary"
            size="small"
            value={inputType}
            onChange={handleInputTypeChange}
            className={classes.toggleButtonGroup}
          >
            <ToggleButton
              value="Field"
              disabled={invalidInput}
              data-testid="field-button"
              className={classes.toggleButton}
            >
              Field
            </ToggleButton>
            <ToggleButton
              value="JSON"
              disabled={invalidInput}
              data-testid="json-button"
              className={classes.toggleButton}
            >
              JSON
            </ToggleButton>
            <ToggleButton
              value="YAML"
              disabled={invalidInput}
              data-testid="yaml-button"
              className={classes.toggleButton}
            >
              YAML
            </ToggleButton>
          </ToggleButtonGroup>
        </Paper>
        <Box>
          <Button
            color="secondary"
            data-testid="cancel-button"
            onClick={() => closeModal()}
            sx={{ mr: 1 }}
          >
            Cancel
          </Button>
          <Button
            color="secondary"
            variant="contained"
            disableElevation
            onClick={submitClicked}
            disabled={missingRequiredInput || invalidInput}
          >
            Submit
          </Button>
        </Box>
      </DialogActions>
    </Dialog>
  );
};

export default InputsModal;
