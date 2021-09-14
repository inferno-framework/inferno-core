import React, { FC, MouseEvent } from 'react';
import { TestSuite, TestGroup, RunnableType } from 'models/testSuiteModels';
import { Card, CardContent } from '@material-ui/core';
import useStyles from './styles';
import TreeView from '@material-ui/lab/TreeView';
import TreeItem from '@material-ui/lab/TreeItem';
import ExpandMoreIcon from '@material-ui/icons/ExpandMore';
import ChevronRightIcon from '@material-ui/icons/ChevronRight';
import TestGroupTreeItem from './TestGroupTreeItem';
import TreeItemLabel from './TreeItemLabel';
import { useHistory } from 'react-router-dom';

export interface TestSuiteTreeProps extends TestSuite {
  runTests: (runnableType: RunnableType, runnableId: string) => void;
  selectedRunnable: string;
  testRunInProgress: boolean;
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
  testRunInProgress,
}) => {
  const styles = useStyles();
  const history = useHistory();

  const defaultExpanded: string[] = [id];
  if (test_groups) {
    addDefaultExpanded(test_groups, defaultExpanded);
  }
  const [expanded, setExpanded] = React.useState(defaultExpanded);

  function treeItemLabelClick(event: MouseEvent<Element>, id: string) {
    event.preventDefault();
    history.push(`#${id}`);
  }

  // types aren't set in the library
  function nodeToggle(event: unknown, nodeIds: unknown) {
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
        testRunInProgress={testRunInProgress}
      />
    ));

    return (
      <Card className={styles.testSuiteTreePanel} variant="outlined">
        <CardContent>
          <TreeView
            defaultCollapseIcon={<ExpandMoreIcon />}
            defaultExpandIcon={<ChevronRightIcon />}
            onNodeToggle={nodeToggle}
            expanded={expanded}
            selected={selectedRunnable}
          >
            <TreeItem
              classes={{ content: styles.treeRoot }}
              nodeId={id}
              label={
                <TreeItemLabel
                  id={id}
                  title={title}
                  runTests={runTests}
                  result={result}
                  runnableType={RunnableType.TestSuite}
                  testRunInProgress={testRunInProgress}
                  user_runnable={true}
                />
              }
              onLabelClick={(event) => treeItemLabelClick(event, id)}
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
