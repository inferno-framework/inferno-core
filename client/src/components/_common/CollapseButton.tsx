import React, { FC } from 'react';
import { IconButton, IconButtonPropsSizeOverrides } from '@mui/material';
import { OverridableStringUnion } from '@mui/types';
import { ExpandLess, ExpandMore } from '@mui/icons-material';
import CustomTooltip from '~/components/_common/CustomTooltip';

export interface CollapseButtonProps {
  collapsed: boolean;
  setCollapsed: (collapsed: boolean) => void;
  size?: OverridableStringUnion<'small' | 'large' | 'medium', IconButtonPropsSizeOverrides>;
}

const CollapseButton: FC<CollapseButtonProps> = ({ collapsed = false, setCollapsed, size }) => {
  return (
    <CustomTooltip title={collapsed ? 'Expand panel' : 'Collapse panel'}>
      <IconButton
        size={size}
        color="secondary"
        aria-label={collapsed ? 'expand button' : 'collapse button'}
        onClick={() => setCollapsed(!collapsed)}
      >
        {collapsed ? <ExpandMore fontSize="inherit" /> : <ExpandLess fontSize="inherit" />}
      </IconButton>
    </CustomTooltip>
  );
};

export default CollapseButton;
