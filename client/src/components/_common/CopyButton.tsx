import React, { FC } from 'react';
import { Box, IconButton, IconButtonPropsSizeOverrides } from '@mui/material';
import { OverridableStringUnion } from '@mui/types';
import { ContentCopy } from '@mui/icons-material';
import CustomTooltip from '~/components/_common/CustomTooltip';

export interface CopyButtonProps {
  copyText: string;
  size?: OverridableStringUnion<'small' | 'large' | 'medium', IconButtonPropsSizeOverrides>;
  view?: string;
}

const CopyButton: FC<CopyButtonProps> = ({ copyText, size, view }) => {
  const [copySuccess, setCopySuccess] = React.useState({}); // Use map for lists of copiable items

  const copyTextClick = async (text: string) => {
    await navigator.clipboard.writeText(text).then(() => {
      setCopySuccess({ ...copySuccess, [text]: true });
      setTimeout(() => {
        // Reset map instead of setting false to avoid async bug
        setCopySuccess({});
      }, 2000); // 2 second delay
    });
  };
  return (
    <CustomTooltip
      title={copySuccess[copyText as keyof typeof copySuccess] ? 'Text copied!' : 'Copy text'}
      sx={
        view === 'report'
          ? {
              display: 'none',
              '@media print': {
                display: 'none',
              },
            }
          : {}
      }
    >
      <Box px={1}>
        <IconButton
          size={size}
          color="secondary"
          aria-label="copy button"
          onClick={() => void copyTextClick(copyText)}
        >
          <ContentCopy fontSize="inherit" />
        </IconButton>
      </Box>
    </CustomTooltip>
  );
};

export default CopyButton;
