import { Badge, SvgIconTypeMap, Tooltip } from '@mui/material';
import { OverridableComponent } from '@mui/material/OverridableComponent';
import React, { FC } from 'react';
import clsx from 'clsx';
import useStyles from './styles';

import { useTestSessionStore } from '~/store/testSession';

type ProblemBadgeProps = {
  Icon: OverridableComponent<SvgIconTypeMap<unknown, 'svg'>>;
  counts: number;
  color: string;
  badgeStyle: string;
  description: string;
  panelIndex: number;
  setPanelIndex: React.Dispatch<React.SetStateAction<number>>;
  setOpen: React.Dispatch<React.SetStateAction<boolean>>;
};

const ProblemBadge: FC<ProblemBadgeProps> = ({
  Icon,
  counts,
  color,
  badgeStyle,
  description,
  panelIndex,
  setPanelIndex,
  setOpen,
}) => {
  const styles = useStyles();
  const view = useTestSessionStore((state) => state.view);

  // Custom icon button to resolve nested interactive control error
  return (
    <Badge
      badgeContent={counts}
      max={9}
      overlap="circular"
      className={clsx([color, badgeStyle, styles.badgeBase])}
    >
      <Tooltip describeChild title={description}>
        <Icon
          aria-label={`View ${description}`}
          aria-hidden={false}
          tabIndex={0}
          className={clsx([styles.badgeIcon, color])}
          onClick={(e) => {
            e.stopPropagation();
            if (view !== 'report') {
              setPanelIndex(panelIndex);
              setOpen(true);
            }
          }}
          onKeyDown={(e) => {
            e.stopPropagation();
            if (e.key === 'Enter' && view !== 'report') {
              setPanelIndex(panelIndex);
              setOpen(true);
            }
          }}
        />
      </Tooltip>
    </Badge>
  );
};

export default ProblemBadge;
