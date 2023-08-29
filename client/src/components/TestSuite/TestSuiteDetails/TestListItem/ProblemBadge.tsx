import React, { FC } from 'react';
import { Badge, SvgIconTypeMap } from '@mui/material';
import { OverridableComponent } from '@mui/material/OverridableComponent';
import clsx from 'clsx';
import CustomTooltip from '~/components/_common/CustomTooltip';

import useStyles from './styles';

type ProblemBadgeProps = {
  Icon: OverridableComponent<SvgIconTypeMap<unknown, 'svg'>>;
  counts: number;
  color: string;
  badgeStyle: string;
  description: string;
  view: string;
  panelIndex?: number;
  setPanelIndex?: React.Dispatch<React.SetStateAction<number>>;
  setOpen?: React.Dispatch<React.SetStateAction<boolean>>;
};

const ProblemBadge: FC<ProblemBadgeProps> = ({
  Icon,
  counts,
  color,
  badgeStyle,
  description,
  view,
  panelIndex,
  setPanelIndex,
  setOpen,
}) => {
  const { classes } = useStyles();

  const openPanel = () => {
    if (view !== 'report') {
      // panelIndex can be 0, which is falsy, so explicitly check against undefined
      if (setPanelIndex && panelIndex !== undefined) {
        setPanelIndex(panelIndex);
      }
      if (setOpen) setOpen(true);
    }
  };

  // Custom icon button to resolve nested interactive control error
  return (
    <Badge
      badgeContent={counts}
      max={9}
      overlap="circular"
      className={clsx([color, badgeStyle, classes.badgeBase])}
      onClick={(e) => {
        e.stopPropagation();
        openPanel();
      }}
      onKeyDown={(e) => {
        e.stopPropagation();
        if (e.key === 'Enter') {
          openPanel();
        }
      }}
    >
      <CustomTooltip describeChild title={description}>
        <Icon
          aria-label={`View ${description}`}
          aria-hidden={false}
          tabIndex={0}
          className={clsx([classes.badgeIcon, color])}
          onClick={(e) => {
            e.stopPropagation();
            openPanel();
          }}
          onKeyDown={(e) => {
            e.stopPropagation();
            if (e.key === 'Enter') {
              openPanel();
            }
          }}
        />
      </CustomTooltip>
    </Badge>
  );
};

export default ProblemBadge;
