import React, { FC } from 'react';
import lightTheme from 'styles/theme';

interface TabPanelProps {
  id: string;
  index: number;
  currentTabIndex: number;
}

const TabPanel: FC<TabPanelProps> = ({ id, index, currentTabIndex, children }) => {
  return (
    <div
      role="tabpanel"
      hidden={currentTabIndex !== index}
      id={`${id}-tabpanel-${index}`}
      aria-labelledby={`${id}-tab-${index}`}
      style={{ overflow: 'auto', backgroundColor: lightTheme.palette.common.white }}
    >
      {currentTabIndex === index && <div>{children}</div>}
    </div>
  );
};

export default TabPanel;
