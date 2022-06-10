import React, { FC } from 'react';

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
      style={{ overflow: 'scroll' }}
    >
      {currentPanelIndex === index && <div>{children}</div>}
    </div>
  );
};

export default TabPanel;
