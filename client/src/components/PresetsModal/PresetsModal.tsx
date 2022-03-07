import React, { FC } from 'react';
import {
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  FormControl,
  Select,
  MenuItem,
} from '@mui/material';
import { applyPreset } from 'api/TestSessionApi';
import { PresetSummary } from 'models/testSuiteModels';
import theme from '../../styles/theme';

export interface PresetsModalProps {
  modalVisible: boolean;
  presets: PresetSummary[];
  testSessionId: string;
  getSessionData: (testSessionId: string) => void;
  setModalVisible: (visible: boolean) => void;
}

const PresetsModal: FC<PresetsModalProps> = ({
  modalVisible,
  presets,
  testSessionId,
  getSessionData,
  setModalVisible,
}) => {
  const null_preset_id = 'NULL_PRESET';
  const [selectedPreset, setSelectedPreset] = React.useState(null_preset_id);

  const applyPresetToSession = () => {
    applyPreset(testSessionId, selectedPreset)
      .then(() => {
        getSessionData(testSessionId);
      })
      .catch((e) => console.log(e))
      .finally(() => setModalVisible(false));
  };

  const presetOptions = [{ id: null_preset_id, title: 'None' }, ...presets].map((preset, index) => {
    return (
      <MenuItem value={preset.id} key={index}>
        {preset.title}
      </MenuItem>
    );
  });

  return (
    <Dialog open={modalVisible} fullWidth maxWidth="xs">
      <DialogTitle>Select Preset Inputs</DialogTitle>
      <DialogContent>
        <FormControl>
          <Select value={selectedPreset} onChange={(e) => setSelectedPreset(e.target.value)}>
            {presetOptions}
          </Select>
        </FormControl>
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
          disabled={selectedPreset === null_preset_id}
          sx={{ color: theme.palette.primary.dark }}
          onClick={applyPresetToSession}
        >
          Apply Preset
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default PresetsModal;
