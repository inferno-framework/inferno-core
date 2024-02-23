import React, { FC, useEffect } from 'react';
import { IconButton, IconButtonPropsSizeOverrides } from '@mui/material';
import { OverridableStringUnion } from '@mui/types';
import { ExpandLess, ExpandMore } from '@mui/icons-material';
import CustomTooltip from '~/components/_common/CustomTooltip';

export interface CollapseButtonProps {
  setCollapsed: (collapsed: boolean) => void;
  size?: OverridableStringUnion<'small' | 'large' | 'medium', IconButtonPropsSizeOverrides>;
  startState?: boolean;
}

const CollapseButton: FC<CollapseButtonProps> = ({
  setCollapsed: setParentCollapsed,
  size,
  startState = false,
}) => {
  const [collapsed, setCollapsed] = React.useState(startState);

  useEffect(() => {
    setParentCollapsed(collapsed);
  }, [collapsed]);

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
