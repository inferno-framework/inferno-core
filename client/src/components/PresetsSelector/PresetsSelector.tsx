import React, { FC } from 'react';
import {
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Autocomplete,
  TextField,
  Snackbar,
  Alert,
  AlertColor,
} from '@mui/material';
import { applyPreset } from 'api/TestSessionApi';
import { PresetSummary } from 'models/testSuiteModels';
import theme from '../../styles/theme';

export interface PresetsModalProps {
  presets: PresetSummary[];
  testSessionId: string;
  getSessionData: (testSessionId: string) => void;
}

const PresetsSelector: FC<PresetsModalProps> = ({ presets, testSessionId, getSessionData }) => {
  const null_preset_id = 'NULL_PRESET';
  const presetOptions = [
    { id: null_preset_id, label: 'None' },
    ...presets.map((p) => ({ id: p.id, label: p.title })),
  ];
  const SHOW_CONFIRMATION_MODAL = false;

  const [selectedPreset, setSelectedPreset] = React.useState(presetOptions[0]);
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
      });
  };

  return (
    <>
      <Autocomplete
        disablePortal
        fullWidth
        size="small"
        id="preset-select"
        value={selectedPreset}
        options={presetOptions}
        isOptionEqualToValue={(option1, option2) => option1.id === option2.id}
        renderInput={(params) => <TextField {...params} label="Preset" />}
        onChange={(e, newValue) => {
          if (newValue) {
            setSelectedPreset(newValue);
            // Remove when modal is active
            if (!SHOW_CONFIRMATION_MODAL) {
              applyPresetToSession(newValue.id);
            }
          }
          // TODO: Handle clearing old results on preset change
          if (newValue && newValue.id !== null_preset_id) {
            if (SHOW_CONFIRMATION_MODAL) {
              setModalVisible(true);
            } else {
              setSnackbarVisible(true);
              setSnackbarStatus('success');
              setSnackbarMessage(`${newValue.label} has been set as preset.`);
            }
          }
        }}
      />
      <Snackbar
        open={snackbarVisible}
        autoHideDuration={6000}
        anchorOrigin={{ horizontal: 'right', vertical: 'bottom' }}
        sx={{ marginBottom: '48px' }}
      >
        <Alert
          onClose={() => setSnackbarVisible(false)}
          severity={(snackbarStatus as AlertColor) || 'warning'}
          sx={{ width: '100%' }}
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
            onClick={() => setModalVisible(false)}
          >
            Cancel
          </Button>
          <Button
            data-testid="preset-apply-button"
            sx={{ color: theme.palette.primary.dark }}
            onClick={() => {
              applyPresetToSession(selectedPreset.id);
              setModalVisible(false);
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
