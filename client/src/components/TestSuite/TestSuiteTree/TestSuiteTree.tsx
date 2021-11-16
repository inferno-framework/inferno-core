import React, { FC, MouseEvent } from 'react';
import { TestSuite, TestGroup, RunnableType } from 'models/testSuiteModels';
import { CardContent, Box } from '@material-ui/core';
import useStyles from './styles';
import TreeView from '@material-ui/lab/TreeView';
import ExpandMoreIcon from '@material-ui/icons/ExpandMore';
import ChevronRightIcon from '@material-ui/icons/ChevronRight';
import TreeItem from '../../_common/TreeItem';
import TestGroupTreeItem from './TestGroupTreeItem';
import TreeItemLabel from './TreeItemLabel';
import { useHistory } from 'react-router-dom';

export interface TestSuiteTreeProps {
  testSuite: TestSuite;
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
  testSuite,
  selectedRunnable,
  runTests,
  testRunInProgress,
}) => {
  const styles = useStyles();
  const history = useHistory();

  const defaultExpanded: string[] = [testSuite.id];
  if (testSuite.test_groups) {
    addDefaultExpanded(testSuite.test_groups, defaultExpanded);
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

  if (testSuite.test_groups) {
    const testGroupList = testSuite.test_groups.map((testGroup) => (
      <TestGroupTreeItem
        key={testGroup.id}
        data-testid={`${testGroup.id}-treeitem`}
        onLabelClick={treeItemLabelClick}
        testGroup={testGroup}
        runTests={runTests}
        testRunInProgress={testRunInProgress}
      />
    ));

    return (
      <Box className={styles.testSuiteTreePanel}>
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
              nodeId={testSuite.id}
              label={
                <TreeItemLabel
                  runnable={testSuite}
                  runTests={runTests}
                  testRunInProgress={testRunInProgress}
                />
              }
              onLabelClick={(event) => treeItemLabelClick(event, testSuite.id)}
            >
              {testGroupList}
            </TreeItem>
          </TreeView>
        </CardContent>
      </Box>
    );
  } else {
    return <Box>{testSuite.title}</Box>;
  }
};

export default TestSuiteTreeComponent;
