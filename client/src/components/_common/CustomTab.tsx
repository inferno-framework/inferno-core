import * as React from 'react';
import { styled } from '@mui/material/styles';
import { Tab } from '@mui/material';

interface CustomTabProps {
  label: React.ReactNode;
  disabled?: boolean;
}

const CustomTab = styled((props: CustomTabProps) => <Tab disableRipple {...props} />)(
  ({ theme }) => ({
    root: {
      pointerEvents: 'auto',
      fontWeight: 'bolder',
      '&:hover, :focus-within': {
        color: theme.palette.common.grayDarkest,
      },
      '&:disabled': {
        color: theme.palette.common.gray,
      },
      '&.Mui-selected': {
        color: theme.palette.common.orangeDarker,
      },
    },
  })
);

export default CustomTab;
