import React, { FC, MouseEvent } from 'react';
import { TestGroup, RunnableType } from 'models/testSuiteModels';
import TreeItem from '@material-ui/lab/TreeItem';
import TreeItemLabel from './TreeItemLabel';

export interface TestGroupTreeItemProps extends TestGroup {
  runTests: (runnableType: RunnableType, runnableId: string) => void;
  onLabelClick: (event: MouseEvent<Element>, id: string) => void;
  testRunInProgress: boolean;
}

const TestGroupTreeItem: FC<TestGroupTreeItemProps> = ({
  title,
  id,
  test_groups,
  result,
  user_runnable,
  runTests,
  onLabelClick,
  testRunInProgress,
}) => {
  let sublist: JSX.Element[] = [];
  if (test_groups.length > 0) {
    sublist = test_groups.map((testGroup) => (
      <TestGroupTreeItem
        {...testGroup}
        runTests={runTests}
        onLabelClick={onLabelClick}
        key={`ti-${testGroup.id}`}
        testRunInProgress={testRunInProgress}
      ></TestGroupTreeItem>
    ));
  }
  return (
    <TreeItem
      nodeId={id}
      label={
        <TreeItemLabel
          id={id}
          title={title}
          runTests={runTests}
          result={result}
          runnableType={RunnableType.TestGroup}
          testRunInProgress={testRunInProgress}
          user_runnable={user_runnable}
        />
      }
      onLabelClick={(event) => onLabelClick(event, id)}
    >
      {sublist}
    </TreeItem>
  );
};

export default TestGroupTreeItem;
