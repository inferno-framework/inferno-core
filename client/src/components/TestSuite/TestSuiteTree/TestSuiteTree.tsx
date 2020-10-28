import React, { FC, MouseEvent } from 'react';
import { TestSuite, TestGroup, RunnableType } from 'models/testSuiteModels';
import { Card, CardContent, CardHeader } from '@material-ui/core';
import useStyles from './styles';
import TreeView from '@material-ui/lab/TreeView';
import TreeItem from '@material-ui/lab/TreeItem';
import ExpandMoreIcon from '@material-ui/icons/ExpandMore';
import ChevronRightIcon from '@material-ui/icons/ChevronRight';
import TestGroupTreeItem from './TestGroupTreeItem';
import TreeItemLabel from './TreeItemLabel';

export interface TestSuiteTreeProps extends TestSuite {
  runTests: (runnableType: RunnableType, runnableId: string) => void;
  setSelectedRunnable: (id: string, type: RunnableType) => void;
  selectedRunnable: string;
}

function addDefaultExpanded(testGroups: TestGroup[], defaultExpanded: string[]): void {
  testGroups.forEach((testGroup: TestGroup) => {
    if (testGroup.test_groups.length > 0) {
      defaultExpanded.push(testGroup.id);
      addDefaultExpanded(testGroup.test_groups, defaultExpanded);
    }
  });
}

const TestSuiteTreeComponent: FC<TestSuiteTreeProps> = ({
  title,
  id,
  test_groups,
  result,
  selectedRunnable,
  runTests,
  setSelectedRunnable,
}) => {
  const styles = useStyles();
  const defaultExpanded: string[] = [id];
  if (test_groups) {
    addDefaultExpanded(test_groups, defaultExpanded);
  }
  const [expanded, setExpanded] = React.useState(defaultExpanded);

  function treeItemLabelClick(event: MouseEvent<Element>, id: string, type: RunnableType) {
    event.preventDefault();
    setSelectedRunnable(id, type);
  }

  // types aren't set in the library
  function nodeToggle(event: unknown, nodeIds: unknown) {
    console.log('node toggle');
    setExpanded(nodeIds as string[]);
  }

  if (test_groups) {
    const testGroupList = test_groups.map((testGroup) => (
      <TestGroupTreeItem
        {...testGroup}
        key={testGroup.id}
        data-testid={`${testGroup.id}-treeitem`}
        onLabelClick={treeItemLabelClick}
        runTests={runTests}
      />
    ));

    return (
      <Card className={styles.testSuiteTreePanel}>
        <CardHeader title={`${title} Tests`} />
        <CardContent>
          <TreeView
            defaultCollapseIcon={<ExpandMoreIcon />}
            defaultExpandIcon={<ChevronRightIcon />}
            onNodeToggle={nodeToggle}
            expanded={expanded}
            selected={selectedRunnable}
          >
            <TreeItem
              nodeId={id}
              label={
                <TreeItemLabel
                  id={id}
                  title={title}
                  runTests={runTests}
                  result={result}
                  runnableType={RunnableType.TestSuite}
                />
              }
              onLabelClick={(event) => treeItemLabelClick(event, id, RunnableType.TestSuite)}
            >
              {testGroupList}
            </TreeItem>
          </TreeView>
        </CardContent>
      </Card>
    );
  } else {
    return <div>{title}</div>;
  }
};

export default TestSuiteTreeComponent;
