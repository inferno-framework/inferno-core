import React, { FC } from 'react';
import {
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  TextField,
  Snackbar,
  Alert,
  AlertColor,
  MenuItem,
} from '@mui/material';
import { applyPreset } from 'api/TestSessionApi';
import { PresetSummary } from 'models/testSuiteModels';
import theme from '../../styles/theme';
import lightTheme from '../../styles/theme';

export interface PresetsModalProps {
  presets: PresetSummary[];
  testSessionId: string;
  getSessionData: (testSessionId: string) => void;
}

const PresetsSelector: FC<PresetsModalProps> = ({ presets, testSessionId, getSessionData }) => {
  const null_preset = { id: 'NULL_PRESET', title: 'None' };
  const presetTitleToIdMap: { [key: string]: string } = presets.reduce(
    (reducedObj, preset) => ({ ...reducedObj, [preset.title]: preset.id }),
    {}
  );

  const SHOW_CONFIRMATION_MODAL = false;

  const [presetOptions, setPresetOptions] = React.useState([
    null_preset,
    ...presets.sort((p1, p2) => {
      if (p1.title > p2.title) return 1;
      if (p1.title < p2.title) return -1;
      return 0;
    }),
  ]);
  const [formerPreset, setFormerPreset] = React.useState(null_preset.title);
  const [selectedPreset, setSelectedPreset] = React.useState(null_preset.title);
  const [modalVisible, setModalVisible] = React.useState(false);
  const [snackbarVisible, setSnackbarVisible] = React.useState(false);
  const [snackbarStatus, setSnackbarStatus] = React.useState('');
  const [snackbarMessage, setSnackbarMessage] = React.useState('');

  const applyPresetToSession = (presetId: string) => {
    applyPreset(testSessionId, presetId)
      .then(() => {
        getSessionData(testSessionId);
      })
      .catch((e) => {
        setSnackbarStatus('error');
        setSnackbarMessage(`Could not set preset: ${e as string}`);
        setTimeout(() => setSnackbarVisible(false), 4000);
      });
  };

  // To be used when the null preset option has no behavior
  const removeNullFromOptions = () => {
    const nullIndex = presetOptions.findIndex((option) => option.id === null_preset.id);
    if (nullIndex >= 0) {
      presetOptions.splice(nullIndex, 1);
      setPresetOptions(presetOptions);
    }
  };

  const handleOnChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.value) {
      setSelectedPreset(e.target.value);
      // Remove when modal is active
      if (!SHOW_CONFIRMATION_MODAL) {
        applyPresetToSession(presetTitleToIdMap[e.target.value]);
      }
    }
    // TODO: Handle clearing old results on preset change
    if (e.target.value && e.target.value !== null_preset.title) {
      if (SHOW_CONFIRMATION_MODAL) {
        setModalVisible(true);
      } else {
        removeNullFromOptions(); // If null preset behavior is added, remove this
        setSnackbarVisible(true);
        setSnackbarStatus('success');
        setSnackbarMessage(`${e.target.value} has been set as preset.`);
        setTimeout(() => setSnackbarVisible(false), 4000);
      }
    }
  };

  return (
    <>
      <TextField
        id="preset-select"
        fullWidth
        size="small"
        select
        label="Preset"
        InputLabelProps={{
          sx: { '&.Mui-focused': { color: lightTheme.palette.common.orangeDarker } },
        }}
        value={selectedPreset}
        onChange={handleOnChange}
      >
        {presetOptions.map((option) => (
          <MenuItem key={option.id} value={option.title}>
            {option.title}
          </MenuItem>
        ))}
      </TextField>
      <Snackbar
        open={snackbarVisible}
        autoHideDuration={4000}
        anchorOrigin={{ horizontal: 'right', vertical: 'bottom' }}
        sx={{ marginBottom: '48px' }}
      >
        <Alert
          onClose={() => setSnackbarVisible(false)}
          severity={(snackbarStatus as AlertColor) || 'warning'}
        >
          {snackbarMessage}
        </Alert>
      </Snackbar>
      <Dialog open={modalVisible} fullWidth maxWidth="xs">
        <DialogTitle>Are you sure?</DialogTitle>
        <DialogContent>
          Selecting a new preset will clear all existing test results. If you wish to proceed, click
          the Apply Preset button.
        </DialogContent>
        <DialogActions>
          <Button
            data-testid="preset-cancel-button"
            sx={{ color: theme.palette.primary.dark }}
            onClick={() => {
              setSelectedPreset(formerPreset);
              setModalVisible(false);
            }}
          >
            Cancel
          </Button>
          <Button
            data-testid="preset-apply-button"
            sx={{ color: theme.palette.primary.dark }}
            onClick={() => {
              applyPresetToSession(presetTitleToIdMap[selectedPreset]);
              setFormerPreset(selectedPreset);
              setModalVisible(false);
              removeNullFromOptions(); // If null preset behavior is added, remove this
            }}
          >
            Apply Preset
          </Button>
        </DialogActions>
      </Dialog>
    </>
  );
};

export default PresetsSelector;
