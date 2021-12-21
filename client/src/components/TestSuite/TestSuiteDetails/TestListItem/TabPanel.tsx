import React, { FC } from 'react';

interface TabPanelProps {
  index: number;
  currentPanelIndex: number;
}

const TabPanel: FC<TabPanelProps> = ({ index, currentPanelIndex, children }) => {
  return (
    <div
      role="tabpanel"
      hidden={currentPanelIndex !== index}
      id={`simple-tabpanel-${index}`}
      aria-labelledby={`simple-tab-${index}`}
    >
      {currentPanelIndex === index && <div>{children}</div>}
    </div>
  );
};

export default TabPanel;
