import React, { FC } from 'react';
import { Typography, Button, Paper, Box } from '@mui/material';
import BackButton from '~/components/_common/BackButton';
import ListSelection from '~/components/_common/SelectionPanel/ListSelection';
import RadioSelection from '~/components/_common/SelectionPanel/RadioSelection';
import useStyles from '~/components/_common/SelectionPanel/styles';
import { useAppStore } from '~/store/app';
import {
  ListOption,
  ListOptionSelection,
  RadioOption,
  RadioOptionSelection,
  isListOption,
  isRadioOption,
} from '~/models/selectionModels';

export interface SelectionPanelProps {
  title: string;
  options: ListOption[] | RadioOption[];
  optionType?: string;
  setSelection: (selected: ListOptionSelection | RadioOptionSelection[]) => void;
  showBackButton?: boolean;
  backTooltipText?: string;
  backDestination?: string;
  submitAction: () => void;
  submitText: string;
}

const SelectionPanel: FC<SelectionPanelProps> = ({
  title,
  options,
  setSelection,
  showBackButton = false,
  backTooltipText = '',
  backDestination = '/',
  submitAction,
  submitText,
}) => {
  const { classes } = useStyles();
  const windowIsSmall = useAppStore((state) => state.windowIsSmall);

  const renderSelection = () => {
    if (options.every((o) => isRadioOption(o))) {
      return <RadioSelection options={options as RadioOption[]} setSelections={setSelection} />;
    } else if (options.every((o) => isListOption(o))) {
      return <ListSelection options={options} setSelection={setSelection} />;
    }
  };

  return (
    <Box display="flex">
      <Paper
        elevation={4}
        className={classes.optionsList}
        sx={{ width: windowIsSmall ? 'auto' : '400px', maxWidth: '400px' }}
      >
        <Box
          display="flex"
          alignItems="center"
          justifyContent={showBackButton ? 'space-between' : 'center'}
          mx={1}
        >
          {showBackButton && (
            <BackButton tooltipText={backTooltipText} destination={backDestination} />
          )}
          <Typography
            variant="h4"
            component="h2"
            align="center"
            sx={{
              fontSize: windowIsSmall ? '1.8rem' : 'auto',
            }}
          >
            {title}
          </Typography>
          {/* Spacer to center title with button */}
          {showBackButton && <Box minWidth="45px" />}
        </Box>

        <Box overflow="auto">
          {options ? renderSelection() : <Typography mt={2}> No options available.</Typography>}
        </Box>

        <Box px={2}>
          <Button
            variant="contained"
            size="large"
            color="primary"
            fullWidth
            data-testid="go-button"
            sx={{ fontWeight: 600 }}
            onClick={() => submitAction()}
          >
            {submitText}
          </Button>
        </Box>
      </Paper>
    </Box>
  );
};

export default SelectionPanel;
