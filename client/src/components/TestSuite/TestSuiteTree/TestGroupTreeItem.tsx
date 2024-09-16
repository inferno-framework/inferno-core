import React, { FC } from 'react';
import { TestGroup } from '~/models/testSuiteModels';
import CustomTreeItem from '~/components/_common/CustomTreeItem';
import TreeItemLabel from './TreeItemLabel';
import ResultIcon from '../TestSuiteDetails/ResultIcon';

export interface TestGroupTreeItemProps {
  testGroup: TestGroup;
}

const TestGroupTreeItem: FC<TestGroupTreeItemProps> = ({ testGroup }) => {
  const renderSublist = (): JSX.Element[] => {
    return testGroup.test_groups.map((subTestGroup, index) => (
      <TestGroupTreeItem testGroup={subTestGroup} key={`ti-${testGroup.short_id}-${index}`} />
    ));
  };

  // Define icon for tree item slots
  const TreeItemIcon: FC<unknown> = () => {
    return <ResultIcon result={testGroup.result} isRunning={testGroup.is_running} />;
  };

  return (
    <CustomTreeItem
      itemId={testGroup.id}
      label={<TreeItemLabel runnable={testGroup} />}
      slots={
        testGroup.run_as_group || testGroup.test_groups.length === 0 ? { icon: TreeItemIcon } : {}
      }
      ContentProps={{ testId: testGroup.short_id } as never}
    >
      {testGroup.test_groups.length > 0 && !testGroup.run_as_group && renderSublist()}
    </CustomTreeItem>
  );
};

export default TestGroupTreeItem;
