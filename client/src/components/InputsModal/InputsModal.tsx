import React, { FC, useEffect } from 'react';
import {
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
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
import remarkGfm from 'remark-gfm';
import YAML from 'js-yaml';
import { useSnackbar } from 'notistack';
import { OAuthCredentials, Runnable, RunnableType, TestInput } from '~/models/testSuiteModels';
import CustomTooltip from '~/components/_common/CustomTooltip';
import InputFields from '~/components/InputsModal/InputFields';
import useStyles from '~/components/InputsModal/styles';
import DownloadFileButton from '../_common/DownloadFileButton';
import UploadFileButton from '../_common/UploadFileButton';
import CopyButton from '../_common/CopyButton';

export interface InputsModalProps {
  modalVisible: boolean;
  hideModal: () => void;
  runnable: Runnable | null;
  runnableType: RunnableType;
  inputs: TestInput[];
  sessionData: Map<string, unknown>;
  createTestRun: (runnableType: RunnableType, runnableId: string, inputs: TestInput[]) => void;
}

const runnableTypeReadable = (runnableType: RunnableType) => {
  switch (runnableType) {
    case RunnableType.TestSuite:
      return 'test suite';
    case RunnableType.TestGroup:
      return 'test group';
    case RunnableType.Test:
      return 'test';
  }
};

const InputsModal: FC<InputsModalProps> = ({
  modalVisible,
  hideModal,
  runnable,
  runnableType,
  inputs,
  sessionData,
  createTestRun,
}) => {
  const { classes } = useStyles();
  const { enqueueSnackbar } = useSnackbar();
  const [inputsEdited, setInputsEdited] = React.useState<boolean>(false);
  const [inputsMap, setInputsMap] = React.useState<Map<string, unknown>>(new Map());
  const [inputType, setInputType] = React.useState<string>('Field');
  const [fileType, setFileType] = React.useState<string>('txt');
  const [serialInput, setSerialInput] = React.useState<string>('');
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
        const accessTokenIsEmpty = !oAuthJSON.access_token;
        const refreshTokenIsEmpty =
          !!oAuthJSON.refresh_token && (!oAuthJSON.token_url || !oAuthJSON.client_id);
        oAuthMissingRequiredInput = (!input.optional && accessTokenIsEmpty) || refreshTokenIsEmpty;
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
    runnable?.input_instructions ||
    `Please fill out required fields in order to run the ${runnableTypeReadable(runnableType)}.` +
      (inputType === 'Field'
        ? ''
        : ' In this view, only changes to the value attribute of an element will be saved. \
          Further, only elements with names that match an input defined for the current suite, \
          group, or test will be saved. The intended use of this view is to provide a template \
          for users to copy/paste in order to avoid filling out individual fields every time.');

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
    setSerialInput(serializeMap(inputsMap));

    // Set download file extensions based on input format
    switch (inputType) {
      case 'JSON':
        setFileType('json');
        break;
      case 'YAML':
        setFileType('yml');
        break;
      default:
        setFileType('txt');
        break;
    }
  }, [inputType, modalVisible]);

  const handleInputTypeChange = (e: React.MouseEvent, value: string) => {
    if (value !== null) setInputType(value);
  };

  const handleFileUpload = (text: string) => {
    handleSerialChanges(text);
    setSerialInput(text);
  };

  const handleSetInputsMap = (inputsMap: Map<string, unknown>, edited?: boolean) => {
    setInputsMap(inputsMap);
    setInputsEdited(inputsEdited || edited !== false); // explicit check for false values
  };

  const handleSubmitKeydown = (e: React.KeyboardEvent<HTMLDivElement>) => {
    const opKey = e.metaKey || e.ctrlKey;
    if (modalVisible && e.key === 'Enter' && opKey && !missingRequiredInput && !invalidInput) {
      submitClicked();
    }
  };

  const submitClicked = () => {
    const inputs_with_values: TestInput[] = [];
    inputsMap.forEach((input_value, input_name) => {
      inputs_with_values.push({ name: input_name, value: input_value, type: 'text' });
    });
    createTestRun(runnableType, runnable?.id || '', inputs_with_values);
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
      parsed = (inputType === 'JSON' ? JSON.parse(changes) : YAML.load(changes)) as TestInput[];
      // Convert OAuth input values to strings; parsed needs to be an array
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
    setSerialInput(serialChanges);
    const parsedChanges = parseSerialChanges(serialChanges);
    if (parsedChanges !== undefined && parsedChanges.keys !== undefined) {
      parsedChanges.forEach((change: TestInput) => {
        if (!change.locked && change.value !== undefined) {
          inputsMap.set(change.name, change.value || '');
        }
      });
    }
    handleSetInputsMap(new Map(inputsMap), true);
  };

  const closeModal = (edited = false) => {
    // For external clicks, check if inputs have been edited first
    if (!edited) {
      hideModal();
    }
  };

  return (
    <Dialog
      open={modalVisible}
      fullWidth
      maxWidth="sm"
      onKeyDown={handleSubmitKeydown}
      onClose={() => closeModal(inputsEdited)}
    >
      <DialogTitle component="div">
        <Box display="flex" justifyContent="space-between">
          <Typography component="h1" variant="h6">
            {runnable?.title || 'Test'}
          </Typography>
          <CustomTooltip title="Cancel - Inputs will be lost">
            <IconButton
              onClick={() => closeModal()}
              aria-label="cancel"
              className={classes.cancelButton}
            >
              <Close />
            </IconButton>
          </CustomTooltip>
        </Box>
      </DialogTitle>
      <DialogContent>
        <main>
          <DialogContentText component="div" sx={{ wordBreak: 'break-word' }}>
            <ReactMarkdown remarkPlugins={[remarkGfm]}>{instructions}</ReactMarkdown>
          </DialogContentText>
          {inputType === 'Field' ? (
            <InputFields inputs={inputs} inputsMap={inputsMap} setInputsMap={handleSetInputsMap} />
          ) : (
            <Box>
              <UploadFileButton onUpload={handleFileUpload} />
              <DownloadFileButton
                fileName={runnable?.title || 'Untitled Inferno File'}
                fileType={fileType}
              />
              <TextField
                id={`${fileType}-serial-input`}
                minRows={4}
                value={serialInput}
                error={invalidInput}
                label={invalidInput ? `ERROR: INVALID ${inputType}` : inputType}
                InputProps={{
                  classes: {
                    input: classes.serialInput,
                  },
                  endAdornment: (
                    <Box sx={{ alignSelf: 'flex-start' }}>
                      <CopyButton copyText={serialInput} />
                    </Box>
                  ),
                }}
                color="secondary"
                fullWidth
                multiline
                data-testid="serial-input"
                onChange={(e) => handleSerialChanges(e.target.value)}
              />
            </Box>
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
            {['Field', 'JSON', 'YAML'].map((type) => {
              return (
                <ToggleButton
                  value={type}
                  disabled={invalidInput}
                  key={`${type.toLowerCase()}-button`}
                  data-testid={`${type.toLowerCase()}-button`}
                  className={classes.toggleButton}
                >
                  {type}
                </ToggleButton>
              );
            })}
          </ToggleButtonGroup>
        </Paper>
        <Box>
          <Button
            color="secondary"
            data-testid="cancel-button"
            onClick={() => closeModal()}
            sx={{ mr: 1, fontWeight: 'bold' }}
          >
            Cancel
          </Button>
          <Button
            color="secondary"
            variant="contained"
            disableElevation
            onClick={submitClicked}
            disabled={missingRequiredInput || invalidInput}
            sx={{ fontWeight: 'bold' }}
          >
            Submit
          </Button>
        </Box>
      </DialogActions>
    </Dialog>
  );
};

export default InputsModal;
