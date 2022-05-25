import { Badge, SvgIconTypeMap, Tooltip } from '@mui/material';
import { OverridableComponent } from '@mui/material/OverridableComponent';
import React, { FC } from 'react';
import clsx from 'clsx';
import useStyles from './styles';

type ProblemBadgeProps = {
  Icon: OverridableComponent<SvgIconTypeMap<unknown, 'svg'>>;
  counts: number;
  color: string;
  badgeStyle: string;
  setPanelIndex: React.Dispatch<React.SetStateAction<number>>;
  setOpen: React.Dispatch<React.SetStateAction<boolean>>;
};

const ProblemBadge: FC<ProblemBadgeProps> = ({
  Icon,
  counts,
  color,
  badgeStyle,
  setPanelIndex,
  setOpen,
}) => {
  const styles = useStyles();
  return (
    <Badge
      badgeContent={counts}
      overlap="circular"
      className={clsx([color, badgeStyle, styles.badgeBase])}
    >
      <Tooltip describeChild title={`${counts} message(s)`}>
        <Icon
          aria-label={`View ${counts} message(s)`}
          aria-hidden={false}
          tabIndex={0}
          className={clsx([styles.badgeIcon, styles.problemBadge, color])}
          onClick={(e) => {
            e.stopPropagation();
            setPanelIndex(0);
            setOpen(true);
          }}
          onKeyDown={(e) => {
            e.stopPropagation();
            if (e.key === 'Enter') {
              setPanelIndex(0);
              setOpen(true);
            }
          }}
        />
      </Tooltip>
    </Badge>
  );
};

export default ProblemBadge;
