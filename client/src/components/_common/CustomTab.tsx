import * as React from 'react';
import { styled } from '@mui/material/styles';
import { Tab } from '@mui/material';

interface CustomTabProps {
  label: React.ReactNode;
  disabled?: boolean;
}

const CustomTab = styled((props: CustomTabProps) => <Tab disableRipple {...props} />)(
  ({ theme }) => ({
    pointerEvents: 'auto',
    fontWeight: 'bold',
    '&:hover, :focus-within': {
      color: theme.palette.common.grayDarkest,
    },
    '&.Mui-selected': {
      color: theme.palette.common.orangeDark,
      '&:hover, :focus-within': {
        color: theme.palette.primary.dark,
      },
    },
  }),
);

export default CustomTab;
