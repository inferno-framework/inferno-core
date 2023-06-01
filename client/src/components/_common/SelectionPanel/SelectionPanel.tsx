import React, { FC, useEffect } from 'react';
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
  isListOptionSelection,
  isRadioOption,
} from '~/models/selectionModels';

export interface SelectionPanelProps {
  title: string;
  options: ListOption[] | RadioOption[];
  optionType?: string;
  selection?: ListOptionSelection | RadioOptionSelection[];
  setSelection: (selected: ListOptionSelection | RadioOptionSelection[] | null) => void;
  showBackButton?: boolean;
  backTooltipText?: string;
  backClickHandler?: () => void;
  submitAction: () => void;
  submitText: string;
}

const SelectionPanel: FC<SelectionPanelProps> = ({
  title,
  options,
  selection: parentSelection,
  setSelection: setParentSelection,
  showBackButton = false,
  backTooltipText = '',
  backClickHandler,
  submitAction,
  submitText,
}) => {
  const { classes } = useStyles();
  const windowIsSmall = useAppStore((state) => state.windowIsSmall);
  const [selection, setSelection] = React.useState<
    ListOptionSelection | RadioOptionSelection[] | null | undefined
  >(parentSelection || null);

  useEffect(() => {
    setSelection(parentSelection);
  }, [parentSelection]);

  const renderSelection = () => {
    if (options.every((o) => isRadioOption(o))) {
      return <RadioSelection options={options as RadioOption[]} setSelections={selectionHandler} />;
    } else if (options.every((o) => isListOption(o))) {
      return (
        <ListSelection
          options={options}
          selection={selection && isListOptionSelection(selection) ? selection : ''}
          setSelection={selectionHandler}
        />
      );
    }
  };

  const selectionHandler = (selected: ListOptionSelection | RadioOptionSelection[] | null) => {
    setSelection(selected);
    setParentSelection(selected);
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
          {showBackButton && backClickHandler && (
            <BackButton tooltipText={backTooltipText} clickHandler={backClickHandler} />
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
            disabled={!selection}
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
