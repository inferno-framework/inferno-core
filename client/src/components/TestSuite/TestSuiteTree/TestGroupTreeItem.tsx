import React, { FC } from 'react';
import { TestGroup, RunnableType } from 'models/testSuiteModels';
import CustomTreeItem from '../../_common/TreeItem';
import TreeItemLabel from './TreeItemLabel';
import CondensedResultIcon from './CondensedResultIcon';

export interface TestGroupTreeItemProps {
  testGroup: TestGroup;
  runTests: (runnableType: RunnableType, runnableId: string) => void;
  testRunInProgress: boolean;
}

const TestGroupTreeItem: FC<TestGroupTreeItemProps> = ({
  testGroup,
  runTests,
  testRunInProgress,
}) => {
  let sublist: JSX.Element[] = [];
  if (testGroup.test_groups.length > 0 && !testGroup.run_as_group) {
    sublist = testGroup.test_groups.map((subTestGroup, index) => (
      <TestGroupTreeItem
        testGroup={subTestGroup}
        runTests={runTests}
        key={`ti-${testGroup.id}-${index}`}
        testRunInProgress={testRunInProgress}
      />
    ));
  }

  return (
    <CustomTreeItem
      nodeId={testGroup.id}
      label={<TreeItemLabel runnable={testGroup} />}
      icon={testGroup.run_as_group ? <CondensedResultIcon result={testGroup.result} /> : null}
      // eslint-disable-next-line max-len
      // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-explicit-any
      ContentProps={{ testId: testGroup.id } as any}
    >
      {sublist}
    </CustomTreeItem>
  );
};

export default TestGroupTreeItem;
