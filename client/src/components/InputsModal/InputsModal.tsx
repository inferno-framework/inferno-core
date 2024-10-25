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
import { Runnable, RunnableType, TestInput } from '~/models/testSuiteModels';
import CopyButton from '~/components/_common/CopyButton';
import CustomTooltip from '~/components/_common/CustomTooltip';
import DownloadFileButton from '~/components/_common/DownloadFileButton';
import UploadFileButton from '~/components/_common/UploadFileButton';
import {
  getMissingRequiredInput,
  parseSerialChanges,
  serializeMap,
} from '~/components/InputsModal/InputHelpers';
import InputFields from '~/components/InputsModal/InputFields';
import useStyles from '~/components/InputsModal/styles';

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
  const [inputsEdited, setInputsEdited] = React.useState<boolean>(false);
  const [inputsMap, setInputsMap] = React.useState<Map<string, unknown>>(new Map());
  const [inputType, setInputType] = React.useState<string>('Field');
  const [fileType, setFileType] = React.useState<string>('txt');
  const [serialInput, setSerialInput] = React.useState<string>('');
  const [missingRequiredInput, setMissingRequiredInput] = React.useState<boolean>(false);
  const [invalidInput, setInvalidInput] = React.useState<boolean>(false);

  const instructions =
    runnable?.input_instructions ||
    `Please fill out required fields in order to run the ${runnableTypeReadable(runnableType)}.` +
      (inputType === 'Field'
        ? ''
        : ' In this view, only changes to the value attribute of an element will be saved. \
          Further, only elements with names that match an input defined for the current suite, \
          group, or test will be saved. The intended use of this view is to provide a template \
          for users to copy/paste in order to avoid filling out individual fields every time.');

  // Set persisted values and defaults at render
  useEffect(() => {
    inputsMap.clear();
    inputs.forEach((requirement: TestInput) => {
      inputsMap.set(
        requirement.name,
        sessionData.get(requirement.name) || requirement.default || '',
      );
    });
    setInputsMap(new Map(inputsMap));
  }, [inputs, sessionData]);

  // Recalculate missing required values on changes to inputs
  useEffect(() => {
    setMissingRequiredInput(getMissingRequiredInput(inputs, inputsMap));
    return () => {
      setMissingRequiredInput(false);
    };
  }, [inputsMap]);

  useEffect(() => {
    setInvalidInput(false);
    setSerialInput(serializeMap(inputType, inputs, inputsMap));

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

  const handleSerialChanges = (serialChanges: string) => {
    setSerialInput(serialChanges);
    const parsedChanges = parseSerialChanges(inputType, serialChanges, setInvalidInput);
    if (parsedChanges !== undefined && parsedChanges.keys !== undefined) {
      parsedChanges.forEach((change: TestInput) => {
        if (!change.locked && change.value !== undefined) {
          inputsMap.set(change.name, change.value || '');
        }
      });
    }
    handleSetInputsMap(new Map(inputsMap), true);
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
    const inputsWithValues: TestInput[] = [];
    inputsMap.forEach((inputValue, inputName) => {
      inputsWithValues.push({ name: inputName, value: inputValue, type: 'text' });
    });
    createTestRun(runnableType, runnable?.id || '', inputsWithValues);
    closeModal();
  };

  const closeModal = (edited = false) => {
    // For external clicks, check if inputs have been edited first
    if (!edited) hideModal();
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
                slotProps={{
                  input: {
                    classes: {
                      input: classes.serialInput,
                    },
                    endAdornment: (
                      <Box sx={{ alignSelf: 'flex-start' }}>
                        <CopyButton copyText={serialInput} />
                      </Box>
                    ),
                  },
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
