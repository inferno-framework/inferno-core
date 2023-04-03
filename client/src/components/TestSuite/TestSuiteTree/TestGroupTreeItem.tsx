import React, { FC } from 'react';
import { TestGroup } from '~/models/testSuiteModels';
import CustomTreeItem from '~/components/_common/TreeItem';
import TreeItemLabel from './TreeItemLabel';
import ResultIcon from '../TestSuiteDetails/ResultIcon';

export interface TestGroupTreeItemProps {
  testGroup: TestGroup;
}

const TestGroupTreeItem: FC<TestGroupTreeItemProps> = ({ testGroup }) => {
  const itemIcon = (testGroup.run_as_group || testGroup.test_groups.length === 0) && (
    <ResultIcon result={testGroup.result} isRunning={testGroup.is_running} />
  );

  const renderSublist = (): JSX.Element[] => {
    return testGroup.test_groups.map((subTestGroup, index) => (
      <TestGroupTreeItem testGroup={subTestGroup} key={`ti-${testGroup.short_id}-${index}`} />
    ));
  };

  return (
    <CustomTreeItem
      nodeId={testGroup.id}
      label={<TreeItemLabel runnable={testGroup} />}
      icon={itemIcon}
      // eslint-disable-next-line max-len
      // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-explicit-any
      ContentProps={{ testId: testGroup.short_id } as any}
    >
      {testGroup.test_groups.length > 0 && !testGroup.run_as_group && renderSublist()}
    </CustomTreeItem>
  );
};

export default TestGroupTreeItem;
