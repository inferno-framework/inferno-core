import { Typography } from '@mui/material';
import React, { FC } from 'react';
import clsx from 'clsx';
import useStyles from './styles';

import Dangerous from '@mui/icons-material/Dangerous';
import Warning from '@mui/icons-material/Warning';
import Info from '@mui/icons-material/Info';

type MessageTypeProps = {
  type: 'warning' | 'error' | 'info';
};

const MessageType: FC<MessageTypeProps> = ({ type }) => {
  const styles = useStyles();
  const style = styles[type];

  let icon;
  if (type === 'error') {
    icon = <Dangerous className={style} />;
  } else if (type === 'warning') {
    icon = <Warning className={style} />;
  } else if (type === 'info') {
    icon = <Info className={style} />;
  }

  return (
    <span>
      {icon}
      <Typography variant="caption" className={clsx([styles.messageTypeText, style])}>
        {type}
      </Typography>
    </span>
  );
};

export default MessageType;
