import React, { FC } from 'react';
import lightTheme from 'styles/theme';

interface TabPanelProps {
  id: string;
  index: number;
  currentPanelIndex: number;
}

const TabPanel: FC<TabPanelProps> = ({ id, index, currentPanelIndex, children }) => {
  return (
    <div
      role="tabpanel"
      hidden={currentPanelIndex !== index}
      id={`${id}-tabpanel-${index}`}
      aria-labelledby={`${id}-tab-${index}`}
      style={{ overflow: 'scroll', backgroundColor: lightTheme.palette.common.white }}
    >
      {currentPanelIndex === index && <div>{children}</div>}
    </div>
  );
};

export default TabPanel;
