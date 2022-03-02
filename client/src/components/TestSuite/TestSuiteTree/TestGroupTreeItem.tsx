import React, { FC } from 'react';
import { TestGroup, RunnableType } from 'models/testSuiteModels';
import CustomTreeItem from '../../_common/TreeItem';
import TreeItemLabel from './TreeItemLabel';
import ResultIcon from '../TestSuiteDetails/ResultIcon';

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
  const itemIcon = (testGroup.run_as_group || testGroup.test_groups.length === 0) && (
    <ResultIcon result={testGroup.result} />
  );

  const renderSublist = (): JSX.Element[] => {
    return testGroup.test_groups.map((subTestGroup, index) => (
      <TestGroupTreeItem
        testGroup={subTestGroup}
        runTests={runTests}
        key={`ti-${testGroup.id}-${index}`}
        testRunInProgress={testRunInProgress}
      />
    ));
  };

  return (
    <CustomTreeItem
      nodeId={testGroup.id}
      label={<TreeItemLabel runnable={testGroup} />}
      icon={itemIcon}
      // eslint-disable-next-line max-len
      // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-explicit-any
      ContentProps={{ testId: testGroup.id } as any}
    >
      {testGroup.test_groups.length > 0 && !testGroup.run_as_group && renderSublist()}
    </CustomTreeItem>
  );
};

export default TestGroupTreeItem;
