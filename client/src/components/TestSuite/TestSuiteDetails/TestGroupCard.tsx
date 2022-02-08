import React, { FC } from 'react';
import useStyles from './styles';
import { TestGroup, RunnableType, TestSuite } from 'models/testSuiteModels';
import { Box, Card, List } from '@mui/material';
import ReactMarkdown from 'react-markdown';
import ResultIcon from './ResultIcon';
import TestRunButton from '../TestRunButton/TestRunButton';

interface TestGroupCardProps {
  runnable: TestSuite | TestGroup;
  runTests: (runnableType: RunnableType, runnableId: string) => void;
  testRunInProgress: boolean;
}

const TestGroupCard: FC<TestGroupCardProps> = ({
  runnable,
  runTests,
  children,
  testRunInProgress,
}) => {
  const styles = useStyles();

  const buttonText = runnable.run_as_group ? 'Run Tests' : 'Run All Tests';

  const description =
    runnable.description && runnable.description.length > 0 ? (
      <div>
        <ReactMarkdown>{runnable.description}</ReactMarkdown>
      </div>
    ) : null;

  return (
    <Card className={styles.testGroupCard} variant="outlined">
      <div className={styles.testGroupCardHeader}>
        <span className={styles.testGroupCardHeaderResult}>
          <ResultIcon result={runnable.result} />
        </span>
        <span className={styles.testGroupCardHeaderText}>{runnable.title}</span>
        <TestRunButton
          buttonText={buttonText}
          runnable={runnable}
          runTests={runTests}
          testRunInProgress={testRunInProgress}
        />
      </div>
      {description && <Box margin="20px">{description}</Box>}
      <List className={styles.testGroupCardList}>{children}</List>
    </Card>
  );
};

export default TestGroupCard;
