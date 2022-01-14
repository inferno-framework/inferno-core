import React, { FC } from 'react';
import { TestGroup, RunnableType, Result } from 'models/testSuiteModels';
import CustomTreeItem from '../../_common/TreeItem';
import TreeItemLabel from './TreeItemLabel';

export interface TestGroupTreeItemProps {
  testGroup: TestGroup;
  runTests: (runnableType: RunnableType, runnableId: string) => void;
  currentTest: Result | null;
  testRunInProgress: boolean;
}

const TestGroupTreeItem: FC<TestGroupTreeItemProps> = ({
  testGroup,
  runTests,
  currentTest,
  testRunInProgress,
}) => {
  let sublist: JSX.Element[] = [];
  if (testGroup.test_groups.length > 0) {
    sublist = testGroup.test_groups.map((subTestGroup, index) => (
      <TestGroupTreeItem
        testGroup={subTestGroup}
        runTests={runTests}
        key={`ti-${testGroup.id}-${index}`}
        currentTest={currentTest}
        testRunInProgress={testRunInProgress}
      />
    ));
  }

  return (
    <CustomTreeItem
      nodeId={testGroup.id}
      label={
        <TreeItemLabel
          runnable={testGroup}
          runTests={runTests}
          currentTest={currentTest}
          testRunInProgress={testRunInProgress}
        />
      }
      // eslint-disable-next-line max-len
      // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-explicit-any
      ContentProps={{ testId: testGroup.id } as any}
    >
      {sublist}
    </CustomTreeItem>
  );
};

export default TestGroupTreeItem;
