import React, { FC, MouseEvent } from 'react';
import { TestGroup, RunnableType, Test } from 'models/testSuiteModels';
import TreeItem from '@material-ui/lab/TreeItem';
import TreeItemLabel from './TreeItemLabel';

export interface TestGroupTreeItemProps extends TestGroup {
  runTests: (runnableType: RunnableType, runnableId: string) => void;
  onLabelClick: (event: MouseEvent<Element>, id: string, type: RunnableType) => void;
}

const TestGroupTreeItem: FC<TestGroupTreeItemProps> = ({
  title,
  id,
  tests,
  test_groups,
  result,
  runTests,
  onLabelClick,
}) => {
  let sublist: JSX.Element[] = [];
  if (test_groups.length > 0) {
    sublist = test_groups.map((testGroup) => (
      <TestGroupTreeItem
        {...testGroup}
        runTests={runTests}
        onLabelClick={onLabelClick}
        key={`ti-${testGroup.id}`}
      ></TestGroupTreeItem>
    ));
  } else if (tests?.length > 0) {
    sublist = tests.map((test: Test) => {
      return (
        <TreeItem
          nodeId={test.id}
          label={
            <TreeItemLabel
              id={test.id}
              title={test.title}
              runTests={runTests}
              result={test.result}
              runnableType={RunnableType.Test}
            />
          }
          onLabelClick={(event) => onLabelClick(event, id, RunnableType.TestGroup)}
          key={`ti-${test.id}`}
        />
      );
    });
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
        />
      }
      onLabelClick={(event) => onLabelClick(event, id, RunnableType.TestGroup)}
    >
      {sublist}
    </TreeItem>
  );
};

export default TestGroupTreeItem;
